#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

sudo dpkg -r hello-ian
rm -rf ./debian

set -e

ian create; ian build; ian install
result=$(my-hello)

expected=$(grep hello my-hello.sh | cut -d'"' -f 2)

[ "$expected" == "$result" ] && echo OK || (echo FAIL; exit 1)
