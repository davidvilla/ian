# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- install ----------------------------------------------------------

function cmd:install {
##:070:cmd:install (with sudo dpkg) all binary packages
    assert-no-more-args

    (
    assert-preconditions
    sc-assert-files-exist $(binary-paths)

    log-info "install"
    ian-sudo "dpkg -i $(binary-paths)"
    notify-install
    log-ok "install"
    )
}

function cmd:build-and-install {
##:combo:010:build-and-install: run "ian build" + "ian install"
    (
    sc-assert cmd:build
    sc-assert cmd:install
    )
}

function cmd:clean-build-and-install {
##:combo:020:clean-build-and-install: run "ian clean" + "ian build" + "ian install"
    (
    sc-assert cmd:clean
    sc-assert cmd:build-and-install
    )
}
