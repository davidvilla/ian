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
    # $1: package name
    local index=$(grep "Package:" debian/control | grep -n $1 | cut -f1 -d":"  | head -n1)
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
    # get binary package names from control
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

# orig, build
function upstream-fullname {
    echo $(package)-$(upstream-version)
}

# release, orig, summary
function upstream-version {
    echo $(debian-version) | cut -f1 -d "-"
}

# build, summary
function builddeps {
    dpkg-checkbuilddeps 2>&1 | cut -f3 -d':' | sed -e 's/([^][]*)//g'
    return ${PIPESTATUS[0]}
}

# repo, build, path
function build-dir {
    echo ".."
}
