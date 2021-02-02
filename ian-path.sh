# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

function cmd:list-products {
	(>&2 log-warning "command \"list-products\" is DEPRECATED. Use \"ian ls\"")
	cmd:ls
}


function cmd:ls {
##:150:cmd:list generated files

    assert-preconditions
	_product-filenames
#    _binary-filenames

	if ! _some-product; then
        log-error "package was not built yet"
	fi
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

# function _debian-source-filename {
#     local pattern="$deb_prefix.debian.tar.*"
#     local found=
#
#     found=$(ls $(build-dir)/$pattern 2> /dev/null)
#     if [ $? -ne 0 ]; then
#     	echo $pattern
#     	return
#     fi
#
#     echo $(basename $found)
# }

# clean
function product-paths {
    for fname in $(_product-filenames); do
		echo $(build-dir)/$fname;
    done
}

# function _product-filenames-old {
#     orig-filename
#     changes-filename
#     dsc-filename
#     local deb_prefix=$(package)_$(debian-version)
#     _debian-source-filename
#     echo $deb_prefix.diff.gz
#     echo $deb_prefix.upload
# }

function _product-filenames {
	for pattern in $(_product-patterns); do
	    if ls $(build-dir)/$pattern > /dev/null 2>&1; then
	        basename $(ls $(build-dir)/$pattern)
			some=true
		fi
	done
}

function _some-product {
    [ -z "$(_product-filenames)" ] && return 1 || return 0
}

function _product-patterns {
	echo $(package)_$(upstream-version).orig.tar.gz
	echo $(package)_$(debian-version)_$(host-arch).upload
    echo $(package)_$(debian-version)_$(host-arch).changes
	echo $(package)_$(debian-version)_$(host-arch).buildinfo
	echo $(package)_$(debian-version).dsc
	echo $(package)_$(debian-version).debian.tar.*
	echo $(package)_$(debian-version).diff.gz
	for fname in $(_binary-filenames); do
        echo $fname
	done
}

function _binary-arch {
	local package_name=$1
    if [ $(_control-arch $package_name) == "all" ]; then
		echo "all"
    else
		host-arch
    fi
}
