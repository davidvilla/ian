#!/bin/bash
# -*- coding:utf-8; tab-width:4; mode:shell-script -*-

source /usr/share/ian/shell-commodity.sh
#source bash/shell-commodity.sh

LANG=C
IAN_CONFIG=$HOME/.config/ian/config

if [ -e $IAN_CONFIG ]; then
	source  $IAN_CONFIG
fi

#-- common --

function _ian-rm {
    if ! sc-file-exists $1; then
		echo rm: missing $1
		return
	fi
	rm -fv $1
}


#-- doc --

function ian-help-reference {
    cat <<EOF
ian-summary         show package info
ian-new-release     add a new changelog entry
ian-clean           clean generated packaging files
ian-build           build all binary packages
ian-binary-contents show binary package content
ian-install         install (with sudo dpkg) all binary packages
ian-upload          upload package to configured debian repository
ian-remove          remove pacakge from configured debian repository
EOF
}

function ian-help-setup {
	cat <<EOF
New maintainer process
----------------------

- Define environment variables in your ~/.config/ian/config
  (run: ian-help-debvars-examples)

- Create a GPG key pair: gpg --gen-key)
- Get your key-ID: gpg --list-secret-keys
- Submit your GPG public key: gpg --send-keys

- Create a SSH key pair: ssh-keygen
- Copy SSH public key to repo server: ssh-copy-id \$(_ian-repo-path)

In the repository server
------------------------

- Log in as repo owner.
- Import GPG key: gpg --keyserver pgp.mit.edu --recv-key <key-ID>
- Add your key-ID in allowed package uploaders: \$(_ian-repo-path)/conf/uploaders

References
----------

- http://www.debian-administration.org/articles/286
- http://crysol.org/es/repo-debian-serio-basico

EOF
}

function ian-help-workflow {
	cat <<EOF
New package release
-------------------

- ian-new-release
- ian-clean
- ian-build
-- fix lintian bugs (and build again)
- ian-install
- ian-binary-contents
-- check success instalation and file location
- ian-upload
EOF
}

function ian-debvars-luser {
	local TMP=$(mktemp)
	local need_vars=0

	if ! sc-var-defined DEBFULLNAME; then
		echo "export DEBFULLNAME=$USERNAME" >> $TMP
		sc-log-warning "exporting placeholder DEBFULLNAME=$USERNAME"
		need_vars=1
	fi

	if ! sc-var-defined DEBEMAIL; then
		fakemail="$LOGNAME@$HOSTNAME"
		echo "export DEBEMAIL=\"$fakemail\"" >> $TMP
		sc-log-warning "exporting placeholder DEBEMAIL=$fakemail"
		need_vars=1
	fi

	if ! sc-var-defined DEBSIGN_KEYID; then
		fakeid="DEADBEE"
		echo "export DEBSIGN_KEYID=$fakeid" >> $TMP
		sc-log-warning "exporting placeholder DEBSIGN_KEYID=$fakeid"
		need_vars=1
	fi

	if ! sc-var-defined DEBREPO_URL; then
		fakepath="$USERNAME@your.server.net/path/to/repo"
		echo "export DEBREPO_URL=$fakepath" >> $TMP
		sc-log-warning "exporting placeholder DEBREPO_URL=$fakepath"
		need_vars=1
	fi

	if [[ $need_vars -eq 0 ]]; then
		echo "Your environment is already right. You are not a luser."
	else
		echo "run: 'cp $TMP $IAN_CONFIG', make your changes and try again"
	fi
}

function ian-debvars {
	echo "DEBFULLNAME:  " $DEBFULLNAME
	echo "DEBEMAIL:     " $DEBEMAIL
	echo "DEBSIGN_KEYID:" $DEBSIGN_KEYID
	echo "DEBREPO_URL:  " $DEBREPO_URL
}

function ian-help-debvars-examples {
	sc-log-info "Define variables bellow in your ~/.config/ian/config using your info:"
    cat <<EOF
export DEBFULLNAME="John Doe"
export DEBEMAIL=john.doe@email.com
export DEBSIGN_KEYID=D0FE7AFB  # man debsign
export DEBREPO_URL=john.doe@debian.repository.org/var/repo
EOF
}

function ian-summary {
    (
    _ian-assert-preconditions
    echo "source:             " $(_ian-source-name)
    echo "uptream:            " $(_ian-version-upstream)
    echo "version:            " $(_ian-version)
    echo "orig:               " $(_ian-orig-filename)
    echo "changes:            " $(_ian-changes-filename)

	if _ian-uses-uscan; then
	echo "watch:              " $(_ian-version-upstream-uscan)
	fi

	echo "binaries:           " $(_ian-binary-names)
    echo "pkg vcs:            " $(_ian-vcs)

	missing_deps=$(_ian-builddeps)
	if [ $? -ne 0 ]; then
	echo "missing build deps: " $missing_deps
	fi
    )
}

function _ian-vcs {
	# the <VCS-buildpackage> that the maintainer uses to manage de package
	if _ian-uses-svn; then
		echo "svn"
		return
	fi
	echo "none"
}

function _ian-version-upstream-uscan {
	local output=$(uscan --report --verbose 2> /dev/null)
	if [ $? -ne 0 ]; then
		echo "error: run \"uscan --verbose\" for details"
		return
	fi
	echo $output | grep "Newest" | cut -d"," -f1 | sed "s/site is /@/g" | cut -d@ -f2
}


#-- new release ------------------------------------------------------

function ian-new-release {
    (
    _ian-assert-preconditions
	dch -i
    )
}

function ian-new-release-date-version {
    (
    _ian-assert-preconditions
    local CHLOG=$(mktemp)
    echo $(_ian-source-name) \(0.$(date +%Y%m%d-1)\) unstable\; urgency=low > $CHLOG
    echo -e "\n  * New release\n\n -- \n" >> $CHLOG
    cat debian/changelog >> $CHLOG
    mv $CHLOG debian/changelog
    emacs +5:4 debian/changelog
    )
}


#-- build ------------------------------------------------------------

function ian-build {
    (
    _ian-assert-preconditions
	sc-assert ian-orig

	_ian-builddeps-assure
	sc-log-info "build"

    if _ian-uses-svn; then
		ian-build-svn
    else
		ian-build-standard
    fi

	sc-assert-files-exist $(_ian-binary-paths)
	sc-log-info "build [DONE]"
    )
}

function ian-build-standard {
    (
    _ian-assert-preconditions
    dpkg-buildpackage -uc -us

    changes=$(_ian-changes-path)
	sc-log-info "LINTIAN: $changes"
    lintian -I $changes
    )
}

# http://people.debian.org/~piotr/uscan-dl
function ian-build-svn {
    (
    _ian-assert-preconditions
	_ian-assert-uses-svn
	sc-assure-dir ../build-area
    svn-buildpackage -rfakeroot -us -uc --svn-ignore --svn-ignore-new --svn-lintian
    )
}

# function ian-build-with-cowbuilder {
#
# }

function _ian-build-dir {
    if _ian-uses-svn; then
		echo "../build-area"
		return
    fi

    echo ".."
}


#-- get/create orig --------------------------------------------------------

# build the upstream orig file from:
# - from-rule: regenerated by "debian/rules get-orig-source"
# - uscan
# - from "local" files
function ian-orig {
    (
    _ian-assert-preconditions
	if [ -f $(_ian-orig-path) ]; then
		sc-log-warning "orig: $(_ian-orig-path) already exists"
		return
	fi

	sc-log-warning "orig: $(_ian-orig-path) DOES NOT exists, getting/creating it"

	ian-clean

	sc-assure-dir $(_ian-orig-dir)

    if _ian-has-rule get-orig-source; then
		ian-orig-from-rule
    elif _ian-uses-uscan; then
		ian-orig-uscan
    else
		ian-orig-from-local
    fi
    sc-assert-files-exist $(_ian-orig-path)
    )
}

function ian-orig-from-rule {
	sc-log-info "orig-from-rule"
    make -f ./debian/rules get-orig-source
    mv -v $(_ian-orig-filename) $(_ian-orig-dir)/
}

function ian-orig-uscan {
	sc-log-info "orig-uscan"
    uscan --verbose --download-current-version --force-download --repack --destdir $(_ian-orig-dir)
}

function ian-orig-from-local {
    sc-log-info "orig-from-local"

    local orig_tmp=$(_ian-source-name)-$(_ian-version-upstream)
    mkdir -p $orig_tmp

    local EXCLUDE="--exclude=$orig_tmp --exclude=./debian --exclude=\*~ --exclude-vcs --exclude=\*.pyc --exclude .pc"

    tar $EXCLUDE -cf - . | ( cd $orig_tmp && tar xf - )
    tar -czf $(_ian-orig-path) $orig_tmp
    \rm -rf $orig_tmp
	sc-log-info "orig file created: $(_ian-orig-path)"
}

function _ian-orig-dir {
	if _ian-uses-svn; then
		echo ../tarballs
		return
	fi

	echo ..
}

function _ian-orig-filename {
    echo $(_ian-source-name)_$(_ian-version-upstream).orig.tar.gz
}

function _ian-orig-path {
	echo $(_ian-orig-dir)/$(_ian-orig-filename)
}

#-- clean ------------------------------------------------------------

function ian-clean {
    (
    _ian-assert-preconditions
	sc-log-info "clean"

    fakeroot make -f ./debian/rules clean

    if _ian-uses-svn; then
		ian-clean-svn
    else
		ian-clean-common
    fi

    if _ian-uses-uscan; then
		ian-clean-uscan
	fi

	return 0
    )
}

function ian-clean-common {
    (
    _ian-assert-preconditions
    sc-log-info "clean-common"

	rm -vf $(_ian-generated-paths)
    rm -vf $(_ian-binary-paths)
    )
}

function ian-clean-svn {
	(
    _ian-assert-preconditions
    sc-log-info "clean-svn"

    rm -vrf ../tarballs/* ../build-area/*
	)
}

function ian-clean-uscan {
	sc-log-info "clean-uscan"
	local nline=$(uscan --report --verbose | grep -n "^Newest version on remote" | cut -d":" -f 1)
	local nline=$(echo $nline - 1 | bc)
	local url=$(uscan --report --verbose | tail -n +$nline | head -n 1)
	local upstream_fname=$(basename $url)
	_ian-rm $(_ian-orig-dir)/$upstream_fname
}

#-- install ----------------------------------------------------------

function ian-install {
	(
	_ian-assert-preconditions
	sc-assert-files-exist $(_ian-binary-paths)

	sc-log-info "install"
    sc-assert "sudo dpkg -i $(_ian-binary-paths)"
	sc-log-info "install [DONE]"
	)
}

function ian-build-and-install {
	(
    sc-assert ian-build
	sc-assert ian-install
	)
}

function ian-clean-build-and-install {
	(
    ian-clean
	sc-assert ian-build-and-install
	)
}


#-- repo actions -----------------------------------------------------

function ian-upload {
    (
	local TMP=$(mktemp)
	sc-assert-files-exist $(_ian-changes-path) $(_ian-binary-paths)
    local changes=$(_ian-changes-path)
    debsign $changes
    dupload -f $changes 2> $TMP
	echo "--- out is $TMP"
	cat $TMP

#   dupload errors:
#   - file '$name.tar.gz' is needed for '$name.dsc', not yet registered in the pool and not found in '$changes'
#   -

# 	if grep "not yet registered in the pool" $TMP; then
# 		dpkg-genchanges -sa > $changes
# 		sc-assert "dupload -f $changes"
# 	fi
    )
}

function ian-remove {
    for pkg in $(_ian-binary-names) $(_ian-source-name); do
		ian-remove-package $pkg
    done
}

function ian-remove-package {
    ssh $(_ian-repo-account) "reprepro -V -b $(_ian-repo-path) remove sid $1"
}

function _ian-repo-account {
	(
    sc-assert-var-defined DEBREPO_URL
	echo ${DEBREPO_URL%%/*}
	)
}

function _ian-repo-path {
	(
    sc-assert-var-defined DEBREPO_URL
	echo /${DEBREPO_URL#*/}
	)
}


#-- expectations --

function _ian-assert-debian-dir {
    sc-assert-directory-exists ./debian
}

function _ian-debvars-missing {
	ian-help-debvars-examples
	exit 1
}

function _ian-assert-debvars {
	sc-set-trap _ian-debvars-missing
    sc-assert-var-defined DEBFULLNAME
    sc-assert-var-defined DEBEMAIL
    sc-assert-var-defined DEBSIGN_KEYID
    sc-assert-var-defined DEBREPO_URL
    sc-clear-trap
}

function _ian-assert-preconditions {
    _ian-assert-debian-dir
    _ian-assert-debvars
}

function _ian-assert-uses-svn {
	sc-assert _ian-uses-svn "" "This debian package is not managed with svn-buildpackage"
}

#-- identities --

function _ian-source-name {
    grep "^Source:" debian/control | cut -f2 -d:  | tr -d " "
#	dpkg-parsechangelog | sed -n 's/^Source: //p'
}

function _ian-binary-names {
    grep "^Package:" debian/control | cut -f2 -d:  | tr -d " "
}

function _ian-arch-binary {
	# $1: package name
	if [ $(_ian-arch-control $1) == "all" ]; then
		echo "all"
	else
		_ian-arch-build
	fi
}

function _ian-arch-build {
	dpkg-architecture | grep "DEB_BUILD_ARCH=" | head -n1 | cut -f2 -d=  | tr -d " "
}

function _ian-arch-control {
	# $1: package name
	local index=$(grep "Package:" debian/control | grep -n $1 | cut -f1 -d":"  | head -n1)
    grep "Architecture:" debian/control | tail -n +$index | head -n1 | cut -f2 -d:  | tr -d " "
}

function _ian-version {
    head -n 1 debian/changelog | cut -f2 -d " " | tr -d "()"
}

function _ian-version-upstream {
    echo $(_ian-version) | cut -f1 -d "-"
}


#-- file names --

function _ian-binary-filenames {
    for pkg in $(_ian-binary-names); do
	    echo ${pkg}_$(_ian-version)_$(_ian-arch-binary $pkg).deb
    done
}

function _ian-binary-paths {
    local build_path=".."
    if _ian-uses-svn; then
		build_path="../build-area"
    fi

    for fname in $(_ian-binary-filenames); do
		echo $build_path/$fname
    done
}

function _ian-changes-filename {
    echo $(_ian-source-name)_$(_ian-version)_$(_ian-arch-build).changes
}

function _ian-changes-path {
    echo $(_ian-build-dir)/$(_ian-changes-filename)
}

function _ian-dsc-filename {
    echo $(_ian-source-name)_$(_ian-version).dsc
}

function _ian-dsc-path {
    echo $(_ian-build-dir)/$(_ian-dsc-filename)
}

function _ian-generated-filenames {
    _ian-orig-filename
    _ian-changes-filename
    _ian-dsc-filename
    local deb_prefix=$(_ian-source-name)_$(_ian-version)
    echo $deb_prefix.debian.tar.gz
    echo $deb_prefix.diff.gz
	echo $deb_prefix.upload
}

function _ian-generated-paths {
	for fname in $(_ian-generated-filenames); do
		echo $(_ian-build-dir)/$fname;
	done
}


#-- utilities --

function _ian-uses-svn {
    (svn pl debian | grep mergeWithUpstream) &> /dev/null
}

function _ian-uses-uscan {
	grep -v ".*#" debian/watch &> /dev/null
}

function _ian-has-rule {
	grep -qs "^$1:" debian/rules
}

function ian-binary-contents {
    (
    _ian-assert-preconditions
	debc $(_ian-changes-path)
    )
}

function ian-py-version-to-setup {
	local version=$(_ian-version-upstream)
	sed -i -e "s/\( *version *= *\)'[0-9\.]\+'/\1'$version'/g" setup.py
	sc-log-info "setting version to $version"
}

function _ian-builddeps {
    dpkg-checkbuilddeps 2>&1 | cut -f3 -d":"| sed 's/)//g' | sed 's/ (//g' | sed 's/= /=/g'
	return ${PIPESTATUS[0]}
}

function _ian-builddeps-assure {
	local deps=$(_ian-builddeps)
	sc-log-info "installing build deps: $deps"

	if [ "$deps" ]; then
		sudo mk-build-deps --tool "apt-get -y" --install --remove debian/control
	fi
}


#-- multiarch support ------------------------------------------------

JAIL_CONFIG=/etc/schroot/chroot.d/ian
JAIL_DCONFIG=/etc/schroot/ian
JAIL_DIR=/var/jails/ian
JAIL_NAME=sid-386
USER_FSTAB=$HOME/.config/ian/fstab

function _ian-schroot-setup() {
	local JAIL_FSTAB=$JAIL_DCONFIG/fstab

	local config=$(mktemp)

    cat <<EOF > $config
[$JAIL_NAME]
description=Debian testing 32 bits
directory=$JAIL_DIR
type=directory
personality=linux32
setup.fstab=ian/fstab
EOF

	sudo mv $config $JAIL_CONFIG
	sudo chown root.root $JAIL_CONFIG

    sudo mkdir -p $JAIL_DCONFIG

	local fstab=$(mktemp)
    cat <<EOF > $fstab
/proc           /proc           none    rw,bind         0       0
/sys            /sys            none    rw,bind         0       0
/dev            /dev            none    rw,bind         0       0
/dev/pts        /dev/pts        none    rw,bind         0       0
/home           /home           none    rw,bind         0       0
/tmp            /tmp            none    rw,bind         0       0
EOF

	sudo bash -c "mv $fstab $JAIL_FSTAB"

    if [ -e $USER_FSTAB ]; then
		sudo cat $USER_FSTAB >> $JAIL_FSTAB
    fi
}

function _ian-jail-create() {
    sudo mkdir -p /var/jails
    sudo debootstrap --arch=i386 sid $JAIL_DIR http://ftp.debian.org/debian
}

function _ian-chroot-sudo() {
    sudo schroot -c $JAIL_NAME -- $@
}

function _ian-chroot-run() {
    sudo schroot -u $USER -c $JAIL_NAME -- $@
}

function _ian-jail-setup() {
	local repo=$(mktemp)
	echo "deb http://babel.esi.uclm.es/arco sid main" > $repo
    sudo cp $repo $JAIL_DIR/etc/apt/sources.list.d/arco.list

	local sudoers=$(mktemp)
	echo "$USER ALL=NOPASSWD: ALL" > $sudoers
	sudo cp $sudoers $JAIL_DIR/etc/sudoers.d/ian

	local key=$(mktemp)
 	wget -O $key http://babel.esi.uclm.es/arco/key.asc
    _ian-chroot-sudo apt-key add $key
    _ian-chroot-sudo apt-get update
    _ian-chroot-sudo apt-get install -y ian
}

function _ian-jail-destroy() {
	sudo rm -f $JAIL_CONFIG
	sudo rm -f $JAIL_DCONFIG/*
	if ! sc-file-exists $JAIL_DCONFIG; then
		sudo rmdir
	fi

    if ! [ -d $JAIL_DIR ]; then
		return
    fi

    local OLD=$JAIL_DIR-discarded-$(uuidgen)
    sc-log-warning "old jail was moved to $OLD"
	if sc-file-exists $JAIL_DIR; then
       sudo mv $JAIL_DIR $OLD
	fi
}

function ian-386-upgrade() {
	_ian-chroot-sudo apt-key update
	_ian-chroot-sudo apt-key upgrade
}

function ian-386() {
	if [ -z "$@" ]; then
		sc-log-error "usage: ian-386 <ian-command>"
		return
	fi

    sc-log-info "Running $@ in the jail $JAIL_NAME"

    _ian-chroot-run ian-help-reference > /dev/null
    if [ $? != 0 ]; then
		_ian-jail-destroy

		sc-log-warning "jail $JAIL_NAME is broken, rebuilding..."
		_ian-jail-create
		_ian-schroot-setup
		_ian-jail-setup
	fi
    _ian-chroot-run $@
}


eval $(basename $0) $@
