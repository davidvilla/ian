# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

# release, assertions
function assert-debian-files {
    sc-assert-directory-exists ./debian
    sc-assert-files-exist ./debian/control ./debian/rules ./debian/changelog
}

function _debvars-missing {
    ian-help-debvars-examples
    exit 1
}

function assert-debvars {
    sc-set-trap _debvars-missing
    sc-assert-var-defined DEBFULLNAME
    sc-assert-var-defined DEBEMAIL
    sc-assert-var-defined DEBSIGN_KEYID
    sc-assert-var-defined DEBREPO_URL
    sc-clear-trap
}

# ""many"
function assert-preconditions {
    if [ "$PRECONDITIONS_CHECKED" = true ]; then
	return 0
    fi

    assert-debvars
    assert-debian-files
    PRECONDITIONS_CHECKED=true
}

# build
function assert-uses-svn {
    sc-assert uses-svn "" "This debian package is not managed with svn-buildpackage"
}

# "all commands"
function assert-no-more-args {
	local end=$1
	local remaining

	if ! [[ -z $end ]]; then
		index=$(expr $end - 1)
		remaining="${__args__[@]:$index}"
	fi

	if ! [ -z "$remaining" ]; then
		log-error "unexpected arguments: $remaining"
		exit 1
	fi
}
