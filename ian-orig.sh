# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- get/create orig --------------------------------------------------------

# build the upstream orig file from:
# - from-rule: regenerated by "debian/rules get-orig-source"
# - uscan
# - from "local" files
function cmd:orig {
##:015:cmd:generate or download the .orig. file. See 'ian help orig'.
##:015:usage:ian orig [mode]
##:015:usage:  mode;    the way to create orig [rule|uscan|local]
##:015:usage:
##:015:usage:  - rule;  run debian/rules "get-orig-source" rule to get/build .orig.
##:015:usage:  - uscan; run uscan to download the .orig.
##:015:usage:  - local; create an .orig. from current directory contents.

    local mode="${__args__[@]}"
    assert-no-more-args

	if [ -f $(orig-path) ]; then
	    log-error "orig $(orig-path) is present"
	    return
	fi


    if [ -z "$mode" ]; then
        local mode=$(_detect-orig-mode)
        log-ok "aplying detected orig mode: $mode"
    else
        log-info "orig mode: $mode"
    fi

    case $mode in
    rule)
    local orig_func="orig-from-rule"
    ;;

    uscan)
    local orig_func="orig-uscan"
    ;;

    local)
    local orig_func="orig-from-local"
    ;;

    *)
    log-error "wrong orig mode: $mode. See 'ian help orig'"
    exit 1
    ;;
    esac

    (
    assert-preconditions
	  if [ ! -f $(orig-path) ]; then
	      log-warning "missing orig '$(orig-path)', getting/creating it"
	  fi
    cmd:clean
    sc-assure-dir $(orig-dir)

    $orig_func

    sc-assert-files-exist $(orig-path)
    log-ok "orig"
    )
}

function cmd:orig-from-rule {
    (>&2 deprecation "command orig-from-rule is DEPRECATED. Use 'ian orig rule'")
    __args__="rule"
    cmd:orig
}

function cmd:orig-uscan {
    (>&2 deprecation "command orig-uscan is DEPRECATED. Use 'ian orig uscan'")
    __args__="uscan"
    cmd:orig
}

function cmd:orig-from-local {
    (>&2 deprecation "command orig-from-local is DEPRECATED. Use 'ian orig local'")
    __args__="local"
    cmd:orig
}


function orig-from-rule {
    sc-assert _has-rule get-orig-source "missing 'get-orig-source' in 'debian/rules'"

    check-run "make -f ./debian/rules get-orig-source"
    mv -v $(orig-filename) $(orig-dir)/
}

# http://people.debian.org/~piotr/uscan-dl
function orig-uscan {
    _assert-valid-watch

    check-run "uscan --verbose --download-current-version --force-download --repack --rename --destdir $(orig-dir)"
}

function orig-from-local {
    local orig_tmp=$(upstream-fullname)
    mkdir -p $orig_tmp

    local EXCLUDE="--exclude=$orig_tmp --exclude=./debian --exclude=\*~ --exclude-vcs --exclude=\*.pyc --exclude .pc"

    tar $EXCLUDE -cf - . | ( cd $orig_tmp && tar xf - )
    tar czf $(orig-path) $orig_tmp
    \rm -rf $orig_tmp
	  log-ok "orig file created: $(orig-path)"
}

# clean, orig
function orig-dir {
    echo ..
}

# repo, orig, path
function orig-filename {
    echo $(package)_$(upstream-version).orig.tar.gz
}
# orig, build, summary
function orig-path {
    echo $(orig-dir)/$(orig-filename)
}

function _detect-orig-mode {
    echo $(orig-modes) | awk '{print $1;}'
}

# summary
function orig-modes {
    if _has-rule get-orig-source; then
		methods[0]='rule'
    fi
    if valid-watch-present; then
		methods[1]='uscan'
    fi
    # if [ $(ls | wc -l) -gt 1 ]; then
		methods[2]='local'
    # fi

    # if [ ${#methods[@]} -eq 0 ]; then
		# echo "none!"
		# return
    # fi

    echo "${methods[@]}"
}

function _has-rule {
    grep -qs "^$1:" debian/rules
}

function _assert-valid-watch {
    sc-assert valid-watch-present
}
