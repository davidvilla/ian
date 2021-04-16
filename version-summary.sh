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
	if [ ! -f setup.py ]; then
		echo None
		return
	fi

	python3 setup.py --version 2> /dev/null
}

function pypi_version() {
	if [ ! -f setup.py ]; then
		echo None
		return
	fi

	local name=$(grep "name *=" setup.py | sed -e "s/.*name *= *\(\S\+\),.*/\1/g" |  tr -d '"' | tr -d "'")
    last-pypi-version $name
}

function deb_version() {
    field_value "$(dpkg-parsechangelog -ldebian/changelog --show-field=Version)"
}

function repo_version() {
	# local package=$(dpkg-parsechangelog -ldebian/changelog --show-field=Source)
	local package=$(grep "^Package:" debian/control | cut -f2 -d:  | tr -d " " | head -n1)
    field_value "$(apt-cache policy $package | grep Candidate)"
}


log=$(mktemp)

printf "%-15s - setup.py\n" $(py_version) > $log
printf "%-15s - PyPI\n" $(pypi_version) >> $log

if [ -d ./debian ]; then
	printf "%-15s - debian/changelog\n" $(deb_version) >> $log
	printf "%-15s - debian repo candidate\n" $(repo_version) >> $log
fi

echo  version summary
echo "---------------"
cat $log
