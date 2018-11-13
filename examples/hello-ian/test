#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

function clean {
	sudo dpkg -r hello-ian
	ian clean
	rm -rf ./debian test
}

clean

set -e

ian create; ian build; ian install
result=$(my-hello)
expected=$(grep hello my-hello.sh | cut -d'"' -f 2)

clean
[ "$expected" == "$result" ] && echo OK || (echo FAIL; exit 1)
