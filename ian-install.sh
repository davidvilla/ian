# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- install ----------------------------------------------------------

function cmd:install {
##:install:cmd:install (sudo dpkg) all binary packages
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
##:ship:cmd:run clean + release + orig + build + ian install + upload + git commit
##:ship:usage:ian ship
##:ship:usage:  release is 'release -u -y' when the orig comes from uscan (the version is
##:ship:usage:  upstream's) and 'release-date -y' otherwise
    assert-no-more-args

    (
    ian-check clean
    ian-check $(_ship-release-command)
    ian-check orig
    ian-check build
    ian-check install
    ian-check upload
    _commit-release
    )
}

# the version of a package whose orig comes from uscan is upstream's, not a date
function _ship-release-command {
    if [ "$(_detect-orig-mode)" = uscan ]; then
        echo "release -u -y"
    else
        echo "release-date -y"
    fi
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
