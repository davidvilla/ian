# -*- coding:utf-8; tab-width:4; mode:shell-script -*-

#-- similar projects --
# https://code.google.com/p/bsfl/


#-- "standard" library --
function sc-upper {
	echo $1 | tr '[:lower:]' '[:upper:]'
}

function sc-retcode2bool {
    [ $1 -eq 0 ] && echo True || echo False
}

function sc-retcode2test {
    [ $1 -eq 0 ] && echo OK || echo FAIL
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
	in=$3
	unset out

	[[ $1 ]] || return

	while true; do
		case "$in" in
			*"$1"*) : ;;
			*) break;;
		esac

		out=$out${in%%"$1"*}$2
		in=${in#*"$1"}
	done

	printf '%s%s\n' "$out" "$in"
}

function sc-str-split() {
	echo $1 | tr "$2" "\n"
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

function sc-deb-pkg-installed {
    dpkg -l "$1" 2> /dev/null | grep "^ii" &> /dev/null
}

function sc-bin-exists {
	type -t "$1" > /dev/null
}

function sc-assert {
	# $1: function
    # $2: argument
    # $3: error message
    local msg=${3:-"Assertion failed: $1 $2"}
    if ! eval $1 $2; then
		sc-log-error "$msg"
		exit 1
    fi
}

function sc-assert-run {
	# $1: command
    # $2: message prefix
	local msg="${2:-"run"}: $1"
	sc-log-info "$msg"
	if ! eval $1; then
		sc-log-fail "$msg"
	fi
}

#-- specific assertions --

function sc-assert-var-defined {
    sc-assert sc-var-defined $1 "Environment variable $1 must be defined"
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
	sc-assert "sudo apt-get install $*"
}


#-- logging --

#LEVEL_ERROR=1
#LEVEL_WARN=2
#LEVEL_INFO=3
#
#LOGLEVEL=$LEVEL_ERROR

function sc-log-notify {
	red="\e[1;31m"
	green="\e[1;32m"
	yellow="\e[1;33m"
	blue="\e[1;34m"
	norm="\e[0m"
	color=""
    bold="\033[1m"

	message=$2

	if [ -z "$message" ]; then
		return
	fi

	if [ $1 = "EE" -o $1 = "FF" ]; then
		color=$red;
	elif [ $1 = "WW" ]; then
#		if [  $LOGLEVEL -lt $LEVEL_WARN ]; then
#			return
#		fi
		color=$yellow;
		message=$bold$message$norm
	elif [ $1 = "II" ]; then
#		if [  $LOGLEVEL -lt $LEVEL_INFO ]; then
#			return
#		fi
		color=$blue;
	elif [ $1 = "OK" ]; then
		color=$green;
	fi

	printf "[$color$1$norm] $message \n"
	sc-log-notify-hook "$1" "$message"
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

function sc-log-error {
	sc-log-notify EE "$1"
}

function sc-log-fail {
	sc-log-notify FF "$1"
}

function sc-log-ok {
	sc-log-notify OK "$1"
}
