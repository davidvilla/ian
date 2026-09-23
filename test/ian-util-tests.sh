#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source shell-commodity.sh
source unittest.sh
source ian-util.sh
source ian-build.sh

export TERM=xterm


function _set-version {
	export _DEBIAN_VERSION="$1"
}

function test-debian-release {
	_set-version "0.1-2arco1"
	sc-assert-equals $(debian-release) 2arco1
}

function test-orig-seems-new {
	_set-version "0.1-1"
	sc-assert orig-seems-new
}

function test-orig-seems-new-non-numeric {
	_set-version "0.1-1arco1"
	sc-assert orig-seems-new
}

function test-orig-seems-new-backport {
	_set-version "0.1-1~bpo12+1"
	sc-assert orig-seems-new
}

function test-orig-seems-new-native {
	_set-version "0.1"
	sc-assert orig-seems-new
}

function test-not-orig-seems-new {
	_set-version "0.1-2"
	sc-assert-false orig-seems-new
}

function test-not-orig-seems-new-non-numeric {
	_set-version "0.1-3.1arco1"
	sc-assert-false orig-seems-new
}

function test-not-orig-seems-new-nmu {
	_set-version "0.1-1.1"
	sc-assert-false orig-seems-new
}

function _make-orig {
	local tmp=$(mktemp -d)

	mkdir -p $tmp/src/hello-1.0/debian
	mkdir $tmp/src/hello-1.0/src
	touch $tmp/src/hello-1.0/setup.py $tmp/src/hello-1.0/README
	tar --create --gzip --file $tmp/hello_1.0.orig.tar.gz --directory $tmp/src hello-1.0
	echo $tmp
}

function test-upstream-sources-missing {
	local tmp=$(_make-orig)

	mkdir $tmp/packaging && cd $tmp/packaging && mkdir debian
	sc-assert _upstream-sources-missing $tmp/hello_1.0.orig.tar.gz
}

function test-upstream-sources-present {
	local tmp=$(_make-orig)

	cd $tmp/src/hello-1.0
	sc-assert-false _upstream-sources-missing $tmp/hello_1.0.orig.tar.gz
}

function test-upstream-sources-missing-with-leftover-dir {
	local tmp=$(_make-orig)

	mkdir $tmp/packaging && cd $tmp/packaging && mkdir debian src
	sc-assert _upstream-sources-missing $tmp/hello_1.0.orig.tar.gz
}

function test-upstream-sources-without-orig {
	sc-assert-false _upstream-sources-missing /nonexistent.orig.tar.gz
}

run-testsuit
