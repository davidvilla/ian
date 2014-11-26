#!/bin/bash
# -*- coding:utf-8; tab-width:4; mode:shell-script -*-

NATIVE_LANG="$LANG"
LANG=C
IAN_CONFIG=$HOME/.config/ian/config
JAIL_PKGS="debootstrap schroot uuid-runtime"

if [ -e $IAN_CONFIG ]; then
	source $IAN_CONFIG
fi

source /usr/share/ian/shell-commodity.sh
source /usr/share/ian/jail.sh


#-- common --

function log-info {
	sc-log-notify II "ian: $1"
}

function log-warning {
	sc-log-notify WW "ian: $1"
}

function log-error {
	sc-log-notify EE "ian: $1"
}

function log-fail {
	sc-log-notify FF "ian: $1"
}

function log-ok {
	sc-log-notify OK "ian: $1"
}

function _ian-rm {
    if ! sc-file-exists $1; then
		echo rm: missing $1
		return
	fi
	rm -fv $1
}


#-- doc --

function cmd:completions {
	grep_commands "^\##:doc:"
}

function cmd:help {
##:doc:000:help: show this help
	echo "usage: ian <cmd>"

	echo -e "\nCommands:"
	print_docstrings "^\##:doc:"

	if [ "X${JAIL_ARCH}X" != "XX" ]; then
		echo -e "\nJail commands:"
		print_docstrings "^##:jail:"
	fi

	echo -e "\nAliases:"
	print_docstrings "^\##:alias:"

#	echo "--"
#	grep "^function cmd:" $__file__
}

function grep_commands {
	grep "$1" $__file__ | sort -n | awk  -F ":" '{printf "%s\n", $4}'
}

function print_docstrings {
    grep "$1" $__file__ | sort -n | awk  -F ":" '{printf "  \033[1m%-23s\033[0m %s\n", $4, $5}'
}

#FIXME
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
- Copy SSH public key to repo server: ssh-copy-id \$(repo-path)

In the repository server
------------------------

- Log in as repo owner.
- Import GPG key: gpg --keyserver pgp.mit.edu --recv-key <key-ID>
- Add your key-ID in allowed package uploaders: \$(repo-path)/conf/uploaders

References
----------

- http://www.debian-administration.org/articles/286
- http://crysol.org/es/repo-debian-serio-basico

EOF
}

#FIXME
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
		echo "DEBFULLNAME=$USERNAME" >> $TMP
		log-warning "exporting placeholder DEBFULLNAME=$USERNAME"
		need_vars=1
	fi

	if ! sc-var-defined DEBEMAIL; then
		fakemail="$LOGNAME@$HOSTNAME"
		echo "DEBEMAIL=\"$fakemail\"" >> $TMP
		log-warning "exporting placeholder DEBEMAIL=$fakemail"
		need_vars=1
	fi

	if ! sc-var-defined DEBSIGN_KEYID; then
		fakeid="DEADBEE"
		echo "DEBSIGN_KEYID=$fakeid" >> $TMP
		log-warning "exporting placeholder DEBSIGN_KEYID=$fakeid"
		need_vars=1
	fi

	if ! sc-var-defined DEBREPO_URL; then
		fakepath="$USERNAME@your.server.net/path/to/repo"
		echo "DEBREPO_URL=$fakepath" >> $TMP
		log-warning "exporting placeholder DEBREPO_URL=$fakepath"
		need_vars=1
	fi

	if [[ $need_vars -eq 0 ]]; then
		echo "Your environment is already right. You are not a luser."
	else
		echo "run: 'cp $TMP $IAN_CONFIG', make your changes and try again"
	fi
}

#FIXME
function ian-debvars {
	echo "DEBFULLNAME:  " $DEBFULLNAME
	echo "DEBEMAIL:     " $DEBEMAIL
	echo "DEBSIGN_KEYID:" $DEBSIGN_KEYID
	echo "DEBREPO_URL:  " $DEBREPO_URL
}

#FIXME
function ian-help-debvars-examples {
	log-info "define variables bellow in your ~/.config/ian/config using your info:"
    cat <<EOF
DEBFULLNAME="John Doe"
DEBEMAIL=john.doe@email.com
DEBSIGN_KEYID=D0FE7AFB  # man debsign
DEBREPO_URL=john.doe@debian.repository.org/var/repo
EOF
}


function orig-methods {
	if has-rule get-orig-source; then
		methods[0]='from-rule'
	fi
	if uses-uscan; then
		methods[1]='uscan'
	fi
	if [ $(ls | wc -l) -gt 1 ]; then
		methods[2]='from-local'
	fi

	if [ ${#methods[@]} -eq 0 ]; then
		echo "none!"
		return
	fi

	echo "${methods[@]}"
}

function cmd:summary {
##:doc:010:summary: show package info
    (
    assert-preconditions
    echo "source:             " $(source-name)
    echo "uptream:            " $(version-upstream)
    echo "version:            " $(pkg-version)
    echo "orig:               " $(orig-path)
	echo "  methods:          " $(orig-methods)
    echo "changes:            " $(changes-path)

	if uses-uscan; then
	echo "watch:              " $(version-upstream-uscan)
	fi

	echo "binaries:           " $(binary-names)
    echo "pkg vcs:            " $(pkg-vcs)

	local missing_deps=$(builddeps)
	if [ $? -ne 0 ]; then
	echo "missing build deps: " $missing_deps
	fi
    )
}

function pkg-vcs {
	# the <VCS-buildpackage> that the maintainer uses to manage de package
	if uses-svn; then
		echo "svn"
		return
	fi
	echo "none"
}

function version-upstream-uscan {
	local -a outputs
	sc-call-out-err outputs uscan --report --verbose

	if [ $? -ne 0 ]; then
		log-warning "error: see ${outputs[2]}"
		return
	fi
	cat "${outputs[1]}" | grep "Newest" | cut -d"," -f1 | sed "s/site is /@/g" | cut -d@ -f2
	rm ${outputs[@]}
}


#-- new release ------------------------------------------------------

function cmd:new-release {
##:doc:020:new-release: add a new changelog entry
    (
    assert-preconditions
	dch -i
    )
}

function cmd:new-release-date {
##:doc:021:new-release-date: add a new package version based on date: 0.20010101
    (
    assert-preconditions
    local CHLOG=$(mktemp)
    echo $(source-name) \(0.$(date +%Y%m%d-1)\) unstable\; urgency=low > $CHLOG
    echo -e "\n  * New release\n\n -- \n" >> $CHLOG
    cat debian/changelog >> $CHLOG
    mv $CHLOG debian/changelog
    emacs +5:4 debian/changelog
    )
}


#-- build ------------------------------------------------------------

function cmd:build {
##:doc:040:build: build all binary packages
    (
    assert-preconditions
	sc-assert cmd:orig

	builddeps-assure
	log-info "build"

    if uses-svn; then
		build-svn
    else
		build-standard
    fi

	sc-assert-files-exist $(binary-paths)
	log-ok "build"
    )
}

function build-standard {
    (
    assert-preconditions
    dpkg-buildpackage -uc -us

    changes=$(changes-path)
	log-info "LINTIAN: $changes"
    lintian -I $changes
    )
}

# http://people.debian.org/~piotr/uscan-dl
function build-svn {
    (
    assert-preconditions
	assert-uses-svn
	sc-assure-dir ../build-area
    svn-buildpackage -rfakeroot -us -uc --svn-ignore --svn-ignore-new --svn-lintian
    )
}

# function ian-build-with-cowbuilder {
#
# }

function build-dir {
    if uses-svn; then
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
function cmd:orig {
##:doc:015:orig: generate or download .orig. file
    (
    assert-preconditions
	if [ -f $(orig-path) ]; then
		log-warning "orig $(orig-path) already exists"
		return
	fi

	log-warning "orig $(orig-path) DOES NOT exists, getting/creating it"

	cmd:clean

	sc-assure-dir $(orig-dir)

    if has-rule get-orig-source; then
		cmd:orig-from-rule
    elif uses-uscan; then
		cmd:orig-uscan
    else
		cmd:orig-from-local
    fi
    sc-assert-files-exist $(orig-path)
	log-ok "orig"
    )
}

function cmd:orig-from-rule {
##:doc:016:orig-from-rule: execute "get-orig-source" rule of debian/rules to get .orig. file
	log-info "orig-from-rule"
    make -f ./debian/rules get-orig-source
    mv -v $(orig-filename) $(orig-dir)/
}

function cmd:orig-uscan {
##:doc:016:orig-uscan: execute uscan to download the .orig. file
	log-info "orig-uscan"
    uscan --verbose --download-current-version --force-download --repack --rename --destdir $(orig-dir)
}

function cmd:orig-from-local {
##:doc:016:orig-from-local: create an .orig. file from current directory content
    log-info "orig-from-local"

    local orig_tmp=$(source-name)-$(version-upstream)
    mkdir -p $orig_tmp

    local EXCLUDE="--exclude=$orig_tmp --exclude=./debian --exclude=\*~ --exclude-vcs --exclude=\*.pyc --exclude .pc"

    tar $EXCLUDE -cf - . | ( cd $orig_tmp && tar xf - )
    tar czf $(orig-path) $orig_tmp
    \rm -rf $orig_tmp
	log-ok "orig file created: $(orig-path)"
}

function orig-dir {
	if uses-svn; then
		echo ../tarballs
		return
	fi

	echo ..
}

function orig-filename {
    echo $(source-name)_$(version-upstream).orig.tar.gz
}

function orig-path {
	echo $(orig-dir)/$(orig-filename)
}

#-- clean ------------------------------------------------------------

function cmd:clean {
##:doc:030:clean: clean generated packaging files and revert patches
    (
    assert-preconditions
	builddeps-assure

	log-info "clean"

    fakeroot make -f ./debian/rules clean

    if uses-svn; then
		clean-svn
    else
		clean-common
    fi

    if uses-uscan; then
		cmd:clean-uscan
	fi

	log-ok "clean"
	return 0
    )
}

function clean-common {
    (
    assert-preconditions
    log-info "clean-common"

	rm -vf $(generated-paths)
    rm -vf $(binary-paths)
    )
}

function clean-svn {
	(
    assert-preconditions
    log-info "clean-svn"

    rm -vrf ../tarballs/* ../build-area/*
	)
}

function cmd:clean-uscan {
##:doc:031:clean-uscan: clean uscan generated files
	log-info "clean-uscan"
	local nline=$(uscan --report --verbose | grep -n "^Newest version on remote" | cut -d":" -f 1)
	local nline=$(echo $nline - 1 | bc)
	local url=$(uscan --report --verbose | tail -n +$nline | head -n 1)
	local upstream_fname=$(basename $url)
	_ian-rm $(orig-dir)/$upstream_fname
}

#-- install ----------------------------------------------------------

function cmd:install {
##:doc:070:install: install (with sudo dpkg) all binary packages
	(
	assert-preconditions
	sc-assert-files-exist $(binary-paths)

	log-info "install"
	ian-sudo "dpkg -i $(binary-paths)"
	log-ok "install"
	notify-install
	)
}

function notify-install {
	if sc-function-exists ian-install-hook; then
		ian-install-hook
	fi
}

function cmd:build-and-install {
##:alias:010:build-and-install: run "ian build" + "ian install"
	(
    sc-assert cmd:build
	sc-assert cmd:install
	)
}

function cmd:clean-build-and-install {
##:alias:020:clean-build-and-install: run "ian clean" + "ian build" + "ian install"
	(
    sc-assert cmd:clean
	sc-assert cmd:build-and-install
	)
}


#-- repo actions -----------------------------------------------------

function cmd:upload {
##:doc:090:upload: sign and upload binary packages to configured package repository
    (
	sc-assert-files-exist ~/.gnupg/secring.gpg
	sc-assert-files-exist $(changes-path) $(binary-paths)

    local changes_path=$(changes-path)
    sc-assert-run "LANG=$NATIVE_LANG debsign $changes_path"

	local -a outputs
	sc-call-out-err outputs "dupload -f $changes_path"
	local rcode=$?

	# echo "dupload out:" $?
	# echo -e $(sc-bold "dupload stderr:")
	# echo -e "${outputs[2]}"
	# echo "not yet registered in the pool and not found in '$(changes-filename)'"
	# echo "grep" $(echo "${outputs[2]}" | grep "not yet registered in the pool and
# not found in '$(changes-filename)'")

	local NOT_YET_REGISTERED="not yet registered in the pool and not found in '$(changes-filename)'"
	local DSC_ALREADY_REGISTERED=".dsc\" is already registered with different checksums"
	local DEB_ALREADY_REGISTERED=".deb\" is already registered with different checksums"

	if [ $rcode -ne 0 ]; then
		if cat ${outputs[2]} | grep "$NOT_YET_REGISTERED"; then
			log-warning "missing $(orig-filename) in repository, fixing..."
			sc-assert-run "dpkg-genchanges -sa > $changes_path"
			sc-assert-run "debsign $changes_path"
			sc-assert-run "dupload -f $changes_path"
		elif cat ${outputs[2]} | grep "$DSC_ALREADY_REGISTERED"; then
			log-warning "$(dsc-filename) already in repository, fixing..."
			sc-assert-run "dpkg-genchanges -b > $changes_path"
			sc-assert-run "debsign $changes_path"
			sc-assert-run "dupload -f $changes_path"
		elif cat ${outputs[2]} | grep "$DEB_ALREADY_REGISTERED"; then
			sc-log-error "already uploaded! Create a new release and try again"
			return
		else
			log-fail "upload"
			return
		fi
	fi

	echo "dupload output:"
	cat "${outputs[1]}"
	rm ${outputs[@]}
	log-ok "upload"
    )
}

function cmd:remove {
##:doc:100:remove: remove package from configured package repository
    for pkg in $(binary-names) $(source-name); do
		remove-package $pkg
    done
}

function remove-package {
    ssh $(repo-account) "reprepro -V -b $(repo-path) remove sid $1"
}

function repo-account {
	(
    sc-assert-var-defined DEBREPO_URL
	echo ${DEBREPO_URL%%/*}
	)
}

function repo-path {
	(
    sc-assert-var-defined DEBREPO_URL
	echo /${DEBREPO_URL#*/}
	)
}


#-- expectations --

function assert-debian-dir {
    sc-assert-directory-exists ./debian
}

function debvars-missing {
	ian-help-debvars-examples
	exit 1
}

function assert-debvars {
	sc-set-trap debvars-missing
    sc-assert-var-defined DEBFULLNAME
    sc-assert-var-defined DEBEMAIL
    sc-assert-var-defined DEBSIGN_KEYID
    sc-assert-var-defined DEBREPO_URL
    sc-clear-trap
}

function assert-preconditions {
    assert-debian-dir
    assert-debvars
}

function assert-uses-svn {
	sc-assert uses-svn "" "This debian package is not managed with svn-buildpackage"
}

#-- identities --

function source-name {
    grep "^Source:" debian/control | cut -f2 -d:  | tr -d " "
#	dpkg-parsechangelog | sed -n 's/^Source: //p'
}

function binary-names {
    grep "^Package:" debian/control | cut -f2 -d:  | tr -d " "
}

function arch-binary {
	# $1: package name
	if [ $(arch-control $1) == "all" ]; then
		echo "all"
	else
		arch-build
	fi
}

function arch-build {
	dpkg-architecture | grep "DEB_BUILD_ARCH=" | head -n1 | cut -f2 -d=  | tr -d " "
}

function arch-control {
	# $1: package name
	local index=$(grep "Package:" debian/control | grep -n $1 | cut -f1 -d":"  | head -n1)
    grep "Architecture:" debian/control | tail -n +$index | head -n1 | cut -f2 -d:  | tr -d " "
}

function pkg-version {
    head -n 1 debian/changelog | cut -f2 -d " " | tr -d "()"
}

function version-upstream {
    echo $(pkg-version) | cut -f1 -d "-"
}


#-- file names --

function binary-filenames {
    for pkg in $(binary-names); do
	    echo ${pkg}_$(pkg-version)_$(arch-binary $pkg).deb
    done
}

function binary-paths {
    local build_path=".."
    if uses-svn; then
		build_path="../build-area"
    fi

    for fname in $(binary-filenames); do
		echo $build_path/$fname
    done
}

function changes-filename {
    echo $(source-name)_$(pkg-version)_$(arch-build).changes
}

function changes-path {
    echo $(build-dir)/$(changes-filename)
}

function dsc-filename {
    echo $(source-name)_$(pkg-version).dsc
}

function dsc-path {
    echo $(build-dir)/$(dsc-filename)
}

function generated-filenames {
    orig-filename
    changes-filename
    dsc-filename
    local deb_prefix=$(source-name)_$(pkg-version)
    echo $deb_prefix.debian.tar.gz
    echo $deb_prefix.diff.gz
	echo $deb_prefix.upload
}

function generated-paths {
	for fname in $(generated-filenames); do
		echo $(build-dir)/$fname;
	done
}


#-- utilities --

function uses-svn {
    (svn pl debian | grep mergeWithUpstream) &> /dev/null
}

function uses-uscan {
	grep -v ".*#" debian/watch &> /dev/null
}

function has-rule {
	grep -qs "^$1:" debian/rules
}

function cmd:binary-contents {
##:doc:060:binary-contents: show binary package file listings
    (
    assert-preconditions
	sc-assert-files-exist $(changes-path)
	debc $(changes-path)
    )
}

function cmd:py-version-to-setup {
	local version=$(version-upstream)
	sed -i -e "s/\( *version *= *\)'[0-9\.]\+'/\1'$version'/g" setup.py
	log-info "setting version to $version"
}

function builddeps {
    dpkg-checkbuilddeps 2>&1 | cut -f3 -d':'| sed 's/)//g' | sed 's/ (//g' | sed 's/= /=/g'
	return ${PIPESTATUS[0]}
}

function builddeps-assure {
	local deps=$(builddeps)
	if [ -z "$deps" ]; then
		return
	fi

	log-info "installing build deps: $deps"

	if [ -n "$deps" ]; then
		ian-sudo "mk-build-deps --tool \"apt-get -y\" --install --remove debian/control"
	fi

	local deps=$(builddeps)
	if [ -n "$deps" ]; then
	    ian-sudo "apt-get install $deps"
	fi

	local deps=$(builddeps)
	if [ -n "$deps" ]; then
		log-error "Unmet build dependencies: $deps"
		exit 1
	fi

	log-ok "build deps"
}

function ian-sudo() {
	sc-assert-run "sudo $*" "ian exec"
}

function ian-run() {
	sc-assert-run "$*" "ian exec"
}

#-- jail support --

function assure-jail-is-ok {
    if jail:is-ok; then
		return 0
	fi

	log-warning "rebuilding jail $(jail:name)..."
	cmd:jail-destroy

	jail:create
	jail:setup
	sync
	jail:install-ian
	jail:clean
}

function ian-jail {
    log-info "Running \"$@\" in the jail \"$(jail:name)\""

	sc-assure-deb-pkg-installed $JAIL_PKGS
	assure-jail-is-ok

	local jail_manag_cmds=(jail-upgrade jail-destroy login)
	case "${jail_manag_cmds[@]}" in  *"$1"*)
			main $*
			return
	esac

	log-ok "enter jail '$(jail:name)'\n---------------------------------------"
    jail:run ian $*
}

function cmd:login {
##:jail:000:login: login into the jail
	sc-log-info "login into $(jail:name)..."
	jail:run
}

function cmd:jail-upgrade {
##:jail:002:jail-upgrade: upgrade source jail
	sc-assert-var-defined JAIL_ARCH "this command must be applied on a jail"

    jail:sudo apt-get update
    jail:sudo apt-get upgrade
 }

function cmd:jail-destroy {
##:jail:003:jail-destroy: destroy jail files
	sc-assert-var-defined JAIL_ARCH "this command must be applied on a jail"

    if ! sc-file-exists $(jail:tarball); then
		log-warning "removing jail: file $(jail:name) does NOT exists"
		return
	fi

    local OLD=$(jail:tarball)-$(uuidgen)
	ian-sudo "mv $(jail:tarball) $OLD"
    log-warning "old jail was moved to $OLD"
    log-ok "jail destroyed"
}

#-- mirror --

function ian-mirror-create {
	debmirror --host=$MIRROR --root=debian --cleanup --nosource --ignore-missing-release --progress --ignore-release-gpg \
		--arch=i386,amd64 --dist=sid --method=http --section=main debian-root
}


function main {
	if [ $# -eq 0 ]; then
		cmd:help
		return 1
	fi

    local cmd=$1
    shift
    local params=$*

    # echo command: $cmd
    # echo params: $params
    # echo $__file__
	# echo -e "--"

    grep "^function cmd:" $__file__ | grep -w "cmd:$cmd" > /dev/null
    if [ $? -ne 0 ]; then
		log-error "invalid command: $cmd\n"
		cmd:help
		return 1
    fi

    eval cmd:$cmd $params
}

function ian {
#	echo "ian running at jail" $JAIL_ARCH
#	echo ian: $*
#	echo "--"
	main $*
}

function ian-386 {
	export JAIL_ARCH=i386
	ian-jail $*
}

__file__=$0
eval $(basename $0) $*
