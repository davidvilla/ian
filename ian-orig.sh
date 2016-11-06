# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- get/create orig --------------------------------------------------------

# build the upstream orig file from:
# - from-rule: regenerated by "debian/rules get-orig-source"
# - uscan
# - from "local" files
function cmd:orig {
##:015:cmd:generate or download .orig. file

    assert-no-more-args

    (
    assert-preconditions
	if [ -f $(orig-path) ]; then
	    log-warning "orig $(orig-path) is present"
	    return
	fi

	log-warning "orig $(orig-path) DOES NOT exist, getting/creating it"

	cmd:clean

	sc-assure-dir $(orig-dir)
	log-info "orig"

    if _has-rule get-orig-source; then
		cmd:orig-from-rule
    elif valid-watch-present; then
		cmd:orig-uscan
    else
		cmd:orig-from-local
    fi

    sc-assert-files-exist $(orig-path)
    log-ok "orig"
    )
}

function cmd:orig-from-rule {
##:017:cmd:execute "get-orig-source" rule of debian/rules to get .orig. file
    assert-no-more-args

    check-run "make -f ./debian/rules get-orig-source"
    mv -v $(orig-filename) $(orig-dir)/
}

# http://people.debian.org/~piotr/uscan-dl
function cmd:orig-uscan {
##:018:cmd:execute uscan to download the .orig. file
    assert-no-more-args

    _assert-valid-watch
    log-info "orig-uscan"
    uscan --verbose --download-current-version --force-download --repack --rename --destdir $(orig-dir)
}

function cmd:orig-from-local {
##:016:cmd:create an .orig. file from current directory content
    assert-no-more-args

    log-info "orig-from-local"

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

# summary
function orig-methods {
    if _has-rule get-orig-source; then
		methods[0]='from-rule'
    fi
    if valid-watch-present; then
		methods[1]='uscan'
    fi
    if [ $(ls | wc -l) -gt 1 ]; then
		methods[2]='from-local'
    fi

    if [ ${#methods[@]} -eq 0 ]; then
		echo "none!"
		return
    fi

    echo "${methods[@]}"
}

function _has-rule {
    grep -qs "^$1:" debian/rules
}

function _assert-valid-watch {
    sc-assert valid-watch-present
}
