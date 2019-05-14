#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source /usr/share/ian/shell-commodity.sh

__file__=$0
__testname__=$1

function __test-log-ok {
    sc-log-ok $__test_name
}

function __test-log-fail {
	sc-log-fail $__test_name
}

function __test-log-error {
    sc-log-error $__test_name
}

function _trap-handler {
	eval $test_failed
	if [ $test_failed == __test-log-ok ]; then
		echo 0 > $test_result
	else
		echo 1 > $test_result
	fi
}

function _positive-test {
	test_success="__test-log-ok"
	test_failed="__test-log-fail"
}

function sc-negative-test {
	test_success="__test-log-fail"
	test_failed="__test-log-ok"
}

function _trap-handler-negative {
	__test-log-ok
}

function sc-test-not {
	(
		sc-set-trap _trap-handler-negative
		eval "$*"
		__test-log-fail
	)
}

function run-test {
	__test_name="$1"
	if [ "$DEBUG" != true ]; then
		__test_name="$__test_name > /dev/null"
	else
		__test_name="$__test_name > >(sed 's/^/     |/g')"
	fi

	test_result=$(mktemp)
	echo 0 > $test_result
    (
		sc-set-trap _trap-handler
		_positive-test
    	eval "$__test_name"
		if [ $? -ne 0 ]; then
			__test-log-error
		else
			eval "$test_success"
		fi
    	sc-clear-trap
    )
	local retval=$(cat $test_result)

	rm -f $test_result
	return $retval
}

function run-testsuit {
	local retval=0
	local test=

	if [[ -n $__testname__ ]]; then
		run-test $__testname__
		return
	fi

	for testname in $(grep "^function test-" $__file__ | cut -d' ' -f2); do
		run-test $testname
		if [ $? -ne 0 ]; then
			retval=1
		fi
    done
	return $retval
}
