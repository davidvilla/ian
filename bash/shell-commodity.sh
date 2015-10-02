# -*- coding:utf-8; tab-width:4; mode:shell-script -*-

#-- similar projects --
# https://code.google.com/p/bsfl/

__file__=$(basename $0)


#-- "standard" library --
function sc-upper {
	echo $1 | tr '[:lower:]' '[:upper:]'
}

function sc-retcode2bool {
    [ $1 -eq 0 ] && echo "True" || echo "False"
}

function sc-retcode2test {
    [ $1 -eq 0 ] && echo OK || echo FAIL
}

function sc-func2bool {
	eval "$1"
	sc-retcode2bool "$?"
}

function sc-set-trap {
#	trap $1 HUP INT QUIT TERM ERR  # EXIT
	trap $1 HUP INT QUIT TERM EXIT
}

function sc-clear-trap {
	trap - HUP INT QUIT TERM ERR EXIT
}

function sc-strip-comments {
    sed '/^ *#/d;/^$/d' ${1:--}
}


# usage: string_rep SEARCH REPL STRING
# replaces all instances of SEARCH with REPL in STRING
# http://mywiki.wooledge.org/BashFAQ/021
function sc-str-replace() {
	local old=$1
	local new=$2
	local text=$3
	local out

	[[ $old ]] || return

	while true; do
		case "$text" in
			*"$old"*) : ;;
			*) break;;
		esac

		out=$out${text%%"$old"*}$2
		text=${text#*"$old"}
	done

	printf '%s%s\n' "$out" "$text"
}

function sc-str-split() {
	local text=$1
	local sep=$2

	echo $text | tr "$sep" "\n"
}

#-- Predicates --

function sc-var-defined {
    [ ! -z "$(eval echo \$${1})" ]
}

function sc-is-substring {
	# $1: is substring
    # $2: of that string
	[[ "$1" =~ "${2}" ]]
}

function sc-file-exists {
    [ -e "$1" ]
}

function sc-directory-exists {
    [ -d "$1" ]
}

function sc-directory-absent {
    [ ! -d "$1" ]
}

function sc-deb-pkg-installed {
    dpkg -l "$1" 2> /dev/null | grep "^ii" &> /dev/null
}

function sc-bin-exists {
	type -t "$1" > /dev/null
}

function sc-function-exists {
	type -t "$1" | grep "function" > /dev/null
}

function sc-assert {
	# assert any predicate
	local callable="$1"
	local arg="$2"
    local msg=${3:-"Assertion failed: $1 $2"}

    if ! eval $callable "$arg"; then
		sc-log-error "$msg"
		exit 1
    fi
}

function sc-assert-run {
# assert command execution
	# $1: command
    # $2: message prefix
	local default="run"
	local msg="${2:-$default}: $1"
	sc-log-info "$msg"
	if ! eval $1; then
		sc-log-fail "$msg"
		exit 1
	fi
}

function sc-assert-run-ok {
# assert command execution with positive feedback
	sc-assert-run "$1" "$2"
	sc-log-ok "$1"
}

#-- specific assertions --

function sc-assert-var-defined {
	local default="Environment variable $1 must be defined"
	local msg="${2:-$default}"
    sc-assert sc-var-defined $1 "$msg"
}

function sc-assert-files-exist {
	for file in $*; do
		sc-assert sc-file-exists "$file" "File required: $file"
	done
}

function sc-assert-directory-exists {
    sc-assert sc-directory-exists "$1" "Directory required: $1"
}

function sc-assert-deb-pkgs-installed {
	for pkg in $*; do
		sc-assert sc-deb-pkg-installed "$pkg" "deb pkg required: $pkg"
	done
}

function sc-assert-binaries-exist {
	for bin in $*; do
		sc-assert sc-bin-exists "$bin" "binary required: $bin"
	done
}


#-- assures

function sc-assure-dir {
	if ! sc-directory-exists "$1"; then
		mkdir "$1"
	fi
}

function sc-assure-deb-pkg-installed {
    local deps
    for d in $*; do
		if ! sc-deb-pkg-installed $d; then
			deps="$d $deps"
		fi
    done

	if [ "none$deps" != "none" ]; then
	   sc-assert-run-ok "sudo apt-get install -y $deps"
	fi
}



#-- logging --

#LEVEL_ERROR=1
#LEVEL_WARN=2
#LEVEL_INFO=3
#
#LOGLEVEL=$LEVEL_ERROR

bold="\033[1m"

function sc-log-notify {
	local red="\e[1;31m"
	local green="\e[1;32m"
	local yellow="\e[1;33m"
	local blue="\e[1;34m"
	local norm="\e[0m"
	local color=""

	local message=$2
	local level="info"

	if [ -z "$message" ]; then
		return
	fi

	if [ $1 = "EE" ]; then
		level="error"
		color=$red;
	elif [ $1 = "FF" ]; then
		level="fail"
		color=$red;
	elif [ $1 = "WW" ]; then
#		if [  $LOGLEVEL -lt $LEVEL_WARN ]; then
#			return
#		fi
		level="warning"
		color=$yellow;
		message=$bold$message$norm
	elif [ $1 = "II" ]; then
#		if [  $LOGLEVEL -lt $LEVEL_INFO ]; then
#			return
#		fi
		color=$blue;
	elif [ $1 = "OK" ]; then
		level="ok"
		color=$green;
	fi

	printf "[$color$1$norm] $message \n"
	notify-log-notify "$level" "$message"
}

function notify-log-notify {
	if sc-function-exists sc-log-notify-hook; then
		sc-log-notify-hook "$1" "$2" &
	fi
}

function sc-bold {
	echo "$bold$1$norm"
}

function sc-log-notify-hook {
	# override this function to show status notification
	# $1 is level: information, warning, error
	# $2 is message
	# notify-send -i dialog-$1 -h int:transient:1 "$2"
	true
}

function sc-log-info {
	sc-log-notify II "$1"
}

function sc-log-warning {
	sc-log-notify WW "$1"
}

function sc-log-warn {
	sc-log-notify WW "$1"
}

function sc-log-error {
	sc-log-notify EE "$1"
}

function sc-log-fail {
	sc-log-notify FF "$1"
}

function sc-log-ok {
	sc-log-notify OK "$1"
}


# how to use sc-call-out-err
#
# function test {
#     local -a outputs
#     sc-call-out-err outputs "command-line"
#     echo "--stdout" ${outputs[1]}
#     echo "--stderr" ${outputs[2]}
# }
function sc-call-out-err {
	local _outputs=$1
	shift

	local stdout=$(mktemp)
	local stderr=$(mktemp)

#	$* 1> >(tee $stdout >&1) 2> >(tee $stderr >&2)
	$* 1> $stdout 2> $stderr

	local retcode=$?

	_out[0]=''
	_out[1]=$stdout
	_out[2]=$stderr

	eval $_outputs='("${_out[@]}")'
	return $retcode
}
