#!/bin/bash
# -*- coding:utf-8; tab-width:4; mode:shell-script -*-

#-- command table --

#- info -
##:ian-map:000:help
##:ian-map:010:summary
##:ian-map:060:binary-contents
##:ian-map:200:list-products

#- actions -
##:ian-map:015:orig
##:ian-map:016:orig-from-local
##:ian-map:017:orig-from-rule
##:ian-map:018:orig-uscan
##:ian-map:020:release
##:ian-map:021:release-date
##:ian-map:030:clean
##:ian-map:031:clean-uscan
##:ian-map:040:build
##:ian-map:070:install
##:ian-map:090:upload
##:ian-map:100:remove
##:ian-map:120:create
##:ian-map:140:lintian-fix

IAN_CONFIG=$HOME/.config/ian/config
IAN_THIS_CONFIG=./.ian
BUILDOPTIONS=${BUILDOPTIONS:-""}
TODAY=$(date +%Y%m%d)


NORMAL=$(tput sgr0)
BOLD=$(tput bold)
GREEN=$(tput setf 2)
RED=$(tput setf 4)
DIM=$(tput dim)
BLUE=$(tput setf 1)
GREY=$(tput setf 7)

OUT_SIGN=" |"
ERR_SIGN=">|"
CHECK_OUT_SIGN="$BLUE$OUT_SIGN$NORMAL"
CHECK_ERR_SIGN="$BLUE$ERR_SIGN$NORMAL"
ROOT_OUT_SIGN="$RED$OUT_SIGN$NORMAL"
ROOT_ERR_SIGN="$RED$ERR_SIGN$NORMAL"

if [ -e $IAN_CONFIG ]; then
	source $IAN_CONFIG
fi

if [ -e $IAN_THIS_CONFIG ]; then
	source $IAN_THIS_CONFIG
fi

IAN_ROOT="/usr/share/ian"
NATIVE_LANG="$LANG"
LANG=C

source $IAN_ROOT/shell-commodity.sh


#-- common --

function logger {
	echo ian
}

function log-info {
	sc-log-notify II "$(logger): $1"
}

function log-warning {
	sc-log-notify WW "$(logger): $1"
}

function log-error {
	sc-log-notify EE "$(logger): $1"
}

function log-fail {
	sc-log-notify FF "$(logger): $1"
}

function log-ok {
	sc-log-notify OK "$(logger): $1"
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
	assert-no-more-args
	get-command-list "ian-map"
}

function cmd:help {
##:000:cmd:show this help
##:000:usage:ian help [command]

	local cmd="${__args__[0]}"

	if ! [[ -z $cmd ]]; then
		if ! get-command-list "ian-map" | grep "$cmd" > /dev/null; then
			unknown-command "$cmd"
		fi

		print-usage-details "ian-map" "$cmd"
		return
	fi

	help-command-summary
}

function help-command-summary() {
	echo "usage: ian <cmd>"

	echo -e "\nCommands:"
	print-command-synopsis "ian-map"

	# echo -e "\nCombos:"
	# print_docstrings "^\##:combo:"
}

function unknown-command() {
	log-error "unknown command: '$1'\n"
	help-command-summary
	exit 1
}

function command-map {
	local map="$1"
	grep "$map" $__file__ | grep "^##" | sort -n | awk -F":" '{printf "%s:%s:\n", $3, $4}'
}

# FIXME: w/o args should return all commands
function get-command-list() {
	local map="$1"
	grep "$map" $__file__ | grep "^##" | sort -n | cut -d: -f4
}

function get-command-code {
	local map="$1"
	local cmd="$2"
	command-map "$map" | grep ":$cmd:" | cut -d: -f1
}

function print-command-synopsis {
	local map="$1"
	for cmd in $(get-command-list "$map"); do
		printf "  \033[1m%-24s\033[0m" $cmd
		local code=$(get-command-code "$map" "$cmd")
		print-usage $code
	done
}

function print-usage {
	local code="$1"
	grep "^##:$code:cmd:" $__file__ | cut -d: -f4
}

function print-usage-details() {
	local map="$1"
	local cmd="$2"
	local code=$(get-command-code "$map" "$cmd")

	local usage=$(grep "^##:$code:usage:" $__file__ | cut -d: -f4)
	local usage_lines=$(echo "$usage" | wc -l)

	if [[ -z "$usage" ]]; then
		printf "ian $cmd\n\n"
		print-usage "$code"
		return
	fi

	echo "$usage" | head -n 1
	echo
	print-usage "$code"

	if [ "$usage_lines" -lt 2 ]; then
		return
	fi

	printf "\noptions:\n\n"
	echo "$usage" | tail -n "$(($usage_lines-1))"
}

function cmd:version {
	dpkg -l ian | grep "ian" | grep "^ii" | awk '{print $3}'
}

#FIXME
function ian-help-setup {
	cat <<EOF
New maintainer process
----------------------

- Define environment variables in your '~/.config/ian/config'
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

- ian release
- ian clean
- ian build
-- fix lintian bugs (and build again)
- ian install
- ian binary-contents
-- check success instalation and file location
- ian upload
EOF
}

#FIXME: generate missing lines in ~/.config/ian/config
function cmd:debvars-luser {
	local TMP=$(mktemp)
	local need_vars=false

	if ! sc-var-defined DEBFULLNAME; then
		echo "DEBFULLNAME=$USERNAME" >> $TMP
		log-warning "exporting placeholder 'DEBFULLNAME=$USERNAME'"
		need_vars=true
	fi

	if ! sc-var-defined DEBEMAIL; then
		fakemail="$LOGNAME@$HOSTNAME"
		echo "DEBEMAIL=\"$fakemail\"" >> $TMP
		log-warning "exporting placeholder 'DEBEMAIL=$fakemail'"
		need_vars=true
	fi

	if ! sc-var-defined DEBSIGN_KEYID; then
		fakeid="DEADBEE"
		echo "DEBSIGN_KEYID=$fakeid" >> $TMP
		log-warning "exporting placeholder 'DEBSIGN_KEYID=$fakeid'"
		need_vars=true
	fi

	if ! sc-var-defined DEBREPO_URL; then
		fakepath="$USERNAME@your.server.net/path/to/repo"
		echo "DEBREPO_URL=$fakepath" >> $TMP
		log-warning "exporting placeholder 'DEBREPO_URL=$fakepath'"
		need_vars=true
	fi

	if [ "$need_vars" = false ]; then
		log-info "Your environment is already right. You don't seem a luser."
	else
		log-warning "run: 'cat $TMP >> $IAN_CONFIG', make your changes and retry."
	fi
}

function cmd:debvars {
	echo "DEBFULLNAME:  " $DEBFULLNAME
	echo "DEBEMAIL:     " $DEBEMAIL
	echo "DEBSIGN_KEYID:" $DEBSIGN_KEYID
	echo "DEBREPO_URL:  " $DEBREPO_URL
}

function ian-help-debvars-examples {
	log-info "define variables bellow in your '~/.config/ian/config' using your info:"
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
	if valid-watch-present; then
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
##:010:cmd:show package info

	assert-no-more-args

    (
    assert-preconditions
    echo "source:             " $(package)
    echo "upstream:           " $(upstream-version)
	if valid-watch-present; then
	echo "watch:              " $(upstream-version-uscan)
	fi
    echo "version:            " $(debian-version)
    echo "orig:               " $(orig-path)
	echo "- methods:          " $(orig-methods)
    echo "changes:            " $(changes-path)
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

function upstream-version-uscan {
	local -a outputs
	sc-call-out-err outputs uscan --report --verbose

	local stderr_nlines=$(wc -l ${outputs[2]} | cut -d' ' -f1)
	if [ $stderr_nlines -gt 0 ]; then
		log-warning "error: see stderr: ${outputs[2]} stdout: ${outputs[1]}"
		return
	fi

	cat "${outputs[1]}" | grep "Newest version" |  cut -d"," -f1 | sed "s/site is /@/g" | cut -d@ -f2
	rm ${outputs[@]}
}


#-- hooks ------------------------------------------------------------

function notify-clean {
	if sc-function-exists ian-clean-hook; then
		log-info "exec ian-clean-hook"
		ian-run ian-clean-hook
	fi
}

function notify-release {
	if sc-function-exists ian-release-hook; then
		log-info "exec ian-release-hook"
		ian-run ian-release-hook
	fi
}

function notify-build-start {
	if sc-function-exists ian-build-start-hook; then
		log-info "exec ian-build-start-hook"
		ian-run ian-build-start-hook
	fi
}

function notify-build-end {
	if sc-function-exists ian-build-end-hook; then
		log-info "exec ian-build-end-hook"
		ian-run ian-build-end-hook
	fi

	if sc-function-exists ian-build-hook; then
		log-info "exec ian-build-end-hook"
		ian-run ian-build-hook
	fi
}

function notify-install {
	if sc-function-exists ian-install-hook; then
		log-info "exec ian-install-hook"
		ian-run ian-install-hook
	fi
}

function notify-install {
	if sc-function-exists ian-upload-hook; then
		log-info "exec ian-upload-hook"
		ian-run ian-upload-hook
	fi
}


#-- release ------------------------------------------------------

function log-release {
	log-info "setting version to $(debian-version)"
}


function cmd:release {
##:020:cmd:add a new changelog entry
##:020:usage:ian release [-i] [-y] [-m release-message]
##:020:usage:  -i;      increment final version component (like 'dch -i')
##:020:usage:  -y;      do not ask for a release message
##:020:usage:  -m MSG;  release message for debian/changelog entry

	local quiet=false msg="New release" revision=false
	local OPTIND=1 OPTARG OPTION

	while getopts m:yi OPTION "${__args__[@]}"; do
		case $OPTION in
			m)
				msg="$OPTARG" ;;
			y)
				quiet=true ;;
			i)
				revision=true ;;
			\?)
				echo "invalid option: -$OPTARG"
				exit 1 ;;
			:)
				echo "option -$OPTARG requires an argument"
				exit 1 ;;
		esac
	done

	assert-no-more-args $OPTIND

	if [ "$revision" = true ]; then
		increment-revision
		return
	fi

	do-release-standard "$quiet" "$msg"
}

function do-release-standard {
	local quiet="$2"
	local msg="$3"

	local old_version=$(upstream-version)
	local version_but_last=$(upstream-version-but-last)
	local micro_version=$(micro-upsteam-version)

	((micro_version++))
	do-release "$version_but_last.$micro_version" 1 "$quiet" "$msg"
}

function cmd:release-date {
##:021:cmd:add a new package version based on date: 0.20010101
##:021:usage:ian release-date [-i] [-y] [-m release-message]
##:021:usage:  -i;      increment final version component (like 'dch -i')
##:021:usage:  -y;      do not ask for a release message
##:021:usage:  -m MSG;  release message for debian/changelog entry

	local quiet=false msg="New release" revision=false
	local OPTIND=1 OPTARG OPTION

	# FIXME DRY
	while getopts m:yi OPTION "${__args__[@]}"; do
		case $OPTION in
			m)
				msg="$OPTARG" ;;
			y)
				quiet=true ;;
			i)
				revision=true ;;
			\?)
				echo "invalid option: -$OPTARG"
				exit 1 ;;
			:)
				echo "option -$OPTARG requires an argument"
				exit 1 ;;
		esac
	done

	assert-no-more-args $OPTIND

	if [ "$revision" = true ]; then
		increment-revision
		return
	fi

	do-release-date "$quiet" "$msg"
}

function do-release-date {
	local quiet="$1"
	local msg="$2"

	local old_version=$(upstream-version)

	local major_version=$(major-upstream-version)
	local date_version=$TODAY
	local micro_version=$(micro-upsteam-version)

	local new_version=$major_version.$date_version
	if ! [ -z "$micro_version" ]; then
		new_version=$new_version.$micro_version
	fi

	if [ "$old_version" == "$new_version" ]; then
		((micro_version++))
		new_version=$major_version.$date_version.$micro_version
	fi

	do-release "$new_version" 1 $quiet $msg
}

function major-upstream-version {
	# 1.2.3 -> 1
	echo $(upstream-version) | cut -d'.' -f1
}

function upstream-version-but-last {
	# 1.2.3 -> 1.2
	local upstream_version=$(upstream-version)
	echo ${upstream_version%.*}
}

function micro-upsteam-version {
	# 1.2.3 -> 3
	echo $(upstream-version) | cut -d'.' -f3
}

function debian-revision {
	# 1.2.3-4 -> 4
	echo $(debian-version) | cut -d'-' -f2
}

function increment-revision {
	revision=$(debian-revision)
	((revision++))
	do-release $(upstream-version) "$revision" "$quiet" "$msg"
}

function do-release() {
	local version="$1"
	local revision="$2"
	local quiet="$3"
	local msg="$4"
    local CHLOG=$(mktemp)

	(
	assert-debvars
	sc-assert-directory-exists ./debian

	cat <<EOF > $CHLOG
$(package) ($version-$revision) unstable; urgency=low

  * $msg

 -- $DEBFULLNAME <$DEBEMAIL>  $(date -R)

EOF

	if sc-file-exists "debian/changelog"; then
		cat debian/changelog >> $CHLOG
	fi

    mv $CHLOG debian/changelog
	assert-debian-files
	log-release

	if [ "$quiet" = false ]; then
		log-info "Openning \$EDITOR ($EDITOR) to get user release comments"
		$EDITOR debian/changelog
	fi

	notify-release
    )
}

#-- build ------------------------------------------------------------

function cmd:build {
##:040:cmd:build all binary packages
##:040:usage:ian build [-b] [-c] [-f] [-i] [-m] [-s]
##:040:usage:  -b;  skip 'source' target. See 'dpkg-buildpackage -b'
##:040:usage:  -c;  run "ian clean" before "build"
##:040:usage:  -f;  force build
##:040:usage:  -i;  run "ian install" after "build"
##:040:usage:  -m;  merge ./debian with upstream .orig. bypassing directory contents
##:040:usage:  -s;  include full source. See 'dpkg-genchanges -sa'


	local clean=false build_binary=false foce=false install=false merge=false include_source=false
	local OPTIND=1 OPTARG OPTION

	while getopts :bcfims OPTION "${__args__[@]}"; do
		case $OPTION in
			b)
				build_binary=true ;;
			c)
				clean=true ;;
			f)
				force=true ;;
			i)
				install=true ;;
			m)
				merge=true ;;
			s)
				include_source=true ;;
			\?)
				echo "invalid option: -$OPTARG"
				exit 1 ;;
			:)
				echo "option -$OPTARG requires an argument"
				exit 1 ;;
		esac
	done

	assert-no-more-args $OPTIND


    (
    assert-preconditions

	if [ "$build_binary" = true ]; then
		BUILDOPTIONS="$BUILDOPTIONS -b"
	fi

	if [ "$clean" = true ]; then
		cmd:clean
	fi

	if [ "$include_source" = true ]; then
		BUILDOPTIONS="$BUILDOPTIONS -sa"
	fi

	sc-assert cmd:orig

	assure-user-is-uploader $force
	builddeps-assure
	log-info "build"

	notify-build-start
    if uses-svn; then
		build-svn
    elif [ "$merge" = true ]; then
		build-merging-upstream
	else
		build-standard
    fi

    changes=$(changes-path)
	log-info "lintian $changes"
    lintian -I $changes

	sc-assert-files-exist $(binary-paths)
	log-ok "build"
	notify-build-end

	if [ "$install" = true ]; then
		cmd:install
	fi
    )
}

function build-merging-upstream {
	local tmp_build_area=$(mktemp -d)
	local tmp_build_dir=$tmp_build_area/$(upstream-fullname)
	mkdir -p $tmp_build_dir

	log-info "merging with uptream in a temp build area: $tmp_build_area"
	tar --no-same-owner --no-same-permissions --extract --gzip --file $(orig-path) --directory $tmp_build_area/
	cp -r ./debian $tmp_build_dir/
	cp $(orig-path) $tmp_build_area/
	chmod -R u+r+w+X,g+r-w+X,o+r-w+X -- $tmp_build_dir
	(
	cd $tmp_build_dir
	build-standard
	)

	cp -v $tmp_build_area/$(package)_$(debian-version)* $(build-dir)
	for pkg in $(binary-names) $(dbgsym-names); do
		local fname="$tmp_build_area/${pkg}_$(debian-version)*.deb"
		if [ -e $fname ]; then
			cp -v $fname $(build-dir)
		fi
    done

	cp -v $tmp_build_dir/debian/files ./debian
}

function build-standard {
    (
    assert-preconditions
	local build_command="dpkg-buildpackage -uc -us $BUILDOPTIONS"
    check-run "$build_command"
    )
}

function build-svn {
    (
    assert-preconditions
	assert-uses-svn
#	sc-assure-dir ../build-area
	log-info "running svn-buildpackage"
    svn-buildpackage -rfakeroot -us -uc --svn-ignore --svn-ignore-new --svn-move --svn-noninteractive --svn-override origDir=..
#	clean-svn
    )
}

function cmd:lintian-fix() {
##:140:cmd:try to automatically solve lintian issues
	assert-no-more-args
	sc-assert-files-exist $(changes-path)

	lintian_log=$(lintian -I $changes)

	lintian-fix-debian-watch-file-is-missing
	lintian-fix-binary-without-manpage
	lintian-fix-out-of-date-standards-version

	log-info "tune and re-build"
}

function lintian-fix-debian-watch-file-is-missing() {
	local tag="debian-watch-file-is-missing"
	if echo "$lintian_log" | grep $tag > /dev/null; then
		log-info "fixing $tag"
		cat <<EOF > ./debian/source/lintian-overrides
$(package) source: debian-watch-file-is-missing
EOF
	fi
}

function lintian-fix-binary-without-manpage() {
	local tag="binary-without-manpage"
	local msg=$(mktemp)
	if echo "$lintian_log" | grep $tag > $msg; then
		cat $msg | while read line; do
			log-info "fixing '$line'"
			local cmd=$(basename $(echo $line | cut -d' ' -f4))
			create-placeholder-manpage "$cmd"
			log-ok "manpage '$cmd.rst' created"
		done
		# FIXME: add rules to debian/rules
		# FIXME: install manpages
	fi
}

function update-standards-version() {
	local msg=$1

	log-info "fixing '$(cat $msg)'"
	local old=$(cat $msg | cut -d' ' -f5)
	local new=$(cat $msg | tr ')' ' ' | cut -d' ' -f8)
	sed -i -e "s/$old/$new/g" debian/control
	log-ok "standards version changed $old -> $new"
}

function lintian-fix-out-of-date-standards-version() {
	local msg=$(mktemp)

	if echo "$lintian_log" | grep "out-of-date-standards-version" > $msg; then
		update-standards-version "$msg"
	fi

	if echo "$lintian_log" | grep "newer-standards-version" > $msg; then
		update-standards-version "$msg"
	fi

	if echo "$lintian_log" | grep "ancient-standards-version" > $msg; then
		update-standards-version "$msg"
	fi
}

function create-placeholder-manpage() {
	local bin="$1"
	local bin_len=${#bin}

	local simple_line=$(printf '%*s' "$bin_len" | tr ' ' "-")
	local double_line=$(printf '%*s' "$bin_len" | tr ' ' "=")

	cat <<EOF > "$bin.rst"
$double_line
$bin
$double_line

------------$simple_line
$bin description
------------$simple_line

:Author: $DEBFULLNAME
:date:   $(date +%Y-%m-%d)
:Manual section: 1

SYNOPSIS
========

\`\`$bin\`\` [options]

This manual page documents briefly the \`\`$bin\`\` command.

This manual page was written for the Debian(TM) distribution because
the original program does not have a manual page.

COPYRIGHT
=========

Copyright © $(date +%Y) $DEBFULLNAME

This manual page was written for the Debian system (and may be used by
others).

Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU General Public License, Version 2 or (at
your option) any later version published by the Free Software
Foundation.

On Debian systems, the complete text of the GNU General Public License
can be found in /usr/share/common-licenses/GPL.

EOF
}

# function ian-build-with-cowbuilder {
#
# }

function build-dir {
    # if uses-svn; then
	# 	echo "../build-area"
	# 	return
    # fi

    echo ".."
}


#-- get/create orig --------------------------------------------------------

# build the upstream orig file from:
# - from-rule: regenerated by "debian/rules get-orig-source"
# - uscan
# - from "local" files
function cmd:orig {
##:015:cmd:generate or download .orig. file

	assert-no-more-args

    (
    assert-preconditions
	if [ -f $(orig-path) ]; then
		log-warning "orig $(orig-path) is present"
		return
	fi

	log-warning "orig $(orig-path) DOES NOT exist, getting/creating it"

	cmd:clean

	sc-assure-dir $(orig-dir)
	log-info "orig"

    if has-rule get-orig-source; then
		cmd:orig-from-rule
    elif valid-watch-present; then
		cmd:orig-uscan
    else
		cmd:orig-from-local
    fi

    sc-assert-files-exist $(orig-path)
	log-ok "orig"
    )
}

function cmd:orig-from-rule {
##:017:cmd:execute "get-orig-source" rule of debian/rules to get .orig. file
	assert-no-more-args

    check-run "make -f ./debian/rules get-orig-source"
    mv -v $(orig-filename) $(orig-dir)/
}

# http://people.debian.org/~piotr/uscan-dl
function cmd:orig-uscan {
##:018:cmd:execute uscan to download the .orig. file
	assert-no-more-args

	assert-valid-watch
	log-info "orig-uscan"
    uscan --verbose --download-current-version --force-download --repack --rename --destdir $(orig-dir)
}

function cmd:orig-from-local {
##:016:cmd:create an .orig. file from current directory content
	assert-no-more-args

    log-info "orig-from-local"

    local orig_tmp=$(upstream-fullname)
    mkdir -p $orig_tmp

    local EXCLUDE="--exclude=$orig_tmp --exclude=./debian --exclude=\*~ --exclude-vcs --exclude=\*.pyc --exclude .pc"

    tar $EXCLUDE -cf - . | ( cd $orig_tmp && tar xf - )
    tar czf $(orig-path) $orig_tmp
    \rm -rf $orig_tmp
	log-ok "orig file created: $(orig-path)"
}

function orig-dir {
	# if uses-svn; then
	# 	echo ../tarballs
	# 	return
	# fi

	echo ..
}

function orig-filename {
    echo $(package)_$(upstream-version).orig.tar.gz
}

function orig-path {
	echo $(orig-dir)/$(orig-filename)
}

#-- clean ------------------------------------------------------------

function cmd:clean {
##:030:cmd:clean product files and revert patches
	assert-no-more-args

    (
    assert-preconditions
#	builddeps-assure

	log-info "clean"

    ian-run "fakeroot make -f ./debian/rules clean"

    # if uses-svn; then
	# 	clean-svn
	# fi
	clean-common

    if valid-watch-present; then
		cmd:clean-uscan
	fi

	log-ok "clean"
	notify-clean
	return 0
    )
}

function clean-common {
    (
    assert-preconditions
    log-info "clean-common"

	ian-run "rm -vf $(product-paths) $(binary-paths)"
    )
}

# function clean-svn {
# 	(
#     assert-preconditions
#     log-info "clean-svn: purging build area"
# 	rm -rf ../$(upstream-fullname) ../$(upstream-fullname).obsolete.*
# 	)
# }

function cmd:clean-uscan {
##:031:cmd:clean uscan related files
	assert-no-more-args

	log-info "clean-uscan"
	# local nline=$(uscan --report --verbose | grep -n "^Newest version on remote" | cut -d":" -f 1)
	# local nline=$(echo $nline - 1 | bc)
	# local url=$(uscan --report --verbose | tail -n +$nline | head -n 1)
	# local upstream_fname=$(basename $url)
	# _ian-rm $(orig-dir)/$upstream_fname
	rm -vf $(uscan-downloads-paths)
}

# FIXME: to test
function uscan-downloads-filenames {
    local nline=$(uscan --report --verbose | grep -n "Found the following matching hrefs" | cut -d":" -f 1)
    local nfirst=$(($nline+1))
    local nline=$(uscan --report --verbose | grep -n "version on remote site" | cut -d":" -f 1)
    local nlast=$(($nline-$nfirst))

    uscan --report --verbose  | tail -n +$nfirst | head -n $nlast | while read fname; do
		local path=$(echo "$fname" | cut -d"(" -f 1)
		echo ${path##*/}
    done
}

# FIXME: to test
function uscan-downloads-paths {
    for fname in $(uscan-downloads-filenames); do
		echo "$(orig-dir)/$fname";
    done
}


#-- install ----------------------------------------------------------

function cmd:install {
##:070:cmd:install (with sudo dpkg) all binary packages
	assert-no-more-args

	(
	assert-preconditions
	sc-assert-files-exist $(binary-paths)

	log-info "install"
	ian-sudo "dpkg -i $(binary-paths)"
	log-ok "install"
	notify-install
	)
}

function cmd:build-and-install {
##:combo:010:build-and-install: run "ian build" + "ian install"
	(
    sc-assert cmd:build
	sc-assert cmd:install
	)
}

function cmd:clean-build-and-install {
##:combo:020:clean-build-and-install: run "ian clean" + "ian build" + "ian install"
	(
    sc-assert cmd:clean
	sc-assert cmd:build-and-install
	)
}


#-- repo actions -----------------------------------------------------

# FIXME: use cmd:upload
function cmd:upload-all {
	for changes_path in $(postbuild-changes-filenames); do
		sc-assert-run "LANG=$NATIVE_LANG debsign $changes_path"
		sc-assert-run "dupload -f $changes_path"
	done
}

function cmd:upload {
##:090:cmd:sign and upload binary packages to configured package repository
	assert-no-more-args

	(
    local changes_path=$(changes-path)

	sc-assert-files-exist ~/.gnupg/secring.gpg
	sc-assert-files-exist $changes_path $(binary-paths)

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

	check-dupload-errors $rcode ${outputs[1]} ${outputs[2]}
	rm ${outputs[@]}

	if [ $rcode -eq 0 ]; then
		log-ok "upload"
	fi
    )
}

function check-dupload-errors {
	local rcode=$1
	local stdout="$2"
	local stderr="$3"

	if [ $rcode -eq 0 ]; then
		return
	fi

	local NOT_YET_REGISTERED="not yet registered in the pool and not found in '$(changes-filename)'"
	local DSC_ALREADY_REGISTERED=".dsc\" is already registered with different checksums"
	local DEB_ALREADY_REGISTERED=".deb\" is already registered with different checksums"
	local ORIG_ALREADY_REGISTERED=".orig.tar.gz\" is already registered with different checksums"

	if file-contains "$stderr" "$NOT_YET_REGISTERED"; then
		log-warning "missing $(orig-filename) in repository, fixing..."
		sc-assert-run "dpkg-genchanges -sa > $changes_path"
		cmd:upload
		return
	elif file-contains "$stderr" "$DSC_ALREADY_REGISTERED"; then
		log-warning "$(dsc-filename) already in repository, fixing..."
		sc-assert-run "dpkg-genchanges -b > $changes_path"
		cmd:upload
		return
	elif file-contains "$stderr" "$ORIG_ALREADY_REGISTERED"; then
		# FIXME: assure debian relase is > "-1"
		sc-log-error "orig already uploaded! Try 'ian build -b' and upload again"
	elif file-contains "$stderr" "$DEB_ALREADY_REGISTERED"; then
		sc-log-error "version already uploaded! Create a new release, and try again"
	fi

	ian-run "echo dupload output:"
	ian-run "cat $stderr"
	log-fail "upload"
	return 1
}

function file-contains {
	cat "$1" | grep "$2"
}

function sign-and-upload {
	sc-assert-run "LANG=$NATIVE_LANG debsign $(changes-path)"
	sc-assert-run "dupload -f $(changes-path)"
}


function do-reprepro {
	ssh $(repo-account) "reprepro -b $(repo-path) $*"
}

function cmd:remove {
##:100:cmd:remove package from configured package repository
##:100:usage:ian remove [i386|amd64]

	echo "Related files in '$DEBREPO_URL':"
	cmd:repo-list
	echo

	# read -r -p "Delete them? [y/N] " response
	# response=${response,,}    # tolower
	# if ! [[ $response =~ ^(yes|y)$ ]]; then
	# 	echo "(cancel)"
	# 	return
	# fi

	local arch=${__args__[0]:-""}

	for pkg in $(sc-filter-dups $(binary-names) $(dbgsym-names) $(package)); do
		remove-package "$pkg" "$arch"
    done
}

function remove-package {
	local package=$1
	local arch
	if [ ! -z $2 ]; then
		local arch="-A $2"
	fi

	do-reprepro $arch -V remove sid $package
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

function cmd:repo-list {
	# list related packages in the public repository

	for pkg in $(sc-filter-dups $(binary-names) $(dbgsym-names) $(package)); do
		do-reprepro list sid $pkg
	done
}

#-- assertions --

function assert-debian-files {
    sc-assert-directory-exists ./debian
	sc-assert-files-exist ./debian/control ./debian/rules ./debian/changelog
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
	if [ "$PRECONDITIONS_CHECKED" = true ]; then
		return 0
	fi

    assert-debvars
    assert-debian-files
	PRECONDITIONS_CHECKED=true
}

function assert-uses-svn {
	sc-assert uses-svn "" "This debian package is not managed with svn-buildpackage"
}

function assert-no-more-args {
	local end=$1
	local remaining

	if ! [[ -z $end ]]; then
		index=$(expr $end - 1)
		remaining="${__args__[@]:$index}"
	fi

	if ! [ -z "$remaining" ]; then
		log-error "unexpected arguments: $remaining"
		exit 1
	fi
}

function assure-user-is-uploader {
	local force=$1
	if grep -e "^Maintainer:" -e "^Uploaders:" debian/control | grep $DEBEMAIL > /dev/null; then
		log-ok "User '$DEBEMAIL' is an uploader."
		return 0
	fi

	log-error "User '$DEBEMAIL' is NOT an uploader!."

	if [ "$force" = true ]; then
		log-warning "build continues because 'force' is enabled."
		return 0
	fi

	log-error "Execute 'build -f' to overcome."
	exit 1
}


#-- identities --

function package {
	if sc-var-defined _PACKAGE; then
		echo $_PACKAGE
		return
	fi

	# this cmd requires a debian/changelog and it's executed when there is not a changelog yet
	# _PACKAGE=$(dpkg-parsechangelog -ldebian/changelog --show-field=Source)
	_PACKAGE=$(grep "^Source:" debian/control | cut -f2 -d:  | tr -d " ")
	package
}

function binary-names {
	# get binary package names from control
    grep "^Package:" debian/control | cut -f2 -d:  | tr -d " "
}

function dbgsym-names {
	binary-names | sed -e 's/$/-dbgsym/'
}

function arch-binary {
	# $1: package name
	if [ $(arch-control $1) == "all" ]; then
		echo "all"
	else
		host-arch
	fi
}

function host-arch {
	dpkg-architecture -qDEB_HOST_ARCH
}

function arch-control {
	# $1: package name
	local index=$(grep "Package:" debian/control | grep -n $1 | cut -f1 -d":"  | head -n1)
    grep "Architecture:" debian/control | tail -n +$index | head -n1 | cut -f2 -d:  | tr -d " "
}

function debian-version {
	if sc-var-defined _DEBIAN_VERSION; then
		echo $_DEBIAN_VERSION
		return
	fi

	sc-assert-files-exist debian/changelog
	# head -n 1 debian/changelog | cut -f2 -d " " | tr -d "()"
	_DEBIAN_VERSION=$(dpkg-parsechangelog -ldebian/changelog --show-field=Version)
	debian-version
}

function upstream-fullname {
	echo $(package)-$(upstream-version)
}

function upstream-version {
    echo $(debian-version) | cut -f1 -d "-"
}


#-- file names --

function binary-filenames {
    for pkg in $(binary-names); do
	    echo ${pkg}_$(debian-version)_$(arch-binary $pkg).deb
    done
}

function binary-paths {
    local build_path=".."
    for fname in $(binary-filenames); do
		echo $build_path/$fname
    done
}

function changes-filename {
    echo $(package)_$(debian-version)_$(host-arch).changes
}

function changes-path {
    echo $(build-dir)/$(changes-filename)
}

function postbuild-changes-filenames {
	ls -1 $(build-dir)/$(package)_$(debian-version)_*.changes
}

function dsc-filename {
    echo $(package)_$(debian-version).dsc
}

function dsc-path {
    echo $(build-dir)/$(dsc-filename)
}

function product-filenames {
    orig-filename
    changes-filename
    dsc-filename
    local deb_prefix=$(package)_$(debian-version)
    echo $deb_prefix.debian.tar.gz
    echo $deb_prefix.diff.gz
	echo $deb_prefix.upload
}

function product-paths {
	for fname in $(product-filenames); do
		echo $(build-dir)/$fname;
	done
}

function cmd:list-products {
##:200:cmd:list product files
	product-filenames
	binary-filenames
}


#-- utilities --

function uses-svn {
    (svn pl debian | grep mergeWithUpstream) &> /dev/null
}

function valid-watch-present {
	grep -v ".*#" debian/watch &> /dev/null
}

function assert-valid-watch {
	sc-assert valid-watch-present
}

function has-rule {
	grep -qs "^$1:" debian/rules
}

function cmd:binary-contents {
##:060:cmd:show binary package file listings
	assert-no-more-args

    (
    assert-preconditions
	sc-assert-files-exist $(changes-path)
	debc $(changes-path)
    )
}

function builddeps {
#    dpkg-checkbuilddeps 2>&1 | cut -f3 -d':'| sed 's/)//g' | sed 's/ (//g' | sed 's/= /=/g'
	dpkg-checkbuilddeps 2>&1 | cut -f3 -d':' | sed -e 's/([^][]*)//g'
	return ${PIPESTATUS[0]}
}

function builddeps-assure {
	local deps=$(builddeps)
	if [[ -z "$deps" ]]; then
		return
	fi

	log-info "installing build deps: $deps"

	if [ -n "$deps" ]; then
		ian-sudo "mk-build-deps --arch $(host-arch) --tool \"apt-get -y\" --install --remove debian/control"
	fi

	local deps=$(builddeps)
	if [ -n "$deps" ]; then
	    ian-sudo "apt-get install $deps"
	fi

	ian-sudo "apt-get install ian"
	local deps=$(builddeps)
	if [ -n "$deps" ]; then
		log-error "Unmet build dependencies: $deps"
		exit 1
	fi

	log-ok "build deps"
}


function indent {
	sed "s/^/    $1/g"
}
function indent2 {
	sed "s/^/    $1/g"
}

function ian-sudo {
	local command="$1"
	local msg="ian: $command"

	sc-log-info "$msg"
	if ! eval sudo $command 2> >(indent "$ROOT_ERR_SIGN") > >(indent "$ROOT_OUT_SIGN"); then
		sc-log-fail "$msg"
		exit 1
	fi
}

function check-run() {
	local command="$1"
	local msg="ian: $command"

	sc-log-info "$msg"
	if ! eval $command 2> >(indent "$CHECK_ERR_SIGN") > >(indent "$CHECK_OUT_SIGN"); then
		sc-log-fail "$msg"
		exit 1
	fi
}

function ian-run {
	eval $1 2> >(indent "$ERR_SIGN") > >(indent "$OUT_SIGN")
}

function cmd:create() {
##:120:cmd:create sample files for a new debian package
	assert-no-more-args

	local pkgname=$(basename $(pwd))

    (
	sc-assert sc-directory-absent ./debian "There is already a debian directory here"
	assert-debvars

	log-info "Check Makefile"
	if ! grep install Makefile > /dev/null; then
		sc-log-error "Your Makefile should have an 'install' rule. See created 'Makefile.example'"
		create-makefile
		exit 1
	fi

	mkdir -p debian/source
	echo "3.0 (quilt)" > ./debian/source/format
	echo 7 > ./debian/compat

	create-control "$pkgname"
	create-rules

	log-info "Creating initial release (date based version applied)"
	do-release "0.$TODAY" 1 true "Initial release"


	create-copyright

	log-warning "Customize ./debian files on your own."
	log-warning "See https://www.debian.org/doc/debian-policy/ and good luck!"
	log-ok "create"
	)
}

function create-makefile() {
	cat <<EOF > ./Makefile.example
# -*- mode: makefile-gmake; coding: utf-8 -*-
DESTDIR ?= ~

all:

install:
	FIXME: Install your scripts/binaries/libraries/...
	install -vd \$(DESTDIR)/usr/bin
	install -v -m 555 bin/your-script.sh \$(DESTDIR)/usr/bin/
EOF
}

function create-control() {
	local pkgname="$1"

	log-info "Creating debian/control"
	cat <<EOF > ./debian/control
Source: $pkgname
Section: utils
Priority: extra
Maintainer: $DEBFULLNAME <$DEBEMAIL>
Build-Depends: debhelper (>= 7.0.50~), quilt
Standards-Version: 3.9.8

Package: $pkgname
Architecture: all
Depends: \${misc:Depends}
Description: FIXME: Short description of the $pkgname package
 FIXME: long description about the basic features of the $pkgname package
EOF
}

function create-rules() {
	log-info "Creating debian/rules"
	cat <<EOF > ./debian/rules
#!/usr/bin/make -f

%:
	dh \$@ --with quilt
EOF
	chmod +x ./debian/rules
}

function create-copyright() {
	cat <<EOF > ./debian/copyright
Copyright $(date +%Y) $DEBFULLNAME <$DEBEMAIL>

License: GPL (/usr/share/common-licenses/GPL)
EOF
}

#-- vagrant boxes --

VAGRANT_FILES="Vagrantfile playbook.yml"

function cmd:vagrant-gen-files {
##:150:cmd:generate vagrant related files to boxed compilation
	assert-no-more-args

    (
    assert-preconditions

	for i in $VAGRANT_FILES; do
		cp $IAN_ROOT/$i .
	done

	log-ok "generated: $VAGRANT_FILES"
    )
}

function cmd:vagrant-build {
##:151:cmd:build package in the vagrant boxes
	assert-no-more-args

    (
    assert-preconditions
	sc-assert-files-exist $VAGRANT_FILES

	local ian_pwd=$(basename $(pwd))

	vagrant up --provision amd64
	vagrant ssh amd64 -c "cd /vagrant/$ian_pwd; ian build -m"
	vagrant up --provision i386
	vagrant ssh i386 -c "cd /vagrant/$ian_pwd; ian build -bm"
    )
}

function cmd:vagrant-clean {
##:151:cmd:remove vagrant related files
	assert-no-more-args

    (
    assert-preconditions

	vagrant destroy  -f
	rm $VAGRANT_FILES
    )
}

function main {
	if [[ -z "$__cmd__" ]]; then
		cmd:help
		return 1
	fi

    # echo command: $cmd
    # echo params: $params
    # echo $__file__
	# echo -e "--"

	# FIXME: use get-command-list
    grep "^function cmd:" $__file__ | grep -w "cmd:$__cmd__" > /dev/null
    if [ $? -ne 0 ]; then
		unknown-command "$__cmd__"
    fi

   eval cmd:$__cmd__
}

function ian {
#	echo ian: $*
#	echo "--"
	main
}

__file__=$0
__cmd__=$1
shift
__args__=("$@")

eval $(basename $__file__)
