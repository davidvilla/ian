#!/bin/bash
# -*- coding:utf-8; tab-width:4; mode:shell-script -*-

#-- command table --

#- info -
##:ian-map:help
##:ian-map:name
##:ian-map:summary
##:ian-map:config
##:ian-map:binary-contents
##:ian-map:ls

#- actions -
##:ian-map:orig
##:ian-map:release
##:ian-map:release-date
##:ian-map:clean
##:ian-map:clean-uscan
##:ian-map:build
##:ian-map:install
##:ian-map:upload
##:ian-map:ship
##:ian-map:remove
##:ian-map:pool-ls
##:ian-map:create
##:ian-map:lintian-fix

IAN_LEGACY_CONFIG=$HOME/.config/ian/config
IAN_CONFIG=$HOME/.config/ian
IAN_CWD_CONFIG=./.ian
BUILDOPTIONS=${BUILDOPTIONS:-""}
TODAY=$(date +%Y%m%d)

__file__=$0
__cmd__=$1
shift
__args__=("$@")

IAN_ROOT=$(readlink -f $(dirname $__file__))
NATIVE_LANG="$LANG"
LANG=C

source $IAN_ROOT/shell-commodity.sh

# colors, only if the terminal supports them
if sc-terminal-has-colors; then
	NORMAL=$(tput sgr0)
	BOLD=$(tput bold)
	GREEN=$(tput setf 2)
	RED=$(tput setf 4)
	DIM=$(tput dim)
	BLUE=$(tput setf 1)
	GREY=$(tput setf 7)
	SOFT_RED=$(tput setaf 1)
fi

OUT_SIGN="     |"
ERR_SIGN="    *|"
ERR_COLOR="$SOFT_RED"
CHECK_OUT_SIGN="$BLUE$OUT_SIGN$NORMAL"
CHECK_ERR_SIGN="$BLUE$ERR_SIGN$NORMAL"
SU_OUT_SIGN="$RED$OUT_SIGN$NORMAL"
SU_ERR_SIGN="$RED$ERR_SIGN$NORMAL"
# TERM_COLS=$(tput cols)

source $IAN_ROOT/ian-util.sh
source $IAN_ROOT/ian-config.sh
load-config

source $IAN_ROOT/ian-exec.sh
source $IAN_ROOT/ian-assertions.sh
source $IAN_ROOT/ian-path.sh
source $IAN_ROOT/ian-help.sh
source $IAN_ROOT/ian-summary.sh
source $IAN_ROOT/ian-hooks.sh
source $IAN_ROOT/ian-create.sh
source $IAN_ROOT/ian-orig.sh
source $IAN_ROOT/ian-release.sh
source $IAN_ROOT/ian-build.sh
source $IAN_ROOT/ian-install.sh
source $IAN_ROOT/ian-lintian.sh
source $IAN_ROOT/ian-repo.sh
source $IAN_ROOT/ian-clean.sh


function ian {
	if [[ -z "$__cmd__" ]]; then
		ian-run help
		return 1
	fi

	# FIXME: use get-command-list
    grep -h "^function cmd:" $IAN_ROOT/ian*.sh | grep -w "cmd:$__cmd__" > /dev/null
    if [ $? -ne 0 ]; then
		unknown-command "$__cmd__"
    fi

	for arg in "${__args__[@]}"; do
		if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
			ian-run help "$__cmd__"
			return
		fi
	done

	ian-run $__cmd__ "${__args__[@]}"
}

eval $(basename $__file__)
