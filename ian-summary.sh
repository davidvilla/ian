# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

function cmd:summary {
##:010:cmd:show package info

    assert-no-more-args

    (
    assert-preconditions
    echo "source:             " $(package)
    echo "upstream:           " $(upstream-version)
    if valid-watch-present; then
	echo "watch:              " $(_upstream-version-uscan)
    fi
    echo "version:            " $(debian-version)
    echo "orig:               " $(orig-path)
    echo "orig methods:       " $(orig-methods)
    echo "changes:            " $(changes-path)
    echo "binaries:           " $(binary-names)
    echo "pkg vcs:            " $(_pkg-vcs)

    local missing_deps=$(builddeps)
    if [ $? -ne 0 ]; then
	echo "missing build deps: " $missing_deps
    fi
    )
}

function cmd:name {
##:009:cmd:show package name and current version

    assert-no-more-args

    (
	assert-preconditions
	echo $(package)-$(debian-version)
	)
}

function _pkg-vcs {
    # the <VCS-buildpackage> that the maintainer uses to manage de package
    if uses-svn; then
	echo "svn"
	return
    fi
    echo "none"
}

function _upstream-version-uscan {
    local -a outputs
    sc-call-out-err outputs uscan --report --verbose

    local stderr_nlines=$(wc -l ${outputs[2]} | cut -d' ' -f1)
    if [ $stderr_nlines -gt 0 ]; then
	log-warning "error: see stderr: ${outputs[2]} stdout: ${outputs[1]}"
	return
    fi

    cat "${outputs[1]}" | grep "Newest version" |  cut -d"," -f1 | sed "s/site is /@/g" | cut -d@ -f2
    rm ${outputs[@]}
}
