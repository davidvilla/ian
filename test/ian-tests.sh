#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source shell-commodity.sh
source unittest.sh

function _negative {
    return 0
}

function test-user-is-uploader-ok {
    export DEBEMAIL="David.Villa@gmail.com"

    source ian-util.sh
    source ian-build.sh
    cd test/unit/build-force
    _assert-user-is-uploader > /dev/null
}

function test-user-is-uploader-fail {
    export DEBEMAIL="John.Doe@gmail.com"

    source ian-util.sh
    source ian-build.sh
    cd test/unit/build-force

    sc-negative-test
    _assert-user-is-uploader > /dev/null
}

function test-user-last-changelog-entry-ok {
    local output=
    export DEBEMAIL="David.Villa@gmail.com"

    source ian-util.sh
    source ian-build.sh
    cd test/unit/build-force

    _assert-user-last-changelog-entry >> /dev/null
}

function test-user-last-changelog-entry-fail {
    local output=
    export DEBEMAIL="John.Doe@gmail.com"

    source ian-util.sh
    source ian-build.sh
    cd test/unit/build-force

    sc-negative-test
    _assert-user-last-changelog-entry > /dev/null
}

run-testsuit
