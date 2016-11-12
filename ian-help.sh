# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

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

		_print-usage-details "ian-map" "$cmd"
		return
    fi

    _help-command-summary
}

function _help-command-summary() {
    echo "usage: ian <cmd>"

    echo -e "\nCommands:"
    _print-command-synopsis "ian-map"

    # echo -e "\nCombos:"
    # print_docstrings "^\##:combo:"
}

function _print-command-synopsis {
    local map="$1"
    for cmd in $(get-command-list "$map"); do
	printf "  \033[1m%-24s\033[0m" $cmd
	local code=$(_get-command-code "$map" "$cmd")
	_print-usage $code
    done
}

# main
function unknown-command() {
    log-error "unknown command: '$1'\n"
    _help-command-summary
    exit 1
}

function _command-map {
    local map="$1"
    grep "$map" $IAN_ROOT/ian.sh | grep "^##" | sort -n | awk -F":" '{printf "%s:%s:\n", $3, $4}'
}

# main
# FIXME: w/o args should return all commands
function get-command-list() {
    local map="$1"
    grep "$map" $IAN_ROOT/ian.sh | grep "^##" | sort -n | cut -d: -f4
}

function _get-command-code {
    local map="$1"
    local cmd="$2"
    _command-map "$map" | grep ":$cmd:" | cut -d: -f1
}


function _print-usage {
    local code="$1"
    grep -h "^##:$code:cmd:" $IAN_ROOT/ian-*.sh | cut -d: -f4
}

function _print-usage-details() {
    local map="$1"
    local cmd="$2"
    local code=$(_get-command-code "$map" "$cmd")

    local usage=$(grep -h "^##:$code:usage:" $IAN_ROOT/ian-*.sh | cut -d: -f4 | tr ';' ':')
    local usage_lines=$(echo "$usage" | wc -l)

    if [[ -z "$usage" ]]; then
	printf "ian $cmd\n\n"
	_print-usage "$code"
	return
    fi

    echo "$usage" | head -n 1
    echo
    _print-usage "$code"

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

function ian-help-debvars-examples {
	log-info "define variables bellow in your '~/.config/ian/config' using your info:"
    cat <<EOF
DEBFULLNAME="John Doe"
DEBEMAIL=john.doe@email.com
DEBSIGN_KEYID=D0FE7AFB  # man debsign
DEBREPO_URL=john.doe@debian.repository.org/var/repo
EOF
}
