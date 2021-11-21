# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- clean ------------------------------------------------------------

function cmd:clean {
##:030:cmd:clean product files and revert patches
    assert-no-more-args

    (
    assert-preconditions
    log-info "clean"

    ian-run "fakeroot make -f ./debian/rules clean"

    _clean-common

    if valid-watch-present; then
	cmd:clean-uscan
    fi

    log-ok "clean"
    notify-clean
    return 0
    )
}

function _clean-common {
    (
    assert-preconditions
    ian-run "rm -vf $(find-orig-path) $(product-paths) $(binary-paths)"
    )
}

function cmd:clean-uscan {
##:031:cmd:clean uscan related files
    assert-no-more-args

    log-info "clean-uscan"
    # local nline=$(uscan --report --verbose | grep -n "^Newest version on remote" | cut -d":" -f 1)
    # local nline=$(echo $nline - 1 | bc)
    # local url=$(uscan --report --verbose | tail -n +$nline | head -n 1)
    # local upstream_fname=$(basename $url)
    # _ian-rm $(orig-dir)/$upstream_fname
    rm -vf $(_uscan-downloads-paths)
}

# FIXME: to test
function _uscan-downloads-filenames {
    local nline=$(uscan --report --verbose | grep -n "Found the following matching hrefs" | cut -d":" -f 1)
    local nfirst=$(($nline+1))
    local nline=$(uscan --report --verbose | grep -n "version on remote site" | cut -d":" -f 1)
    local nlast=$(($nline-$nfirst))

    uscan --report --verbose  | tail -n +$nfirst | head -n $nlast | while read fname; do
	local path=$(echo "$fname" | cut -d"(" -f 1)
	echo ${path##*/}
    done
}

# FIXME: to test
function _uscan-downloads-paths {
    for fname in $(_uscan-downloads-filenames); do
	echo "$(orig-dir)/$fname";
    done
}

# function _ian-rm {
#     if ! sc-file-exists $1; then
# 	echo rm: missing $1
# 	return
#     fi
#     rm -fv $1
# }
