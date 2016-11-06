#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source shell-commodity.sh

__file__=$0

function testfail {
	sc-log-fail $testname
}

function testok {
    sc-log-ok $testname
}

function sc-negative-test {
    sc-clear-trap
	sc-set-trap testok
	success=testfail
}

function run-test {
	local testname=$1
	success=testok
    (
    	sc-set-trap testfail
    	eval $testname
		eval $success
    	sc-clear-trap
    )
}

function run-testsuit {
	local testname=$1

	if [[ -n $testname ]]; then
		run-test $testname
		return
	fi

    grep "^function test-" $__file__ | while read line; do
        testname=$(echo $line | cut -d' ' -f 2)
		run-test $testname
    done
}
