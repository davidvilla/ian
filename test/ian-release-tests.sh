#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source shell-commodity.sh
source unittest.sh

IAN=$(pwd)/ian
export TERM=xterm


TODAY=$(date +%Y%m%d)

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

# 0.1-1          | release         | 0.2-1
# 0.1-1          | release -i      | 0.1-2
# 0.0.1-1        | release         | 0.0.2-1
# 0.0.1-1        | release -i      | 0.0.1-2
# 0.19990203-1   | release         | 0.19990204-1
# 0.19990203-1   | release -i      | 0.19990203-1
# 0.1-1          | release-date    | 0.TODAY-1
# 0.1-1          | release-date -i | 0.1-2
# 0.0.1-1        | release-date    | 0.0.20021122-1
# 0.0.1-1        | release-date -i | 0.0.1-2
# 0.19990203-1   | release-date    | 0.TODAY-1
# 0.19990203-1   | release-date -i | 0.19990203-2
# 0.19990203.2-1 | release-date    | 0.TODAY-1
# 0.19990203.2-1 | release-date -i | 0.19990203.2-2
# 0.TODAY-1      | release-date    | 0.TODAY.1-1
# 0.TODAY.1-1    | release-date    | 0.TODAY.2-1


function _get-version {
	dpkg-parsechangelog -ldebian/changelog --show-field=Version
}

function _set-changelog-version {
	local version="$1"

	cat <<EOF > debian/changelog
hello-ian ($version) unstable; urgency=low

  * Initial release

 -- David Villa Alises <David.Villa@gmail.com>  Fri, 04 Nov 2016 17:32:12 +0000
EOF
}

function test-release-0_1-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.1-1"
	$IAN release -y

	sc-assert-equals $(_get-version) 0.2-1
}

function test-release-i-0_1-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.1-1"
	$IAN release -iy

	sc-assert-equals $(_get-version) 0.1-2
}

function test-release-0_0_1-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.0.1-1"
	$IAN release -y

	sc-assert-equals $(_get-version) 0.0.2-1
}

function test-release-i-0_0_1-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.0.1-1"
	$IAN release -iy

	sc-assert-equals $(_get-version) 0.0.1-2
}

function test-release-0_date-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.19990203-1"
	$IAN release -y

	sc-assert-equals $(_get-version) 0.19990204-1
}

function test-release-i-0_date-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.19990203-1"
	$IAN release -iy

	sc-assert-equals $(_get-version) 0.19990203-2
}

function test-release-date-0_1-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.1-1"
	$IAN release-date -y

	sc-assert-equals $(_get-version) 0.$TODAY-1
}

function test-release-date-i-0_1-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.1-1"
	$IAN release-date -iy

	sc-assert-equals $(_get-version) 0.1-2
}

function test-release-date-0_0_1-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.0.1-1"
	$IAN release-date -y

	sc-assert-equals $(_get-version) 0.$TODAY-1
}

function test-release-date-i-0_0_1-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.0.1-1"
	$IAN release-date -iy

	sc-assert-equals $(_get-version) 0.0.1-2
}

function test-release-date-0_date-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.19990203-1"
	$IAN release-date -y

	sc-assert-equals $(_get-version) 0.$TODAY-1
}

function test-release-date-i-0_date-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.19990203-1"
	$IAN release-date -iy

	sc-assert-equals $(_get-version) 0.19990203-2
}

function test-release-date-0_date_2-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.19990203.2-1"
	$IAN release-date -y

	sc-assert-equals $(_get-version) 0.$TODAY-1
}

function test-release-date-i-0_date_2-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.19990203.2-1"
	$IAN release-date -iy

	sc-assert-equals $(_get-version) 0.19990203.2-2
}

function test-release-date-0_today-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.$TODAY-1"
	$IAN release-date -y

	sc-assert-equals $(_get-version) 0.$TODAY.1-1
}

function test-release-date-0_today_1-1 {
	cd test/fixtures/hello-ian

	_set-changelog-version "0.$TODAY.1-1"
	$IAN release-date -y

	sc-assert-equals $(_get-version) 0.$TODAY.2-1
}


run-testsuit
