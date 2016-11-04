# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

OUT_SIGN=" |"
ERR_SIGN=">|"
CHECK_OUT_SIGN="$BLUE$OUT_SIGN$NORMAL"
CHECK_ERR_SIGN="$BLUE$ERR_SIGN$NORMAL"
ROOT_OUT_SIGN="$RED$OUT_SIGN$NORMAL"
ROOT_ERR_SIGN="$RED$ERR_SIGN$NORMAL"


function ian-sudo {
    local command="$1"
    local msg="ian: $command"

    sc-log-info "$msg"
    if ! eval sudo $command 2> >(_indent "$ROOT_ERR_SIGN") > >(_indent "$ROOT_OUT_SIGN"); then
	sc-log-fail "$msg"
	exit 1
    fi
}

function check-run() {
    local command="$1"
    local msg="ian: $command"

    sc-log-info "$msg"
    if ! eval $command 2> >(_indent "$CHECK_ERR_SIGN") > >(_indent "$CHECK_OUT_SIGN"); then
	sc-log-fail "$msg"
	exit 1
    fi
}

function ian-run {
    eval $1 2> >(_indent "$ERR_SIGN") > >(_indent "$OUT_SIGN")
}

function _indent {
    sed "s/^/    $1/g"
}
