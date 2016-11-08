#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source shell-commodity.sh
source unittest.sh

function test-deb-already-registered {
	# same upstream-version and debian-release but different package contents

	cd test/fixtures/upload-issues
	hg revert debian
	ian remove -y

	echo 1 > content
	ian build -c
	ian upload

	echo 2 > content
	ian build -c
	ian upload

	ian remove -y
	ian clean
}

function test-orig-not-yet-registered {
	# Upload a -2 version with no previous upload, so no sources in the pool

	cd test/fixtures/upload-issues
	hg revert debian
	ian remove -y

	echo 1 > content
	ian release -yi
	ian build -c
	ian upload

	ian remove -y
	ian clean
}

function test-orig-already-registered {
	# A different orig was uploaded for the same upstream version

	cd test/fixtures/upload-issues
	hg revert debian
	ian remove -y

	echo 1 > content
	ian build -c
	ian upload

	echo 2 > content
	ian release -yi
	ian build -c
	ian upload

	ian remove -y
	ian clean
}

run-testsuit
