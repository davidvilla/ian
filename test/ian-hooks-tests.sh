#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source shell-commodity.sh
source unittest.sh
source ian-util.sh
source ian-exec.sh
source ian-hooks.sh

export TERM=xterm
unset IAN_DISABLE_HOOKS

# commands and hooks write their name here, in the order they run
TRACE=

function _setup {
	TRACE=$(mktemp)

	function cmd:thing { echo thing >> $TRACE; }
	function cmd:broken { echo broken >> $TRACE; return 3; }
	function cmd:build { echo build >> $TRACE; }
	function cmd:clean { echo clean >> $TRACE; }
	function cmd:summary { echo summary >> $TRACE; }

	# what the warnings are, and not how they are shown (nor the delay of "deprecation")
	function deprecation { echo deprecated >> $TRACE; }
	function log-warning { echo discarded >> $TRACE; }
}

function _trace {
	tr '\n' ' ' < $TRACE | sed 's/ $//'
	rm -f $TRACE
}

function test-hooks-of-a-command-that-succeeds {
	_setup
	function ian-thing-pre-hook { echo pre >> $TRACE; }
	function ian-thing-post-hook { echo post >> $TRACE; }
	function ian-thing-ok-hook { echo ok >> $TRACE; }
	function ian-thing-fail-hook { echo fail >> $TRACE; }

	run-cmd thing
	sc-assert-equals "$(_trace)" "pre thing post ok"
}

function test-hooks-of-a-command-that-fails {
	_setup
	function ian-broken-pre-hook { echo pre >> $TRACE; }
	function ian-broken-post-hook { echo post >> $TRACE; }
	function ian-broken-ok-hook { echo ok >> $TRACE; }
	function ian-broken-fail-hook { echo fail >> $TRACE; }

	run-cmd broken
	sc-assert-equals "$(_trace)" "pre broken post fail"
}

function test-run-cmd-returns-the-command-code {
	_setup
	local rcode=0

	run-cmd broken || rcode=$?
	sc-assert-equals $rcode 3
}

function test-run-cmd-survives-an-exit-of-the-command {
	_setup
	function cmd:aborted { echo aborted >> $TRACE; exit 1; }
	function ian-aborted-fail-hook { echo fail >> $TRACE; }

	run-cmd aborted
	sc-assert-equals "$(_trace)" "aborted fail"
}

function test-hooks-of-a-command-run-by-another-one {
	_setup
	function cmd:outer { run-cmd thing; }
	function ian-thing-pre-hook { echo pre >> $TRACE; }

	run-cmd outer
	sc-assert-equals "$(_trace)" "pre thing"
}

function test-hooks-disabled {
	_setup
	function ian-thing-pre-hook { echo pre >> $TRACE; }

	export IAN_DISABLE_HOOKS=1
	run-cmd thing
	unset IAN_DISABLE_HOOKS
	sc-assert-equals "$(_trace)" "thing"
}

function test-a-hook-does-not-stop-the-command {
	_setup
	function ian-thing-pre-hook { echo pre >> $TRACE; exit 1; }

	run-cmd thing
	sc-assert-equals "$(_trace)" "pre thing"
}

function test-a-hook-does-not-change-the-directory-of-ian {
	_setup
	function ian-thing-post-hook { cd /; }
	local before=$(pwd)

	run-cmd thing
	sc-assert-equals "$(pwd)" "$before"
}

function test-a-command-that-only-shows-information-has-no-hooks {
	_setup
	function ian-summary-pre-hook { echo pre >> $TRACE; }
	function ian-summary-post-hook { echo post >> $TRACE; }
	function ian-summary-ok-hook { echo ok >> $TRACE; }

	run-cmd summary
	sc-assert-equals "$(_trace)" "summary"
}

function test-deprecated-hook-runs-as-post {
	_setup
	function ian-clean-hook { echo old >> $TRACE; }

	run-cmd clean
	sc-assert-equals "$(_trace)" "clean deprecated old"
}

function test-deprecated-build-start-hook-runs-as-pre {
	_setup
	function ian-build-start-hook { echo old >> $TRACE; }

	run-cmd build
	sc-assert-equals "$(_trace)" "deprecated old build"
}

function test-deprecated-build-end-hook-runs-as-ok {
	_setup
	function ian-build-end-hook { echo old >> $TRACE; }

	run-cmd build
	sc-assert-equals "$(_trace)" "build deprecated old"
}

function test-deprecated-hook-discarded-when-its-replacement-is-defined {
	_setup
	function ian-clean-hook { echo old >> $TRACE; }
	function ian-clean-post-hook { echo new >> $TRACE; }

	run-cmd clean
	sc-assert-equals "$(_trace)" "clean discarded new"
}

run-testsuit
