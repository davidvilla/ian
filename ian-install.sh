# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- install ----------------------------------------------------------

function cmd:install {
##:070:cmd:install (sudo dpkg) all binary packages
    assert-no-more-args

    (
    assert-preconditions
    sc-assert-files-exist $(binary-paths)

    log-info "install"
    sh-sudo "dpkg -i $(binary-paths)"
    log-ok "install"
    )
}

function cmd:build-and-install {
##:combo:010:build-and-install: run "ian build" + "ian install"
    (
    ian-check build
    ian-check install
    )
}

function cmd:clean-build-and-install {
##:combo:020:clean-build-and-install: run "ian clean" + "ian build" + "ian install"
    (
    ian-check clean
    ian-check build-and-install
    )
}

function cmd:ship {
##:095:cmd:run clean + release-date -y + orig + build + ian install + upload + git commit
    assert-no-more-args

    (
    ian-check clean
    ian-check release-date -y
    ian-check orig
    ian-check build
    ian-check install
    ian-check upload
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

    sh-check "git commit -am '$msg'"
}
