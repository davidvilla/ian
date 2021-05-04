#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source shell-commodity.sh
source unittest.sh

function test-deb-already-registered {
	# same upstream-version and debian-release but different package contents

	cd examples/hello-ian
	git checkout debian 2> /dev/null
	ian remove -y

	echo 1 > content
	ian build -c
	ian upload
	ian clean

	echo 2 > content
	ian build -c
	ian upload
	ian clean

	ian remove -y
}

function test-orig-not-yet-registered {
	# Upload a -2 version with no previous upload, so no sources in the pool

	cd examples/hello-ian
	git checkout debian 2> /dev/null
	ian remove -y

	echo 1 > content
	ian release -yi
	ian build -c
	ian upload
	ian clean

	ian remove -y
}

function test-orig-already-registered {
	# A different orig was uploaded for the same upstream version

	cd examples/hello-ian
    git checkout debian 2> /dev/null
	ian remove -y

	echo 1 > content
	ian build -c
	ian upload
	ian clean

	echo 2 > content
	ian release -yi
	ian build -c
	ian upload
	ian clean

	ian remove -y
}

function test-pool-unknown-maintainer {
	# upload without gpg fingerprint in conf/uploaders

	local pool="/tmp/ian-pool"
	rm -rf $pool
	cp -r $HOME/repos/ian-test-pool/docs $pool
	echo "# empty" > $pool/conf/uploaders
	export DEBPOOL=$pool

	(
	cd examples/hello-ian
    git checkout debian 2> /dev/null
	ian remove -y

	ian release -y
	ian build -c

	local dupload_err=/tmp/$(uuidgen)
	ian upload > $dupload_err
	ian clean

	ian remove -y
	git checkout debian 2> /dev/null

	grep "dupload: error: Post-upload" $dupload_err
	)
}

run-testsuit
