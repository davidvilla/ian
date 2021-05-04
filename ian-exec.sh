# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

function ian-sudo {
    local command="$1"
    local msg="ian: $command"

    sc-log-info "$msg"
    if ! eval sudo $command 2> >(_indent "$SU_ERR_SIGN") > >(_indent "$SU_OUT_SIGN"); then
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
    #local width=$(( $TERM_COLS - ${#1} ))
    #fold -w $width | sed "s/^/$1/g"
    sed "s/^/$1/g"
}
