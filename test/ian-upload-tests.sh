#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source shell-commodity.sh
source unittest.sh

IAN=$(pwd)/ian

function test-deb-already-registered {
	# same upstream-version and debian-release but different package contents

	cd-fixture examples/hello-ian
	$IAN remove -y

	echo 1 > content
	$IAN build -c
	$IAN upload
	$IAN clean

	echo 2 > content
	$IAN build -c
	$IAN upload
	$IAN clean

	$IAN remove -y
}

function test-orig-not-yet-registered {
	# Upload a -2 version with no previous upload, so no sources in the pool

	cd-fixture examples/hello-ian
	$IAN remove -y

	echo 1 > content
	$IAN release -yi
	$IAN build -c
	$IAN upload
	$IAN clean

	$IAN remove -y
}

function test-orig-already-registered {
	# A different orig was uploaded for the same upstream version

	cd-fixture examples/hello-ian
	$IAN remove -y

	echo 1 > content
	$IAN build -c
	$IAN upload
	$IAN clean

	echo 2 > content
	$IAN release -yi
	$IAN build -c
	$IAN upload
	$IAN clean

	$IAN remove -y
}

function test-pool-unknown-maintainer {
	# upload without gpg fingerprint in conf/uploaders

	local pool=$(mktemp -d -p "$__test_tmp__")
	rmdir $pool
	cp -r $HOME/repos/ian-test-pool/docs $pool
	echo "# empty" > $pool/conf/uploaders
	export DEBPOOL=$pool

	(
	cd-fixture examples/hello-ian
	$IAN remove -y

	$IAN release -y
	$IAN build -c

	local dupload_err=$(mktemp -p "$__test_tmp__")
	$IAN upload > $dupload_err
	$IAN clean

	$IAN remove -y

	grep "dupload: error: Post-upload" $dupload_err
	)
}

run-testsuit
