#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source bash/shell-commodity.sh

__file__=$0

function testfail {
	sc-log-fail $testname
}

function run-testsuit {
    grep "^function test-" $__file__ | while read line; do
        testname=$(echo $line | cut -d' ' -f 2)
    	(
    	    sc-set-trap testfail
    	    eval $testname
    	    sc-log-ok $testname
    	    sc-clear-trap
    	)
    done
}
