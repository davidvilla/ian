# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

function cmd:list-products {
##:200:cmd:list product files
    _product-filenames
    _binary-filenames
}

function _binary-filenames {
    for pkg in $(binary-names); do
	echo ${pkg}_$(debian-version)_$(_binary-arch $pkg).deb
    done
}

# clean
# repo
# build
# install
function binary-paths {
    local build_path=".."
    for fname in $(_binary-filenames); do
	echo $build_path/$fname
    done
}

# repo
function changes-filename {
    echo $(package)_$(debian-version)_$(host-arch).changes
}

# repo, main, path, lintian, summary
function changes-path {
    echo $(build-dir)/$(changes-filename)
}

# repo
function dsc-filename {
    echo $(package)_$(debian-version).dsc
}

# function dsc-path {
#     echo $(build-dir)/$(dsc-filename)
# }

# clean
function product-paths {
    for fname in $(_product-filenames); do
	echo $(build-dir)/$fname;
    done
}

function _product-filenames {
    orig-filename
    changes-filename
    dsc-filename
    local deb_prefix=$(package)_$(debian-version)
    echo $deb_prefix.debian.tar.gz
    echo $deb_prefix.diff.gz
    echo $deb_prefix.upload
}

function _binary-arch {
    # $1: package name
    if [ $(_control-arch $1) == "all" ]; then
	echo "all"
    else
	host-arch
    fi
}
