#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

JAIL_CONFIG=/etc/schroot/chroot.d/ian
JAIL_DCONFIG=/etc/schroot/ian
JAIL_DIR_TMP=$(mktemp -d)
JAIL_DIR=/var/jails
USER_FSTAB=$HOME/.config/ian/fstab
MIRROR=${DEBIAN_MIRROR:-http://ftp.debian.org}/debian

DPKG_OPTS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew"

function _jail-name {
    echo sid-$JAIL_ARCH-ian
}

function _jail-tarball {
	echo $JAIL_DIR/$(_jail-name).tar
}

function _ian-schroot-setup() {
    local JAIL_FSTAB=$JAIL_DCONFIG/fstab

    if [ -e $USER_FSTAB ]; then
		sudo cat $USER_FSTAB >> $JAIL_FSTAB
    fi
}

function _ian-chroot-sudo() {
    params="$@"
	if [ -n "$params" ]; then
		sc-log-info "ian: chroot exec: sudo $params"
	fi
    sudo schroot -c $(_jail-name) -- $params
}

function _ian-chroot-src-sudo {
    params="$@"
    sc-log-info "ian: chroot exec: sudo $params"
    sudo schroot -c source:$(_jail-name) -- $params
}

function _ian-chroot-run() {
    params="$@"
	if [ -n "$params" ]; then
		sc-log-info "ian: chroot exec: $params"
	fi
    sudo schroot -u $USER -c $(_jail-name) -- $params
}

function _jail-create() {
    _ian-sudo "mkdir -p /var/jails"
    _ian-sudo "debootstrap --arch=$JAIL_ARCH --variant=buildd --include=fakeroot,build-essential,debfoster sid $JAIL_DIR_TMP $MIRROR"
#    _ian-sudo "debootstrap --verbose --variant=buildd sid $JAIL_DIR_TMP $MIRROR"
	_jail-add-ian-repo
	_jail-add-sudoer
	sudo tar cf $(_jail-tarball) -C $JAIL_DIR_TMP .
	sc-log-ok "jail $(_jail-name) created"
}

function _jail-add-ian-repo() {
    local repo=$(mktemp)
    echo "deb http://babel.esi.uclm.es/arco sid main" > $repo
    sudo cp $repo $JAIL_DIR_TMP/etc/apt/sources.list.d/arco.list
}

function _jail-add-sudoer() {
    local sudoers=$(mktemp)
    echo "$USER ALL=NOPASSWD: ALL" > $sudoers
    sudo mkdir -p $JAIL_DIR_TMP/etc/sudoers.d
    sudo cp $sudoers $JAIL_DIR_TMP/etc/sudoers.d/ian
}

function _jail-install-ian() {
#    local key=$(mktemp)
#    wget -q -O $key http://babel.esi.uclm.es/arco/key.asc
#    _ian-chroot-src-sudo apt-key add $key
	_ian-chroot-src-sudo apt-key adv --keyserver pgp.mit.edu --recv-keys DCA26384
    _ian-chroot-src-sudo apt-get -q update
    _ian-chroot-src-sudo apt-get -q $DPKG_OPTS install -y ian
}

function _jail-clean {
    _ian-chroot-src-sudo apt-get clean
}

function ian-jail-destroy() {
    export JAIL_ARCH=i386

    if ! sc-file-exists $(_jail-tarball); then
		sc-log-warning "ian: jail $(_jail-name) does NOT exists"
		return
	fi

    local OLD=$(_jail-tarball)-$(uuidgen)
	_ian-sudo "mv $(_jail-tarball) $OLD"
    sc-log-warning "ian: old jail was moved to $OLD"
    sc-log-ok "ian: jail destroyed"
}

function jail-upgrade() {
    _ian-chroot-sudo apt-get update
    _ian-chroot-sudo apt-get upgrade
 }

function ian-386() {
    export JAIL_ARCH=i386
    _ian-schroot $@
}

function _jail-is-ok {
	sc-log-info "ian: jail checking..."

	if ! [ -e $(_jail-tarball) ]; then
		return 1
	fi

	_ian-chroot-run ian-help-reference > /dev/null
    if [ $? != 0 ]; then
		return 1
	fi

	sc-log-ok "ian: jail ok"
}

function _ian-schroot() {
    # if [ -z "$@" ]; then
	# 	sc-log-error "usage: ian-$JAIL_ARCH <ian-command>"
	# 	return
    # fi

    sc-log-info "ian: running \"$@\" in the jail \"$(_jail-name)\""

    if ! _jail-is-ok; then
		ian-jail-destroy

		sc-log-warning "ian: jail $(_jail-name) is broken or missing, rebuilding..."
		_jail-create
		_ian-schroot-setup
		sync
		_jail-install-ian
		_jail-clean
    fi
    _ian-chroot-run $@
}
