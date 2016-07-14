#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source ../shell-commodity.sh

function test {
    local -a outputs
    sc-call-out-err outputs ./write_out_err.py

	sc-assert "[ ${outputs[1]} == stdout-write ]"
	sc-assert "[ ${outputs[2]} == stderr-write ]"
}

test
