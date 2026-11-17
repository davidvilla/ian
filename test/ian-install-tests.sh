#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source shell-commodity.sh
source unittest.sh

export TERM=xterm

# sandbox: no user config
export HOME=$__test_tmp__/home
mkdir -p $HOME

DEB=../hello_1.0-1_all.deb

# "ian install" without a built package: what these tests check is the command it runs,
# not the preconditions, so the package and the sudo call are faked
function _fake-install-environment {
	source ian-util.sh
	source ian-assertions.sh
	source ian-install.sh

	function assert-preconditions { :; }
	function sc-assert-files-exist { :; }
	function binary-paths { echo "$DEB"; }
	function sh-sudo { echo "SUDO: $1"; }
}

function _sudo-command {
	cmd:install | sed -n 's/^SUDO: //p'
}

function test-install-runs-dpkg {
	_fake-install-environment
	__args__=()

	sc-assert-equals "$(_sudo-command)" "dpkg -i $DEB"
}

function test-install-d-installs-dependencies {
	_fake-install-environment
	__args__=(-d)

	sc-assert-equals "$(_sudo-command)" "apt-get install --yes --no-remove $DEB"
}

function test-install-rejects-unknown-option {
	_fake-install-environment
	__args__=(-z)

	sc-assert-false "( cmd:install > /dev/null 2>&1 )"
}

function test-install-rejects-arguments {
	_fake-install-environment
	__args__=(foo)

	sc-assert-false "( cmd:install > /dev/null 2>&1 )"
}

run-testsuit
