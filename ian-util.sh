# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

function _logger {
    echo ian
}

function log-info {
    sc-log-notify II "$(_logger): $1"
}

function log-warning {
    sc-log-notify WW "$(_logger): $1"
}

function log-error {
    sc-log-notify EE "$(_logger): $1"
}

function log-fail {
    sc-log-notify FF "$(_logger): $1"
}

function log-ok {
    sc-log-notify OK "$(_logger): $1"
}

function deprecation {
    echo
    sc-log-notify DEPRECATED "$(_logger): $1"
    echo
    sleep 2
}

# main, build, util, summary
function uses-svn {
    (svn pl debian | grep mergeWithUpstream) &> /dev/null
}

# clean, orig, util, summary
function valid-watch-present {
    grep -v ".*#" debian/watch &> /dev/null
}

# build, path
function host-arch {
    dpkg-architecture -qDEB_HOST_ARCH
}

function _control-arch {
    local package_name="$1"
    local index=$(grep "Package:" debian/control | grep -n $package_name | cut -f1 -d":"  | head -n1)
    grep "Architecture:" debian/control | tail -n +$index | head -n1 | cut -f2 -d:  | tr -d " "
}

# release, repo, orig, build, path, lintian, summary
function package {
    if sc-var-defined _PACKAGE; then
		echo $_PACKAGE
		return
    fi

    # Done dpkg-parsechangelog cause this function is used when no changelog file
    _PACKAGE=$(grep "^Source:" debian/control | cut -f2 -d:  | tr -d " ")
    package
}

# repo, build, path, summary
function binary-names {
    # get binary package names from 'control'
    grep "^Package:" debian/control | cut -f2 -d:  | tr -d " "
}

# repo, build
function dbgsym-names {
    binary-names | sed -e 's/$/-dbgsym/'
}

# release, build, summary
function debian-version {
	if sc-var-defined _DEBIAN_VERSION; then
		echo $_DEBIAN_VERSION
		return
	fi

    sc-assert-files-exist debian/changelog
    # head -n 1 debian/changelog | cut -f2 -d " " | tr -d "()"
    _DEBIAN_VERSION=$(dpkg-parsechangelog -ldebian/changelog --show-field=Version)
    debian-version
}

function debian-release {
	debian-version | cut -d'-' -f2
}

# orig, build
function upstream-fullname {
    echo $(package)-$(upstream-version)
}

# release, orig, summary
function upstream-version {
    echo $(debian-version) | cut -f1 -d "-"
}

function version-upstream {
	upstream-version
	(>&2 ian-warning "function 'version-upstream' is DEPRECATED! Use 'upstream-version'")
}

# build, summary
function builddeps {
    LANG=C pkgnames=$(dpkg-checkbuilddeps 2>&1)  # | cut -f3 -d':' | sed -e 's/([^][]*)//g'
    echo ${pkgnames##*:}
    # return ${PIPESTATUS[0]}
}

# repo, build, path
function build-dir {
    echo ".."
}

function find_dir_in_ancestors {
	local base="$1"
	local target="$2"

    if [ -d "$base/$target" ]; then
		echo "$base"
		return 0
    fi

    if [ "$base" = "/" ]; then
		return 1;
    fi

	find_dir_in_ancestors "$(dirname $base)" "$target"
	return $?
}

function cd_package_root {
	local target=$(find_dir_in_ancestors "$(pwd)" debian)
	if [ -z "$target" ]; then
		log-fail "package root directory (containing \"./debian\") not found"
		exit 1
	else
		if [ "$target" != "$(pwd)" ]; then
			log-info "package root directory found at \"$target\""
			cd "$target"
		fi
	fi
}
