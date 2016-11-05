# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

#-- vagrant boxes --

VAGRANT_FILES="Vagrantfile playbook.yml"

function cmd:vagrant-gen-files {
##:150:cmd:generate vagrant related files to boxed compilation
    assert-no-more-args

    (
    assert-preconditions

    for i in $VAGRANT_FILES; do
	cp $IAN_ROOT/$i .
    done

    log-ok "generated: $VAGRANT_FILES"
    )
}

function cmd:vagrant-build {
##:151:cmd:build package in the vagrant boxes
    assert-no-more-args

    (
    assert-preconditions
    sc-assert-files-exist $VAGRANT_FILES

    local ian_pwd=$(basename $(pwd))

	echo \# Run this to build amd64 and i386 binaries
	echo ian clean
    echo vagrant up --provision i386
    echo "vagrant ssh i386 -c \"cd /vagrant/$ian_pwd; ian build -mb\""
    echo vagrant up --provision amd64
    echo "vagrant ssh amd64 -c \"cd /vagrant/$ian_pwd; ian build -m\""
    )
}

function cmd:vagrant-clean {
##:152:cmd:remove vagrant related files
    assert-no-more-args

    (
    assert-preconditions

    vagrant destroy  -f
    rm $VAGRANT_FILES
    )
}
