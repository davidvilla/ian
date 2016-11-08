#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source shell-commodity.sh
source unittest.sh

function test-user-is-uploader-ok {
    export DEBEMAIL="David.Villa@gmail.com"

    source ian-util.sh
    source ian-build.sh
    cd test/fixtures/hello-ian
    _assert-user-is-uploader
}

function test-user-is-uploader-fail {
    export DEBEMAIL="John.Doe@gmail.com"

    source ian-util.sh
    source ian-build.sh
    cd test/fixtures/hello-ian

    sc-negative-test
    _assert-user-is-uploader
}

function test-user-last-changelog-entry-ok {
    export DEBEMAIL="David.Villa@gmail.com"

    source ian-util.sh
    source ian-build.sh
    cd test/fixtures/hello-ian

    _assert-user-last-changelog-entry
}

function test-user-last-changelog-entry-fail {
    export DEBEMAIL="John.Doe@gmail.com"

    source ian-util.sh
    source ian-build.sh
    cd test/fixtures/hello-ian

    sc-negative-test
    _assert-user-last-changelog-entry
}

function reset-changelog {
	cat <<EOF > debian/changelog
hello-ian (0.20161104-1) unstable; urgency=low

  * Initial release

 -- David Villa Alises <David.Villa@gmail.com>  Fri, 04 Nov 2016 17:32:12 +0000
EOF
}

function test-release {
	cd test/fixtures/hello-ian

	reset-changelog
	ian release -y
	sc-assert "head -n1 debian/changelog | grep '0.20161105-1'"
}

function test-release-i {
	cd test/fixtures/hello-ian

	reset-changelog
	ian release -yi

	sc-assert "head -n1 debian/changelog | grep '0.20161104-2'"
}

function test-release-date {
	cd test/fixtures/hello-ian

	reset-changelog
	ian release-date -y

	TODAY=$(date +%Y%m%d)
	sc-assert "head -n1 debian/changelog | grep '0.$TODAY-1'"
}

function test-release-date-i {
	cd test/fixtures/hello-ian

	reset-changelog
	ian release-date -yi

	TODAY=$(date +%Y%m%d)
	sc-assert "head -n1 debian/changelog | grep '0.20161104-2'"
}

run-testsuit
