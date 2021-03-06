#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source shell-commodity.sh
source unittest.sh

function test-upper {
    local result=$(sc-upper hello)
    sc-assert '[ "$result" = "HELLO" ]'
}

function test-sc-retcode2bool-True {
	true
	local result=$(sc-retcode2bool $?)

	sc-assert '[ "$result" = True ]'
}

function test-sc-retcode2bool-False {
	false
	local result=$(sc-retcode2bool $?)

	sc-assert '[ "$result" = False ]'
}


function test-sc-retcode2test-OK {
	true
	local result=$(sc-retcode2test $?)

	sc-assert '[ "$result" = OK ]'
}

function test-sc-retcode2test-FAIL {
	false
	local result=$(sc-retcode2test $?)

	sc-assert '[ "$result" = FAIL ]'
}

function return-this {
	return $1
}

function test-sc-func2bool-True {
	local result=$(sc-func2bool "return-this 0")

	sc-assert '[ "$result" = True ]'
}

function test-sc-func2bool-False {
	local result=$(sc-func2bool "return-this 1")

	sc-assert '[ "$result" = False ]'
}

function test-sc-str-replace {
	local result=$(sc-str-replace la KO falailaba)

	sc-assert '[ "$result" = faKOiKOba ]'
}

function test-str-split {
	local result=$(sc-str-split "do:re:mi" ":" | wc -l)

	sc-assert '[ $result -eq 3 ]'
}

function test-equals {
	sc-assert-equals "test output" "test output"
	sc-assert-equals "$(echo test output)" "test output"
	sc-assert-equals 1 1
}

function test-not-equals {
	sc-assert-not-equals "test output" "other output"
}

function test-call-out-err {
    local -a outputs
    sc-call-out-err outputs ./test/write_out_err.py

    local stdout=${outputs[1]}
    local stderr=${outputs[2]}

    local stdout_content=$(cat $stdout)
    local stderr_content=$(cat $stderr)

	sc-assert "[ $stdout_content == stdout-write ]"
	sc-assert "[ $stderr_content == stderr-write ]"
}


run-testsuit
