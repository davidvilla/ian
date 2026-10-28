# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- hooks ------------------------------------------------------------

# Hooks are shell functions the user defines in ~/.config/ian or in the project's .ian file, which ian runs around
# each of its commands ("run-cmd"). Every command has the same four:
#
#   ian-<cmd>-pre-hook     before the command
#   ian-<cmd>-post-hook    after it, whatever it did
#   ian-<cmd>-ok-hook      after "post", only when the command succeeded
#   ian-<cmd>-fail-hook    after "post", only when it failed
#
# They also run when a command is run by another one: "ian build" runs those of "orig", which runs those of
# "clean", and, with "-i", those of "install". A hook cannot stop the command: its exit code is ignored.
# IAN_DISABLE_HOOKS disables all of them.

# The commands that only show information have no hooks: nothing happens in them for a hook to react to. The last
# two are the other names of "ls" and "config".
IAN_HOOKLESS_COMMANDS="help name summary config binary-contents pool-ls ls list-products debvars"

# The hooks of previous versions of ian, each with the hook that replaces it. A deprecated hook still runs, in the
# place of its replacement and warning about it; when both are defined, only the replacement runs.
IAN_DEPRECATED_HOOKS="
ian-clean-hook:ian-clean-post-hook
ian-release-hook:ian-release-post-hook
ian-build-hook:ian-build-post-hook
ian-build-start-hook:ian-build-pre-hook
ian-build-end-hook:ian-build-ok-hook
ian-install-hook:ian-install-post-hook
ian-upload-start-hook:ian-upload-pre-hook
ian-upload-end-hook:ian-upload-ok-hook
ian-remove-hook:ian-remove-post-hook
"

# run a command (its name, without the "cmd:" prefix) with its hooks, returning what the command returned
function run-cmd {
	local cmd="$1"
	shift

	if _hookless-command $cmd; then
		cmd:$cmd "$@"
		return $?
	fi

	run-hook $cmd pre

	# in a subshell: an "exit" of the command (a failed assertion) must not skip the hooks below
	local rcode=0
	( cmd:$cmd "$@" ) || rcode=$?

	run-hook $cmd post

	if [ $rcode -eq 0 ]; then
		run-hook $cmd ok
	else
		run-hook $cmd fail
	fi

	return $rcode
}

function _hookless-command {
	[[ " $IAN_HOOKLESS_COMMANDS " == *" $1 "* ]]
}

# run the hook of a command for one stage: pre, post, ok or fail
function run-hook {
	local hook="ian-$1-$2-hook"
	local old=

	if sc-var-defined IAN_DISABLE_HOOKS; then
		return 0
	fi

	if sc-function-exists $hook; then
		for old in $(_deprecated-hooks $hook); do
			if sc-function-exists $old; then
				log-warning "hook '$old' DISCARDED because '$hook' is defined. Remove it"
			fi
		done

		_exec-hook $hook
		return 0
	fi

	for old in $(_deprecated-hooks $hook); do
		if sc-function-exists $old; then
			(>&2 deprecation "hook '$old' is DEPRECATED. Rename it as '$hook'")
			_exec-hook $old
		fi
	done
}

# the deprecated hooks a hook replaces
function _deprecated-hooks {
	echo "$IAN_DEPRECATED_HOOKS" | grep ":$1\$" | cut -d: -f1
}

# in a subshell and in the package root, where the commands run: a hook that changes directory or exits affects
# neither ian nor the hooks that follow
function _exec-hook {
	log-info "exec $1"

	(
	local root=$(find_dir_in_ancestors "$(pwd)" debian)
	if [ -n "$root" ]; then
		cd "$root"
	fi

	ian-run $1
	)
}
