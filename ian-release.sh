# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

function cmd:release {
##:release:cmd:add a new changelog entry
##:release:usage:ian release [-i] [-u] [-y] [-m release-message]
##:release:usage:  -i;      increment debian version suffix (like 'dch -i')
##:release:usage:  -u;      the upstream version uscan finds, or the next debian revision if it is not newer
##:release:usage:  -y;      don't ask for a release message
##:release:usage:  -m MSG;  release message for debian/changelog entry

    local quiet=false msg="New release" revision=false upstream=false
    local OPTIND=1 OPTARG OPTION

    while getopts m:yiu OPTION "${__args__[@]}"; do
		case $OPTION in
			m)
				msg="$OPTARG" ;;
			y)
				quiet=true ;;
			i)
				revision=true ;;
			u)
				upstream=true ;;
			\?)
				echo "invalid option: -$OPTARG"
				exit 1 ;;
			:)
				echo "option -$OPTARG requires an argument"
				exit 1 ;;
		esac
    done

    assert-no-more-args $OPTIND
    assert-preconditions

    if [ "$revision" = true ]; then
		_do-release-next-revision
		return
    fi

    if [ "$upstream" = true ]; then
		_do-release-upstream "$quiet" "$msg"
		return
    fi

    _do-release-standard "$quiet" "$msg"
}

# the version is upstream's (debian/watch): a new upstream version if uscan
# finds one newer than the current, the next debian revision otherwise
function _do-release-upstream {
	local quiet="$1"
	local msg="$2"

	local newest=$(_uscan-newest-version)
	if [ -z "$newest" ]; then
		log-error "uscan found no upstream version, see 'uscan --report --verbose'"
		exit 1
	fi

	if dpkg --compare-versions "$newest" gt "$(upstream-version)"; then
		do-release "$newest" 1 "$quiet" "$msg"
	else
		_do-release-next-revision
	fi
}

# newest upstream version uscan finds on the remote site (uscan exits 1 when
# it is not newer, so the exit status is not checked)
function _uscan-newest-version {
	uscan --report --dehs 2>/dev/null | sed -n 's|^<upstream-version>\(.*\)</upstream-version>$|\1|p'
}

function _do-release-standard {
    local quiet="$1"
    local msg="$2"

    local version_but_last=$(_upstream-version-but-last)
    local micro_version=$(_micro-upsteam-version)
	local version_last_field=$(_version-last-field)

    ((version_last_field++))
    do-release "$version_but_last.$version_last_field" 1 "$quiet" "$msg"
}

function cmd:release-date {
##:release-date:cmd:add a new package version based on date: 0.20010101
##:release-date:usage:ian release-date [-i] [-y] [-m release-message]
##:release-date:usage:  -i;      increment final version component (like 'dch -i')
##:release-date:usage:  -y;      do not ask for a release message
##:release-date:usage:  -m MSG;  release message for debian/changelog entry

    local quiet=false msg="New release" revision=false
    local OPTIND=1 OPTARG OPTION

    # FIXME DRY
    while getopts m:yi OPTION "${__args__[@]}"; do
		case $OPTION in
			m)
				msg="$OPTARG" ;;
			y)
				quiet=true ;;
			i)
				revision=true ;;
			\?)
				echo "invalid option: -$OPTARG"
				exit 1 ;;
			:)
				echo "option -$OPTARG requires an argument"
				exit 1 ;;
		esac
	done

    assert-no-more-args $OPTIND
    assert-preconditions

	if [ "$revision" = true ]; then
		_do-release-next-revision
		return
	fi

    _do-release-date "$quiet" "$msg"
}

function _do-release-date {
	local quiet="$1"
	local msg="$2"

	local major_version=$(_major-upstream-version)
	local two_first=$(_upstream-version-two-first)
	local micro_version=$(_micro-upsteam-version)

	local new_version=$major_version.$TODAY
	if [ "$two_first" == "$new_version" ]; then
		((micro_version++))
		new_version=$major_version.$TODAY.$micro_version
	fi

	do-release "$new_version" 1 "$quiet" "$msg"
}

function do-release() {
    local version="$1"
    local revision="$2"
    local quiet="$3"
    local msg="$4"
    local CHLOG=$(mktemp)

    (
    assert-debvars
    sc-assert-directory-exists ./debian

    cat <<EOF > $CHLOG
$(package) ($version-$revision) unstable; urgency=low

  * $msg

 -- $DEBFULLNAME <$DEBEMAIL>  $(date -R)

EOF

	if sc-file-exists "debian/changelog"; then
		cat debian/changelog >> $CHLOG
	fi

	mv $CHLOG debian/changelog
	assert-debian-files
	_log-release

	if [ "$quiet" = false ]; then
		log-info "Openning \$EDITOR ($EDITOR) to get user release comments"
		$EDITOR debian/changelog
	fi

    )
}

function _major-upstream-version {
    # 1.2.3 -> 1
    echo $(upstream-version) | cut -d'.' -f1
}

function _upstream-version-but-last {
    # 1.2.3 -> 1.2
    # 1.2   -> 1
    local upstream_version=$(upstream-version)
    echo ${upstream_version%.*}
}

function _upstream-version-two-first {
    # 1.2.3 -> 1.2
	# 1.2   -> 1.2
    local upstream_version=$(upstream-version)
    echo $upstream_version | awk -F. '{ printf "%s.%s", $1, $2 }'
}

function _micro-upsteam-version {
    # 1.2.3 -> 3  (third, not last!)
    echo $(upstream-version) | cut -d'.' -f3
}

function _version-last-field {
    # 1.2.3 -> 3  (last!)
	local upstream=$(upstream-version)
    echo ${upstream##*.}
}

function _do-release-next-revision {
    revision=$(_debian-revision)
    ((revision++))
    do-release $(upstream-version) "$revision" "$quiet" "$msg"
}

function _debian-revision {
    # 1.2.3-4 -> 4
    echo $(debian-version) | cut -d'-' -f2
}

function _log-release {
    log-info "setting version to $(debian-version)"
}
