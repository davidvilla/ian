# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

function cmd:binary-contents {
##:binary-contents:cmd:show binary package file listings
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
		sh-run "quilt pop -a"
	fi
}

function cmd:build {
##:build:cmd:build all binary packages. See 'ian help build'.
##:build:usage:ian build [-b] [-c] [-f] [-i] [-l] [-s] [-w] [-x]
##:build:usage:  -b;  skip 'source' target. See 'dpkg-buildpackage -b'
##:build:usage:  -c;  run "ian clean" then "build"
##:build:usage:  -f;  force build
##:build:usage:  -i;  run "ian build" then "install"
##:build:usage:  -l;  creates orig with "ian orig local"
##:build:usage:  -s;  include full source. See 'dpkg-genchanges -sa'
##:build:usage:  -w;  build in the working directory instead of merging ./debian with the .orig.
##:build:usage:  -x;  skip lintian
##:build:usage:
##:build:usage:  By default, the package is built in a temporary directory, from the .orig.
##:build:usage:  plus ./debian. Native packages are always built in the working directory.
##:build:usage:  If the orig comes from "local", build fails when the working directory
##:build:usage:  differs from it: run "ian build -c" or make a new release.


    local clean=false build_binary=false force=false install=false local=false in_place=false include_source=false
    local orig_created=false
    local OPTIND=1 OPTARG OPTION

    while getopts :bcfilmswx OPTION "${__args__[@]}"; do
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
				log-info "'-m' is the default now, the option is not needed" ;;
			s)
				include_source=true ;;
			w)
				in_place=true ;;
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
			rm -f $(find-orig-path)
		fi

		if  ! sc-file-exists "$(find-orig-path)"; then
			if [ "$local" = true ]; then
				ian-check orig local
			else
				ian-check orig
			fi
			orig_created=true
		fi

		if [ "$in_place" != true ] && is-native; then
			in_place=true
			log-info "native package: building in the working directory"
		fi

		if [ "$in_place" = true ] && _upstream-sources-missing "$(find-orig-path)"; then
			in_place=false
			log-warning "no upstream sources here, merging ./debian with $(basename $(find-orig-path)) instead"
		fi

		if [ "$in_place" != true ] && [ "$orig_created" != true ] && _orig-from-local $local; then
			_assert-orig-matches-local "$(find-orig-path)"
		fi

		_assert-user-is-uploader $force
		_assert-user-last-changelog-entry $force

		_builddeps-assure
		log-info "build"

		if [ "$in_place" = true ]; then
			sc-set-trap quilt-pop
			_build-standard
			sc-clear-trap
		else
			_build-merging-upstream
		fi

        if [ "$skip_lintian" = true ]; then
			log-info "lintian was skipped as requested"
		else
			run-lintian
		fi

		sc-assert-files-exist $(binary-paths)
		log-ok "build"
		log-info "generated files:"
		ian-run ls

		if [ "$install" = true ]; then
			ian-run install
		fi
	)
}

# true if the orig is made from the working directory: "-l" or no other orig mode available
function _orig-from-local {
	local local_option="$1"
	[ "$local_option" = true ] || [ "$(_detect-orig-mode)" = local ]
}

# fail if the working directory has files the orig does not, or the other way round, or with other contents: the
# build takes the orig, so it would silently miss the changes made after the orig was created
function _assert-orig-matches-local {
	local orig="$1"
	local tmp=$(mktemp -d)
	local differences=

	_extract-orig "$orig" $tmp/orig
	rm -rf $tmp/orig/debian
	_copy-local-sources $tmp/local
	differences=$(cd $tmp && LC_ALL=C diff --recursive --brief --no-dereference orig local)
	rm -rf $tmp

	if [ -z "$differences" ]; then
		return 0
	fi

	log-error "the working directory differs from $(basename $orig), which the build takes:"
	echo "$differences" | head -n 20
	log-error "run 'ian build -c' to create the orig again or, if it was already uploaded, make a new release"
	exit 1
}

# true when none of the regular files the .orig. provides is in the working
# directory, ie. the package holds the packaging only and can not be built
# in the working directory (see -w). Directories are ignored, as build leftovers often match
function _upstream-sources-missing {
	local orig="$1"
	local fname=

	if ! sc-file-exists "$orig"; then
		return 1
	fi

	for fname in $(tar --list --file "$orig" | cut -d/ -f2- | cut -d/ -f1 | sort -u); do
		if [ -z "$fname" ] || [ "$fname" == debian ]; then
			continue
		fi

		if [ -f "$fname" ]; then
			return 1
		fi
	done
}

# Extract the orig into dir: tar detects the compression (gz, xz) and, if the whole tarball is inside one top directory, that directory is dropped, whatever its name (PyPI tarballs are <upstream>-<version>, not <source package>-<version>)
function _extract-orig {
    local orig="$1"
    local dir="$2"
    local strip=

    if _orig-has-top-directory "$orig"; then
        strip=--strip-components=1
    fi

    mkdir -p "$dir"
    tar --no-same-owner --no-same-permissions --extract --file "$orig" --directory "$dir" $strip
}

# true if every entry of the tarball is inside the same top directory
function _orig-has-top-directory {
    local orig="$1"
    local entries=$(tar --list --file "$orig" | sed 's|^\./||' | grep -v '^$')

    # a file at the top level (no "/" in its name) is not inside a directory
    if echo "$entries" | grep -qv '/'; then
        return 1
    fi
    [ $(echo "$entries" | cut -d/ -f1 | sort -u | wc -l) -eq 1 ]
}

function _build-merging-upstream {
    local tmp_build_area=$(mktemp -d)
    local tmp_build_dir=$tmp_build_area/$(upstream-fullname)
    local fname=

    log-info "merging with upstream in a temp build area: $tmp_build_area"
    _TMP_BUILD_AREA=$tmp_build_area
    sc-set-trap _remove-tmp-build-area
    _extract-orig $(find-orig-path) $tmp_build_dir
    _copy-debian $tmp_build_dir
    cp $(find-orig-path) $tmp_build_area/
    chmod -R u+r+w+X,g+r-w+X,o+r-w+X -- $tmp_build_dir

    (
    cd $tmp_build_dir
    _build-standard
    ) || exit 1

    # what dpkg-buildpackage leaves next to the package dir: .deb, .udeb, .ddeb, .dsc, .changes...
    for fname in $tmp_build_area/*; do
		if [ -f "$fname" ] && [[ "$(basename $fname)" != *.orig.tar.* ]]; then
			cp -v "$fname" $(build-dir)
		fi
    done

    sc-clear-trap
    _remove-tmp-build-area
}

function _remove-tmp-build-area {
	rm -rf "$_TMP_BUILD_AREA"
}

# copy ./debian into dir, without what a previous build in the working directory left there
function _copy-debian {
	local dir="$1"
	local exclude=()
	local path=

	for path in $(_build-leftovers); do
		exclude+=(--exclude="$path")
	done

	tar "${exclude[@]}" -cf - debian | ( cd $dir && tar xf - )
}

function _build-standard {
    assert-preconditions

	local buildopts=
	if [ -z "$BUILDOPTIONS" ] && ! orig-seems-new; then
		BUILDOPTIONS='-b'
		log-info "no source code included because the orig was probably already uploaded"
	fi

    local build_command="dpkg-buildpackage -uc -us $BUILDOPTIONS"
    sh-check "$build_command"
}

function _builddeps-assure {
    local deps=$(builddeps)
    if [[ -z "$deps" ]]; then
		return
    fi

    log-warning "installing build deps: $deps"

	# FIXME: can use "apt-get build-dep"? (require deb-src)
    # if [ -n "$deps" ]; then
	# 	sh-sudo "mk-build-deps --arch $(host-arch) --tool \"apt-get -y\" --install --remove debian/control"
    # fi

    local deps=$(builddeps)
    if [ -n "$deps" ]; then
		sh-sudo "apt-get install $deps"
    fi

    sh-sudo "apt-get install ian"
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
