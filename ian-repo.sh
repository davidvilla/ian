# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- repo actions -----------------------------------------------------

function cmd:upload {
##:090:cmd:sign and upload binary packages to the configured remote pool
##:090:usage:ian upload [nickname]
##:090:usage:   nickname;  Upload to nickname'd host (see dupload -t option)

	local nickname="${__args__[@]}"

	assert-debian-files
	sc-assert-files-exist $(binary-paths)

	local retval=0

    for changes_path in $(_postbuild-changes-filenames); do
		_create-dupload-config
		_do-upload $changes_path $nickname
		if [ $? -ne 0 ]; then
			retval=1
		fi
    done

	return $retval
}

function _dupload-filename {
	echo "/tmp/$USER-dupload.config"
}

function _create-dupload-config {
	log-info "creating $(_dupload-filename)"
	cat <<EOF > $(_dupload-filename)
# .ssh/config
# Host debrepo
#      Hostname <your-repo-host>
#      User $(_repo-user)
#      IdentityFile ~/.ssh/your-private-key-for-debrepo

package config;

\$default_host = "debrepo";

\$cfg{'debrepo'} = {
   fqdn => "debrepo",
   login => "$(_repo-user)",
   method => "scpb",
   incoming => "$(repo-path)/incoming/",

   # The dinstall on ftp-master sends emails itself
   dinstall_runs => 1,
};

\$postupload{'changes'} = 'ssh $(_repo-account) "reprepro -V -b $(repo-path) processincoming sid-process"';

\$cfg{'local'} = {
   method => "copy",
   incoming => "$(repo-local-path)/incoming/",

   dinstall_runs => 1,
};

\$cfg{'local'}{postupload}{'changes'} = 'reprepro -V -b $(repo-local-path) processincoming sid-process';

1;  # DO NOT remove this line!
EOF
}

function _do-upload {
    local changes_path="$1"
	local nickname="$2"

	nickname=${nickname:+"-t $nickname"}

    (
	# sc-assert-files-exist ~/.gnupg/secring.gpg
    sc-assert-files-exist $changes_path $(binary-paths) $(_dupload-filename)

	notify-upload-start

    while true; do
		sc-assert-run "LANG=$NATIVE_LANG debsign -k$DEBSIGN_KEYID --no-re-sign $changes_path"

		local -a outputs
		sc-call-out-err outputs "dupload -c $(_dupload-filename) -f $changes_path $nickname"
		local rcode=$?

		if [ $rcode -eq 0 ]; then
			break
		fi

		_check-dupload-errors ${outputs[2]}
		if [ $? -eq 1 ]; then
			break
		fi
    done

    log-info "dupload output"

    if [ $rcode -eq 0 ]; then
		ian-run "cat ${outputs[1]}"
		log-ok "upload"
		notify-upload-end
    else
		ian-run "cat ${outputs[2]}"
		log-fail "upload"
    fi

    rm ${outputs[@]}
	return $rcode
    )
}

function _check-dupload-errors {
    local stderr="$1"

    local NOT_YET_REGISTERED="not yet registered in the pool and not found in '$(changes-filename)'"
    local DSC_ALREADY_REGISTERED=".dsc\" is already registered with different checksums"
    local DEB_ALREADY_REGISTERED=".deb\" is already registered with different checksums"
    local ORIG_ALREADY_REGISTERED=".orig.tar.gz\" is already registered with different checksums"

    if _file-contains "$stderr" "$NOT_YET_REGISTERED"; then
		log-warning "missing $(orig-filename) in repository, fixing..."
		check-run "dpkg-genchanges -sa > $changes_path"
		return
    elif _file-contains "$stderr" "$DSC_ALREADY_REGISTERED"; then
		log-warning "$(dsc-filename) already in repository, fixing..."
		check-run "dpkg-genchanges -b > $changes_path"
		return
    elif _file-contains "$stderr" "$ORIG_ALREADY_REGISTERED"; then
		sc-log-error "1. orig already uploaded! Try 'ian build -b' and upload again"
		if [ $(debian-release) -ne 1 ]; then
			sc-log-error "2. different orig already uploaded! Create a new release"
		fi
    elif _file-contains "$stderr" "$DEB_ALREADY_REGISTERED"; then
		sc-log-error "deb already uploaded! Create a new release"
    fi

    return 1
}

function _file-contains {
    cat "$1" | grep "$2"
}

# function sign-and-upload {
#     sc-assert-run "LANG=$NATIVE_LANG debsign $(changes-path)"
#     sc-assert-run "dupload -f $(changes-path)"
# }


function _reprepro-cmd {
    check-run "ssh $(_repo-account) \"reprepro -b $(repo-path) $*\""
}

function cmd:remove {
##:100:cmd:remove package from configured remote pool
##:100:usage:ian remove [-y]
##:100:usage:  -y;  do not ask for confirmation

    local quiet=false
    local OPTIND=1 OPTARG OPTION

    while getopts :y OPTION "${__args__[@]}"; do
		case $OPTION in
			y)
				quiet=true ;;
			\?)
				echo "invalid option: -$OPTARG"
				exit 1 ;;
			:)
				echo "option -$OPTARG requires an argument"
				exit 1 ;;
		esac
    done

    assert-no-more-args $OPTIND

    echo "Related files in '$DEBREPO_URL':"
    cmd:repo-list
    echo

    if [ $quiet = false ]; then
		if ! _user-confirm "Delete them"; then
			return
		fi
    fi

    for pkg in $(sc-filter-dups $(binary-names) $(dbgsym-names) $(package)); do
		_remove-package "$pkg" "$arch"
    done
}

function _user-confirm {
	local msg="$1"

	read -r -p "$msg? [y/N] " response
	response=${response,,}    # tolower
	if ! [[ $response =~ ^(yes|y)$ ]]; then
		echo "(cancel)"
		return 1
	fi
}

function _remove-package {
    local package=$1
    local arch

    if [ ! -z $2 ]; then
		local arch="-A $2"
    fi

    _reprepro-cmd $arch -V remove sid $package
}

function _repo-account {
    (
    sc-assert-var-defined DEBREPO_URL
    echo ${DEBREPO_URL%%/*}
    )
}

function _repo-user {
	local username
    (
    sc-assert-var-defined DEBREPO_URL
    username=${DEBREPO_URL%%@*}
	if [ "$username" == "$DEBREPO_URL" ]; then
		echo $USER
	else
		echo $username
	fi
    )
}

# help
# repo
function repo-path {
    (
    sc-assert-var-defined DEBREPO_URL
    echo /${DEBREPO_URL#*/}
    )
}

function repo-local-path {
	(
	sc-assert-var-defined DEBREPO_LOCAL_DIR
	echo $DEBREPO_LOCAL_DIR
	)
}

function cmd:repo-list {
# list related packages in the public repository

    for pkg in $(sc-filter-dups $(binary-names) $(dbgsym-names) $(package)); do
		_reprepro-cmd list sid $pkg
    done
}

function _postbuild-changes-filenames {
    ls -1 $(build-dir)/$(package)_$(debian-version)_*.changes
}
