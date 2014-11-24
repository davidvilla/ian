#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

JAIL_CONFIG=/etc/schroot/chroot.d/ian
JAIL_DCONFIG=/etc/schroot/ian
JAIL_DIR_TMP=$(mktemp -d)
JAIL_DIR=/var/jails
USER_FSTAB=$HOME/.config/ian/fstab
MIRROR=${DEBIAN_MIRROR:-http://ftp.debian.org}/debian

DPKG_OPTS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew"

function jail:name {
    echo sid-$JAIL_ARCH-ian
}

function jail:tarball {
	echo $JAIL_DIR/$(jail:name).tar
}

function jail:setup {
    local JAIL_FSTAB=$JAIL_DCONFIG/fstab

    if [ -e $USER_FSTAB ]; then
		sudo cat $USER_FSTAB >> $JAIL_FSTAB
    fi
}

function sudo_in_jail {
	local schroot_args="$1"
	shift
	local cmd="$@"

	if [ -n "$cmd" ]; then
		log-info "chroot exec: sudo $cmd"
	fi

	sudo schroot $schroot_args -- $cmd
	local retval=$?
	if [ $retval -ne 0 ]; then
		log-error "$cmd"
	fi
	return $retval
}

function jail:sudo {
	sudo_in_jail "-c $(jail:name)" "$@"
}

function jail:src:sudo {
	sudo_in_jail "-c source:$(jail:name)" "$@"
}

function jail:run() {
	sudo_in_jail "-u $USER -c $(jail:name)" "$@"
}

function jail:create() {
    _ian-sudo "mkdir -p /var/jails"
    _ian-sudo "debootstrap --arch=$JAIL_ARCH --variant=buildd --include=fakeroot,build-essential,debfoster sid $JAIL_DIR_TMP $MIRROR"
#    _ian-sudo "debootstrap --verbose --variant=buildd sid $JAIL_DIR_TMP $MIRROR"
	jail:add-ian-repo
	jail:add-sudoer
	sudo tar cf $(jail:tarball) -C $JAIL_DIR_TMP .
	log-ok "jail $(jail:name) created"
}

function jail:add-ian-repo() {
    local repo=$(mktemp)
    echo "deb http://babel.esi.uclm.es/arco sid main" > $repo
    sudo cp $repo $JAIL_DIR_TMP/etc/apt/sources.list.d/arco.list
}

function jail:add-sudoer() {
    local sudoers=$(mktemp)
    echo "$USER ALL=NOPASSWD: ALL" > $sudoers
    sudo mkdir -p $JAIL_DIR_TMP/etc/sudoers.d
    sudo cp $sudoers $JAIL_DIR_TMP/etc/sudoers.d/ian
}

function jail:install-ian() {
#    local key=$(mktemp)
#    wget -q -O $key http://babel.esi.uclm.es/arco/key.asc
#    jail:src:sudo apt-key add $key
	jail:src:sudo apt-key adv --keyserver pgp.mit.edu --recv-keys DCA26384
    jail:src:sudo apt-get -q update
    jail:src:sudo apt-get -q $DPKG_OPTS install -y ian
}

function jail:clean {
    jail:src:sudo apt-get clean
}

function jail:is-ok {
	log-info "jail checking..."

	if ! [ -e $(jail:tarball) ]; then
		return 1
	fi

	if ! jail:run "ls /usr/bin/ian"; then
		return 1
	fi

	# jail:run ian-help-reference > /dev/null
    # if [ $? != 0 ]; then
	# 	return 1
	# fi

	log-ok "jail seems to be ok"
}
