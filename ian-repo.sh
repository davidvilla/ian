# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- pool actions -----------------------------------------------------

function cmd:upload {
##:090:cmd:sign and upload binary packages to the configured pool
##:090:usage:ian upload [arch]
##:090:usage:  arch;  overwrite detected package architecture, for a cross-compiled package.


	local arch="${__args__[@]}"

	if [ ! -z "$arch" ]; then
        log-warning "looking for cross-compiled package with arch '$arch'"

		# monkey-patch detected arch
        function _binary-arch() {
			echo "$arch"
		}
	fi

	assert-preconditions
	sc-assert-deb-pkgs-installed reprepro
	sc-assert-files-exist $(binary-paths)

	local retval=0

	log-info "Debian pool: $DEBPOOL"

    for changes_path in $(_postbuild-changes-filenames); do
		_create-dupload-config
		_do-upload $changes_path
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
	if _pool-is-remote; then
		_create-dupload-remote-config
	else
		_create-dupload-local-config
	fi
}

function _create-dupload-remote-config {
	cat <<EOF > $(_dupload-filename)
# .ssh/config
# Host debrepo
#      Hostname <your-repo-host>
#      User $(_pool-user)
#      IdentityFile ~/.ssh/your-private-key-for-debrepo

package config;

\$default_host = "default";

\$cfg{'default'} = {
   fqdn => "debrepo",
   login => "$(_pool-user)",
   method => "scpb",
   incoming => "$(_pool-path)/incoming/",

   dinstall_runs => 1,
};

\$postupload{'changes'} = ['ssh $(_pool-account) "reprepro -V -b $(_pool-path) processincoming sid-process"'];

1;  # DO NOT remove this line!
EOF
}

function _create-dupload-local-config {
	cat <<EOF > $(_dupload-filename)
package config;

\$default_host = "default";

\$cfg{'default'} = {
   method => "copy",
   incoming => "$DEBPOOL/incoming/",

   dinstall_runs => 1,
};

\$postupload{'changes'} = ['reprepro -V -b $DEBPOOL processincoming sid-process'];

1;  # DO NOT remove this line!
EOF
}

function _do-upload {
    local changes_path="$1"

    (
	# sc-assert-files-exist ~/.gnupg/secring.gpg
    sc-assert-files-exist $changes_path $(binary-paths) $(_dupload-filename)

	notify-upload-start

	local second_try=false
    while true; do
		check-run "LANG=$NATIVE_LANG debsign -k$DEBSIGN_KEYID --no-re-sign $changes_path"

		local -a outputs
		local cmd="dupload --skip-hook=openpgp-check -c $(_dupload-filename) -f $changes_path"
		sc-log-info "$cmd"
		sc-call-out-err outputs "$cmd"
		local rcode=$?

		if [ $rcode -eq 0 ]; then
			break
		fi

		_check-dupload-errors ${outputs[2]}
		if [ $? -eq 1 ]; then
			break
		fi

		if $second_try; then
			log-error "automatic fix failed"
			break
		fi
		second_try=true
    done

    log-info "dupload output"

    if [ $rcode -eq 0 ]; then
	    cat ${outputs[1]} > >(_indent "$OUT_SIGN")
		log-ok "upload"
		notify-upload-end
    else
	    cat ${outputs[2]} > >(_indent "$ERR_SIGN")
		log-fail "upload"
    fi

    rm ${outputs[@]}
	return $rcode
    )
}

function _check-dupload-errors {
    local stderr="$1"

    local NOT_YET_REGISTERED="not yet registered in the pool and not found in"
    local DSC_ALREADY_REGISTERED=".dsc\" is already registered with different checksums"
    local DEB_ALREADY_REGISTERED=".deb\" is already registered with different checksums"
    local ORIG_ALREADY_REGISTERED=".orig.tar.gz\" is already registered with different checksums"
	local POOL_VERSION_NEWER="while there already is the stricly newer"


    if _file-contains "$stderr" "$NOT_YET_REGISTERED"; then
		log-warning "missing orig file in repository, fixing..."
		check-run "dpkg-genchanges -sa > $changes_path"
		return
    elif _file-contains "$stderr" "$DSC_ALREADY_REGISTERED"; then
		log-warning "$(dsc-filename) already in repository, fixing..."
		check-run "dpkg-genchanges -b > $changes_path"
		return
    elif _file-contains "$stderr" "$ORIG_ALREADY_REGISTERED"; then
		sc-log-error "1. orig already uploaded! Try 'ian build -b' and upload again"
		if [ $(debian-release) -ne 1 ]; then
			sc-log-error "different orig already uploaded! Create a new release."
		fi
    elif _file-contains "$stderr" "$DEB_ALREADY_REGISTERED"; then
		sc-log-error "deb already uploaded! Create a new release."
    elif _file-contains "$stderr" "$POOL_VERSION_NEWER"; then
		sc-log-error "newer version already uploaded! Get last version source."
	fi

    return 1  # not fixed
}

function _file-contains {
    cat "$1" | grep "$2" > /dev/null
}

function _reprepro-cmd {
	if _pool-is-remote; then
		ian-run "ssh $(_pool-account) \"reprepro --nothingiserror -b $(_pool-path) $*\""
	else
		ian-run "reprepro --nothingiserror -b $DEBPOOL $*"
	fi
}

function _pool-is-remote {
	! [[ "$DEBPOOL" == "/"* ]]
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

    echo "Listing pool files in '$DEBPOOL' for package '$(package)':"
    cmd:pool-ls
    echo

    if [ $quiet = false ]; then
		if ! _user-confirm "Delete pool files"; then
			return
		fi
    fi

    for pkg in $(sc-filter-dups $(binary-names) $(dbgsym-names) $(package)); do
		_remove-package "$pkg" "$arch"
    done

	notify-remove
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

    if [ ! -z $3 ]; then
		local arch="-A $2"
    fi

    _reprepro-cmd $arch -V remove sid $package
}

function _pool-account {
    (
    sc-assert-var-defined DEBPOOL
    echo ${DEBPOOL%%/*}
    )
}

function _pool-user {
	local username
    (
    sc-assert-var-defined DEBPOOL
    username=${DEBPOOL%%@*}
	if [ "$username" == "$DEBPOOL" ]; then
		echo $USER
	else
		echo $username
	fi
    )
}

# help
# pool
function _pool-path {
    (
    sc-assert-var-defined DEBPOOL
    echo /${DEBPOOL#*/}
    )
}

function cmd:pool-ls {
##:101:cmd:list related packages in the configured pool repository
##:101:usage:ian pool-ls [-y]

    for pkg in $(sc-filter-dups $(binary-names) $(dbgsym-names) $(package)); do
		_reprepro-cmd list sid $pkg
    done
}

function _postbuild-changes-filenames {
    ls -1 $(build-dir)/$(package)_$(debian-version)_*.changes
}
