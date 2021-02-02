# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

function cmd:binary-contents {
##:060:cmd:show binary package file listings
	assert-no-more-args

    (
    assert-preconditions
	sc-assert-files-exist $(changes-path)
	debc $(changes-path)
    )
}

function quilt-pop {
	if grep quilt debian/source/format > /dev/null; then
		sc-log-info "quilt pop"
		ian-run "quilt pop -a"
	fi
}

function cmd:build {
##:040:cmd:build all binary packages. See 'ian help build'.
##:040:usage:ian build [-b] [-c] [-f] [-i] [-m] [-s] [-x]
##:040:usage:  -b;  skip 'source' target. See 'dpkg-buildpackage -b'
##:040:usage:  -c;  run "ian clean" then "build"
##:040:usage:  -f;  force build
##:040:usage:  -i;  run "ian build" then "install"
##:040:usage:  -l;  creates orig with "ian orig-from-local"
##:040:usage:  -m;  merge ./debian with upstream .orig. bypassing directory contents
##:040:usage:  -s;  include full source. See 'dpkg-genchanges -sa'
##:040:usage:  -x;  skip lintian


    local clean=false build_binary=false force=false install=false local=false merge=false include_source=false
    local OPTIND=1 OPTARG OPTION

    while getopts :bcfilmsx OPTION "${__args__[@]}"; do
		case $OPTION in
			b)
				build_binary=true ;;
			c)
				clean=true ;;
			f)
				force=true ;;
			i)
				install=true ;;
			l)
				local=true ;;
			m)
				merge=true ;;
			s)
				include_source=true ;;
			x)
			    skip_lintian=true ;;
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

		if [ "$include_source" = true ]; then
			BUILDOPTIONS="$BUILDOPTIONS -sa"
		fi

		if [ "$clean" = true ]; then
			# force orig create
			rm -f $(orig-path)
		fi

		if [ "$local" = true ]; then
			sc-assert cmd:orig-from-local
		else
			sc-assert cmd:orig
		fi

		_assert-user-is-uploader $force
		_assert-user-last-changelog-entry $force

		_builddeps-assure
		log-info "build"

		notify-build-start

		sc-set-trap quilt-pop
		if uses-svn; then
			_build-svn
		elif [ "$merge" = true ]; then
			_build-merging-upstream
		else
			_build-standard
		fi
		sc-clear-trap

        if [ "$skip_lintian" = true ]; then
		    log-info "lintian was skipped as requested"
		else
		    changes=$(changes-path)
		    log-info "lintian $changes"
		    ian-run "unbuffer lintian -I $changes"
		fi

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
    assert-preconditions

	local buildopts=
	if [ -z $BUILDOPTIONS ] && [ $(debian-release) -ne 1 ]; then
		BUILDOPTIONS='-b'
		log-info "no source code included because debian revision > 1"
	fi

    local build_command="dpkg-buildpackage -uc -us $BUILDOPTIONS"
    check-run "$build_command"
}

function _build-svn {
    assert-preconditions
    assert-uses-svn
    #	sc-assure-dir ../build-area
    log-info "running svn-buildpackage"
    check-run "svn-buildpackage -rfakeroot -us -uc --svn-ignore --svn-ignore-new --svn-move --svn-noninteractive --svn-override origDir=.."
}

function _builddeps-assure {
    local deps=$(builddeps)
    if [[ -z "$deps" ]]; then
		return
    fi

    log-warning "installing build deps: $deps"

	# FIXME: can use "apt-get build-dep"? (require deb-src)
    # if [ -n "$deps" ]; then
	# 	ian-sudo "mk-build-deps --arch $(host-arch) --tool \"apt-get -y\" --install --remove debian/control"
    # fi

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
		log-ok "User '$DEBEMAIL' is an uploader"
		return 0
	fi

	log-error "User '$DEBEMAIL' is NOT an uploader! You won't be able to upload the resulting package."
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

	log-error "User '$DEBEMAIL' does NOT own the current changelog entry!. You won't be able to upload the resulting package."
	_check-force
}

function _check-force {
	if [ "$force" = true ]; then
		log-warning "build continues because 'force' was enabled"
		return 0
	fi

	log-error "Fix issue or run 'build -f' to overcome"
	exit 1
}
