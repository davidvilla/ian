# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

function cmd:completions {
    assert-no-more-args
    get-command-list
}

function cmd:help {
##:help:cmd:show this help
##:help:usage:ian help [command]

    local cmd="${__args__[0]}"

    if ! [[ -z $cmd ]]; then
		if ! get-command-list | grep -qx -- "$cmd"; then
			unknown-command "$cmd"
		fi

		_print-usage-details "$cmd"
		return
    fi

    _help-command-summary
}

function _help-command-summary() {
    echo "usage: ian <cmd>"

    echo -e "\nCommands:"
    _print-command-synopsis

    echo -e "\nrun 'ian help <cmd>' or 'ian <cmd> -h' for details."
}

# command table: '##:ian-map:<cmd>' lines in ian.sh, in display order
# command docs: '##:<cmd>:cmd:<description>' and '##:<cmd>:usage:<line>' in ian-*.sh

function _print-command-synopsis {
    awk -F: '
	FNR == NR { if (/^##:ian-map:/) cmds[++n] = $3; next }
	/^##:[^:]+:cmd:/ { desc[$2] = $4 }
	END { for (i = 1; i <= n; i++) printf "  \033[1m%-24s\033[0m%s\n", cmds[i], desc[cmds[i]] }
	' $IAN_ROOT/ian.sh $IAN_ROOT/ian-*.sh
}

# main
function unknown-command() {
    log-error "unknown command: '$1'\n"
    _help-command-summary
    exit 1
}

# main
function get-command-list() {
    awk -F: '/^##:ian-map:/ { print $3 }' $IAN_ROOT/ian.sh
}

function _print-usage-details() {
    local cmd="$1"

    awk -F: -v cmd="$cmd" '
	$1 == "##" && $2 == cmd && $3 == "cmd" { desc = $4 }
	$1 == "##" && $2 == cmd && $3 == "usage" { gsub(";", ":", $4); usage[++n] = $4 }
	END {
		if (n == 0) { printf "ian %s\n\n%s\n", cmd, desc; exit }
		printf "%s\n\n%s\n", usage[1], desc
		if (n < 2) exit
		printf "\noptions:\n\n"
		for (i = 2; i <= n; i++) print usage[i]
	}
	' $IAN_ROOT/ian-*.sh
}

function cmd:version {
    dpkg -l ian | grep "ian" | grep "^ii" | awk '{print $3}'
}

#FIXME
function ian-help-setup {
    cat <<EOF
New maintainer process
----------------------

- Define environment variables in your '~/.config/ian'
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
	log-info "define variables bellow in your '~/.config/ian' with your info:"
    cat <<EOF
DEBFULLNAME="John Doe"
DEBEMAIL=john.doe@email.com
DEBSIGN_KEYID=D0FE7AFB  # man debsign
DEBREPO_URL=john.doe@debian.repository.org/var/repo
EOF
}

function cmd:config {
##:config:cmd:show found environment variables
##:config:usage:ian config
	ian-run debvars
}
