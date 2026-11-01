# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- install ----------------------------------------------------------

function cmd:install {
##:070:cmd:install (sudo dpkg) all binary packages
    assert-no-more-args

    (
    assert-preconditions
    sc-assert-files-exist $(binary-paths)

    log-info "install"
    ian-sudo "dpkg -i $(binary-paths)"
    log-ok "install"
    )
}

function cmd:build-and-install {
##:combo:010:build-and-install: run "ian build" + "ian install"
    (
    sc-assert "run-cmd build"
    sc-assert "run-cmd install"
    )
}

function cmd:clean-build-and-install {
##:combo:020:clean-build-and-install: run "ian clean" + "ian build" + "ian install"
    (
    sc-assert "run-cmd clean"
    sc-assert "run-cmd build-and-install"
    )
}

function cmd:ship {
##:095:cmd:run "ian clean" + "ian release-date -y" + "ian build" + "ian install" + "ian upload" + "git commit"
    assert-no-more-args

    (
    sc-assert "run-cmd clean"
    # the commands read their options from __args__, not from their parameters
    __args__=(-y)
    sc-assert "run-cmd release-date"
    __args__=()
    sc-assert "run-cmd build"
    sc-assert "run-cmd install"
    sc-assert "run-cmd upload"
    _commit-release
    )
}

function _commit-release {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        log-warning "not a git repository, release not committed"
        return
    fi

    # the release changed the changelog: the cached version is the previous one
    unset _DEBIAN_VERSION
    local msg="new-release: $(debian-version)"

    log-info "git commit: $msg"
    sc-assert "ian-run \"git commit -am '$msg'\""
    log-ok "git commit"
}
