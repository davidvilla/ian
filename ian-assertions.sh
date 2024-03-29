# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

function assert-debian-files {
    cd_package_root
    sc-assert-directory-exists ./debian
    sc-assert-files-exist ./debian/control ./debian/rules ./debian/changelog
}

function _debvars-missing {
    ian-help-debvars-examples
    exit 1
}

#FIMXE: move to ian-config.sh
#FIXME: rename "debvars" to "config"
function assert-debvars {
    if sc-var-defined DEBREPO_URL; then
        (>&2 log-warning "Variable DEBREPO_URL is now DEPRECATED. Rename to DEBPOOL")
    fi

    if sc-var-defined DEBREPO_LOCAL_DIR; then
        (>&2 log-warning "Variable DEBREPO_LOCAL_DIR is now DEPRECATED. Rename to DEBPOOL")
    fi

    sc-set-trap _debvars-missing
    sc-assert-var-defined DEBFULLNAME
    sc-assert-var-defined DEBEMAIL
    sc-assert-var-defined DEBSIGN_KEYID
    sc-assert-var-defined DEBPOOL
    sc-assert-var-defined EDITOR
    sc-clear-trap
}

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

    __args__=""
}
