#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

LANG=C

# if [ "$#" -eq 0 ]; then
#   echo "usage: $(basename $0) <package-name> [debian-package-name]"
#   exit 1
# fi

function field_value() {
    echo "$1" | cut -d':' -f2 | tr -d '[[:space:]]'
    echo
}

function py_version() {
	grep "version *=" setup.py | sed "s/.*version *= *\(['\"0-9\.]\+\),/\1/g" | tr -d '"' | tr -d "'"
}

function pypi_version() {
	local name=$(grep "name *=" setup.py | sed -e "s/.*name *= *\(\S\+\),.*/\1/g" |  tr -d '"' | tr -d "'")
    python ~/repos/ian/bash/last-pypi-version.py $name
}

function deb_version() {
    field_value "$(dpkg-parsechangelog -ldebian/changelog --show-field=Version)"
}

function repo_version() {
	local package=$(dpkg-parsechangelog -ldebian/changelog --show-field=Source)
    field_value "$(apt-cache policy $package | grep Candidate)"
}


log=$(mktemp)

printf "%-15s - setup.py\n" $(py_version) > $log
printf "%-15s - PyPI\n" $(pypi_version) >> $log

if [ -d ./debian ]; then
	printf "%-15s - debian/changelog\n" $(deb_version) >> $log
	printf "%-15s - debian repo candidate\n" $(repo_version) >> $log
fi

echo  version inventory
echo "-----------------"
cat $log | sort
