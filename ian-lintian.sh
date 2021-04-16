# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

function run-lintian() {
    if ! command -v lintian 2> /dev/null; then
        log-warning "lintian is not available"
        return
    fi

    changes=$(changes-path)
    log-info "lintian $changes"
    ian-run "unbuffer lintian -I $changes"
}


function cmd:lintian-fix() {
##:140:cmd:try to automatically solve some lintian issues
    assert-no-more-args
    assert-preconditions
    sc-assert-files-exist $(changes-path)

    lintian_log=$(lintian -I $changes)

    _lintian-fix-debian-watch-file-is-missing
    _lintian-fix-binary-without-manpage
    _lintian-fix-out-of-date-standards-version

    log-info "tune and re-build"
}

function _lintian-fix-debian-watch-file-is-missing() {
    local tag="debian-watch-file-is-missing"
    if echo "$lintian_log" | grep $tag > /dev/null; then
	log-info "fixing $tag"
	cat <<EOF > ./debian/source/lintian-overrides
$(package) source: debian-watch-file-is-missing
EOF
    fi
}

function _lintian-fix-binary-without-manpage() {
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

function _update-standards-version() {
    local msg=$1

    log-info "fixing '$(cat $msg)'"
    local old=$(cat $msg | cut -d' ' -f5)
    local new=$(cat $msg | tr ')' ' ' | cut -d' ' -f8)
    sed -i -e "s/$old/$new/g" debian/control
    log-ok "standards version changed $old -> $new"
}

function _lintian-fix-out-of-date-standards-version() {
    local msg=$(mktemp)

    # FIXME: or
    if echo "$lintian_log" | grep "out-of-date-standards-version" > $msg; then
	_update-standards-version "$msg"
    fi

    if echo "$lintian_log" | grep "newer-standards-version" > $msg; then
	_update-standards-version "$msg"
    fi

    if echo "$lintian_log" | grep "ancient-standards-version" > $msg; then
	_update-standards-version "$msg"
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
