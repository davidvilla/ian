#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

source shell-commodity.sh
source unittest.sh

IAN=$(pwd)/ian
POOL_FIXTURE=$(pwd)/test/fixtures/pool

# sandbox: no user config, throwaway gpg key and pool
export HOME=$__test_tmp__/home
mkdir -p $HOME
# GNUPGHOME must not be $HOME/.gnupg: gpg takes that as the default homedir
# and connects to the user's own agent (/run/user/UID/gnupg/S.gpg-agent)
export GNUPGHOME=$__test_tmp__/gnupg
mkdir -m 700 $GNUPGHOME
if [ "$(gpgconf --list-dirs agent-socket)" = "$(env -u GNUPGHOME HOME=$(getent passwd $USER | cut -d: -f6) gpgconf --list-dirs agent-socket)" ]; then
	echo "test gpg agent would be the user's one, aborting" >&2
	exit 1
fi
trap "gpgconf --kill gpg-agent; rm -rf $__test_tmp__" EXIT

gpg --batch --quiet --pinentry-mode loopback --passphrase '' \
	--quick-gen-key "ian tests <ian-tests@example.net>" ed25519 sign never 2> /dev/null
TEST_KEYID=$(gpg --list-keys --with-colons | awk -F: '/^fpr/ {print $10; exit}')

function _create-pool {
	local pool="$1"
	cp -r $POOL_FIXTURE $pool
	mkdir -p $pool/incoming
	echo "allow * by key ${TEST_KEYID: -16}" > $pool/conf/uploaders
}

export DEBFULLNAME="David Villa Alises"
export DEBEMAIL="David.Villa@gmail.com"
export DEBSIGN_KEYID=$TEST_KEYID
export DEBPOOL=$__test_tmp__/pool
export EDITOR=true
_create-pool $DEBPOOL

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

	local pool=$__test_tmp__/unknown-maintainer-pool
	_create-pool $pool
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
