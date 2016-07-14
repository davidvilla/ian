#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source shell-commodity.sh

__file__=$0

function testfail {
	sc-log-fail $testname
}

function run-test {
	local testname=$1
    (
    	sc-set-trap testfail
    	eval $testname
    	sc-log-ok $testname
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
