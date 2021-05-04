#!/bin/bash
# -*- coding:utf-8; tab-width:4; mode:shell-script -*-

#-- command table --

#- info -
##:ian-map:000:help
##:ian-map:009:name
##:ian-map:010:summary
##:ian-map:012:config
##:ian-map:060:binary-contents
##:ian-map:150:ls

#- actions -
##:ian-map:015:orig
##:ian-map:020:release
##:ian-map:021:release-date
##:ian-map:030:clean
##:ian-map:031:clean-uscan
##:ian-map:040:build
##:ian-map:070:install
##:ian-map:090:upload
##:ian-map:100:remove
##:ian-map:101:pool-ls
##:ian-map:120:create
##:ian-map:140:lintian-fix
##:ian-map:200:vagrant-gen-files
##:ian-map:201:vagrant-build
##:ian-map:202:vagrant-clean

IAN_LEGACY_CONFIG=$HOME/.config/ian/config
IAN_CONFIG=$HOME/.config/ian
IAN_CWD_CONFIG=./.ian
BUILDOPTIONS=${BUILDOPTIONS:-""}
TODAY=$(date +%Y%m%d)

NORMAL=$(tput sgr0)
BOLD=$(tput bold)
GREEN=$(tput setf 2)
RED=$(tput setf 4)
DIM=$(tput dim)
BLUE=$(tput setf 1)
GREY=$(tput setf 7)

OUT_SIGN="     |"
ERR_SIGN="    e|"
CHECK_OUT_SIGN="$BLUE$OUT_SIGN$NORMAL"
CHECK_ERR_SIGN="$BLUE$ERR_SIGN$NORMAL"
SU_OUT_SIGN="$RED$OUT_SIGN$NORMAL"
SU_ERR_SIGN="$RED$ERR_SIGN$NORMAL"
TERM_COLS=$(tput cols)

__file__=$0
__cmd__=$1
shift
__args__=("$@")

IAN_ROOT=$(readlink -f $(dirname $__file__))
NATIVE_LANG="$LANG"
LANG=C

source $IAN_ROOT/shell-commodity.sh
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
source $IAN_ROOT/ian-vagrant.sh


function ian {
	if [[ -z "$__cmd__" ]]; then
		cmd:help
		return 1
	fi

	# FIXME: use get-command-list
    grep -h "^function cmd:" $IAN_ROOT/ian*.sh | grep -w "cmd:$__cmd__" > /dev/null
    if [ $? -ne 0 ]; then
		unknown-command "$__cmd__"
    fi

	eval cmd:$__cmd__
}

eval $(basename $__file__)
