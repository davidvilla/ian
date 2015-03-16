#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

LANG=C

if [ "$#" -eq 0 ]; then
  echo "usage: $(basename $0) <package-name>"
  exit 1
fi

function field_value() {
    echo "$1" | cut -d':' -f2 | tr -d '[[:space:]]'
    echo
}

function py_version() {
    sed "s/ *__version__ *= *'\([0-9\.]\+\)'/\1/g" version.py
}

function pypi_version() {
    python ~/repos/ian/bash/last-pypi-version.py $name
}

function deb_version() {
    field_value "$(ian summary | grep upstream)"
}

function repo_version() {
    field_value "$(apt-cache policy $package | grep Candidate)"
}

name="$1"
package="${2:-$name}"

log=$(mktemp)

echo "$(py_version)   - setup.py" > $log
echo "$(pypi_version)   - PyPI" >> $log

if [ -d ./debian ]; then
	echo "$(deb_version)   - debian/changelog" >> $log
	echo "$(repo_version) - debian repo candidate" >> $log
fi

echo  version inventory
echo "-----------------"
cat $log | sort
