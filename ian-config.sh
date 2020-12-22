function load-config {
    local superseded
    local config_vars="DEBFULLNAME DEBEMAIL DEBSIGN_KEYD DEBPOOL EDITOR"

    for var in $config_vars; do
        ref="env_$var"
        eval "$ref=\"${!var}\""
    done

    load-config-files

    for var in $config_vars; do
        if sc-var-defined "env_$var"; then
            log-warning "environ variable supersedes config files: $var=\"${!var}\""
            ref="env_$var"
            eval "$var=\"${!ref}\""
        fi
        superseded=true
    done

    # FIXME
    # if [ $superseded = true ]; then
    #     log-info "you can suppress supersedes warnings defining 'QUIET_CONFIG=true'"
    # fi
}

function load-config-files {
    if sc-directory-exists $IAN_CONFIG; then
       log-warning "'$IAN_LEGACY_CONFIG' is deprecated, rename it as '$IAN_CONFIG'"
       if [ -e $IAN_LEGACY_CONFIG ]; then
           source $IAN_LEGACY_CONFIG
       fi
    elif sc-file-exists $IAN_CONFIG; then
        source $IAN_CONFIG
    fi

    if [ -e $IAN_CWD_CONFIG ]; then
        source $IAN_CWD_CONFIG
    fi
}

#FIXME: generate missing lines in ~/.config/ian/config
function cmd:debvars-newbie {
	local TMP=$(mktemp)
	local need_vars=false

	if ! sc-var-defined DEBFULLNAME; then
		echo "DEBFULLNAME=$USERNAME" >> $TMP
		log-warning "exporting placeholder 'DEBFULLNAME=$USERNAME'"
		need_vars=true
	fi

	if ! sc-var-defined DEBEMAIL; then
		fakemail="$LOGNAME@$HOSTNAME"
		echo "DEBEMAIL=\"$fakemail\"" >> $TMP
		log-warning "exporting placeholder 'DEBEMAIL=$fakemail'"
		need_vars=true
	fi

	if ! sc-var-defined DEBSIGN_KEYID; then
		fakeid="DEADBEE"
		echo "DEBSIGN_KEYID=$fakeid" >> $TMP
		log-warning "exporting placeholder 'DEBSIGN_KEYID=$fakeid'"
		need_vars=true
	fi

	if ! sc-var-defined DEBPOOL; then
		fakepath="$USERNAME@your.server.net/path/to/repo"
		echo "DEBPOOL=$fakepath" >> $TMP
		log-warning "exporting placeholder 'DEBPOOL=$fakepath'"
		need_vars=true
	fi

	if [ "$need_vars" = false ]; then
		log-info "Your environment is already right. You don't seem a newbie."
	else
		log-warning "run: 'cat $TMP >> $IAN_CONFIG', make your changes and retry."
	fi
}

function cmd:debvars {
	echo "DEBFULLNAME:  " $DEBFULLNAME
	echo "DEBEMAIL:     " $DEBEMAIL
	echo "DEBSIGN_KEYID:" $DEBSIGN_KEYID
	echo "DEBPOOL:      " $DEBPOOL
}
