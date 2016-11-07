# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- build ------------------------------------------------------------

function cmd:build {
##:040:cmd:build all binary packages
##:040:usage:ian build [-b] [-c] [-f] [-i] [-m] [-s]
##:040:usage:  -b;  skip 'source' target. See 'dpkg-buildpackage -b'
##:040:usage:  -c;  run "ian clean" before "build"
##:040:usage:  -f;  force build
##:040:usage:  -i;  run "ian install" after "build"
##:040:usage:  -m;  merge ./debian with upstream .orig. bypassing directory contents
##:040:usage:  -s;  include full source. See 'dpkg-genchanges -sa'


    local clean=false build_binary=false foce=false install=false merge=false include_source=false
    local OPTIND=1 OPTARG OPTION

    while getopts :bcfims OPTION "${__args__[@]}"; do
		case $OPTION in
			b)
				build_binary=true ;;
			c)
				clean=true ;;
			f)
				force=true ;;
			i)
				install=true ;;
			m)
				merge=true ;;
			s)
				include_source=true ;;
			\?)
				echo "invalid option: -$OPTARG"
				exit 1 ;;
			:)
				echo "option -$OPTARG requires an argument"
				exit 1 ;;
		esac
    done

    assert-no-more-args $OPTIND

    (
    assert-preconditions

    if [ "$build_binary" = true ]; then
	BUILDOPTIONS="$BUILDOPTIONS -b"
    fi

    if [ "$clean" = true ]; then
	cmd:clean
    fi

    if [ "$include_source" = true ]; then
	BUILDOPTIONS="$BUILDOPTIONS -sa"
    fi

    sc-assert cmd:orig
    _assert-user-is-uploader $force
    _assert-user-last-changelog-entry $force

    _builddeps-assure
    log-info "build"

    notify-build-start
    if uses-svn; then
	_build-svn
    elif [ "$merge" = true ]; then
	_build-merging-upstream
    else
	_build-standard
    fi

    changes=$(changes-path)
    log-info "lintian $changes"
    ian-run "unbuffer lintian -I $changes"

    sc-assert-files-exist $(binary-paths)
    log-ok "build"
    notify-build-end

    if [ "$install" = true ]; then
	cmd:install
    fi
    )
}

function _build-merging-upstream {
    local tmp_build_area=$(mktemp -d)
    local tmp_build_dir=$tmp_build_area/$(upstream-fullname)
    mkdir -p $tmp_build_dir

    log-info "merging with uptream in a temp build area: $tmp_build_area"
    tar --no-same-owner --no-same-permissions --extract --gzip --file $(orig-path) --directory $tmp_build_area/
    cp -r ./debian $tmp_build_dir/
    cp $(orig-path) $tmp_build_area/
    chmod -R u+r+w+X,g+r-w+X,o+r-w+X -- $tmp_build_dir

    (
    cd $tmp_build_dir
    _build-standard
    )

    cp -v $tmp_build_area/$(package)_$(debian-version)* $(build-dir)
    for pkg in $(binary-names) $(dbgsym-names); do
		local fname="$tmp_build_area/${pkg}_$(debian-version)*.deb"
		if [ -e $fname ]; then
			cp -v $fname $(build-dir)
		fi
    done

    cp -v $tmp_build_dir/debian/files ./debian
}

function _build-standard {
    (
    assert-preconditions
    local build_command="dpkg-buildpackage -uc -us $BUILDOPTIONS"
    check-run "$build_command"
    )
}

function _build-svn {
    (
    assert-preconditions
    assert-uses-svn
    #	sc-assure-dir ../build-area
    log-info "running svn-buildpackage"
    check-run "svn-buildpackage -rfakeroot -us -uc --svn-ignore --svn-ignore-new --svn-move --svn-noninteractive --svn-override origDir=.."
    )
}

function _builddeps-assure {
    local deps=$(builddeps)
    if [[ -z "$deps" ]]; then
	return
    fi

    log-info "installing build deps: $deps"

    if [ -n "$deps" ]; then
	ian-sudo "mk-build-deps --arch $(host-arch) --tool \"apt-get -y\" --install --remove debian/control"
    fi

    local deps=$(builddeps)
    if [ -n "$deps" ]; then
	ian-sudo "apt-get install $deps"
    fi

    ian-sudo "apt-get install ian"
    local deps=$(builddeps)
    if [ -n "$deps" ]; then
	log-error "Unmet build dependencies: $deps"
	exit 1
    fi

    log-ok "build deps"
}

function _assert-user-is-uploader {
	local force=$1
	if grep -e "^Maintainer:" -e "^Uploaders:" debian/control | grep $DEBEMAIL > /dev/null; then
		log-ok "User '$DEBEMAIL' is an uploader."
		return 0
	fi

	log-error "User '$DEBEMAIL' is NOT an uploader!."
	_check-force
}

function _assert-user-last-changelog-entry {
	local force=$1
	local expected="$DEBFULLNAME <$DEBEMAIL>"
	local last="$(dpkg-parsechangelog --show-field "Maintainer")"

	if [ "$last" == "$expected" ]; then
		log-ok "User '$DEBEMAIL' owns the last changelog entry"
		return 0
	fi

	log-error "User '$DEBEMAIL' does NOT own the last changelog entry!."
	_check-force
}

function _check-force {
	if [ "$force" = true ]; then
		log-warning "build continues because 'force' is enabled."
		return 0
	fi

	log-error "Execute 'build -f' to overcome."
	exit 1
}