# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- release ------------------------------------------------------

function cmd:release {
##:020:cmd:add a new changelog entry
##:020:usage:ian release [-i] [-y] [-m release-message]
##:020:usage:  -i;      increment final version component (like 'dch -i')
##:020:usage:  -y;      do not ask for a release message
##:020:usage:  -m MSG;  release message for debian/changelog entry

    local quiet=false msg="New release" revision=false
    local OPTIND=1 OPTARG OPTION

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

    if [ "$revision" = true ]; then
		_do-release-next-revision
		return
    fi

    _do-release-standard "$quiet" "$msg"
}

function _do-release-standard {
    local quiet="$1"
    local msg="$2"

    local version_but_last=$(_upstream-version-but-last)
    local micro_version=$(_micro-upsteam-version)

    ((micro_version++))
    do-release "$version_but_last.$micro_version" 1 "$quiet" "$msg"
}

function cmd:release-date {
##:021:cmd:add a new package version based on date: 0.20010101
##:021:usage:ian release-date [-i] [-y] [-m release-message]
##:021:usage:  -i;      increment final version component (like 'dch -i')
##:021:usage:  -y;      do not ask for a release message
##:021:usage:  -m MSG;  release message for debian/changelog entry

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

	if [ "$revision" = true ]; then
		_do-release-next-revision
		return
	fi

    _do-release-date "$quiet" "$msg"
}

function _do-release-date {
    local quiet="$1"
    local msg="$2"

    local old_version=$(upstream-version)

    local major_version=$(_major-upstream-version)
    local date_version=$TODAY
    local micro_version=$(_micro-upsteam-version)

    local new_version=$major_version.$date_version
    if ! [ -z "$micro_version" ]; then
	new_version=$new_version.$micro_version
    fi

    if [ "$old_version" == "$new_version" ]; then
	((micro_version++))
	new_version=$major_version.$date_version.$micro_version
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

    notify-release
    )
}

function _major-upstream-version {
    # 1.2.3 -> 1
    echo $(upstream-version) | cut -d'.' -f1
}

function _upstream-version-but-last {
    # 1.2.3 -> 1.2
    local upstream_version=$(upstream-version)
    echo ${upstream_version%.*}
}

function _micro-upsteam-version {
    # 1.2.3 -> 3
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
