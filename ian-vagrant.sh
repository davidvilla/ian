# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

#-- vagrant boxes --

VAGRANT_FILES="Vagrantfile playbook.yml"

function cmd:vagrant-provision {
##:200:cmd:prepare vagrant images to boxed build
    assert-no-more-args

    (
    assert-preconditions

    for i in $VAGRANT_FILES; do
        cp $IAN_ROOT/vagrant/$i .
    done

    log-ok "generated: $VAGRANT_FILES"

    check-run "cmd:clean"
    check-run "vagrant up --provision i386"
    check-run "vagrant up --provision amd64"
    )

    echo -e "\n# In case of 'Suite' value change issues run:"
    echo "$ vagrant ssh {vm} -c \"sudo apt update; sudo apt install apt-transport-https\""
    echo "and run 'ian vagrant-provision' again"

}

function cmd:vagrant-build {
##:201:cmd:build package in the vagrant boxes
    assert-no-more-args

    (
    assert-preconditions
    sc-assert-files-exist $VAGRANT_FILES

    local ian_pwd=$(basename $(pwd))

	echo \# Run commands above to build amd64 and i386 binaries
    echo "vagrant ssh i386 -c \"cd /vagrant/$ian_pwd; ian build -mb\""
    echo "vagrant ssh amd64 -c \"cd /vagrant/$ian_pwd; ian build -m\""
    )
}

function cmd:vagrant-clean {
##:202:cmd:remove vagrant related files
    assert-no-more-args

    (
    assert-preconditions

    vagrant destroy  -f
    rm $VAGRANT_FILES
    )
}
