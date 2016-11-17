# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

function cmd:create() {
##:120:cmd:create sample files for a new debian package
    assert-no-more-args

    local pkgname=$(basename $(pwd))

    (
    sc-assert sc-directory-absent ./debian "There is already a debian directory here"
    assert-debvars

    log-info "Check Makefile"
    if ! grep install Makefile > /dev/null; then
        sc-log-error "Your Makefile should have an 'install' rule. See created 'Makefile.example'"
        _create-makefile
        exit 1
    fi

    mkdir -p debian/source
    echo "3.0 (quilt)" > ./debian/source/format
    # echo "compression = \"gzip\"" > ./debian/source/options
    echo 7 > ./debian/compat

    _create-control "$pkgname"
    _create-rules

    log-info "Creating initial release (date based version applied)"
    do-release "0.$TODAY" 1 true "Initial release"

    _create-copyright

    log-warning "Customize ./debian files on your own."
    log-warning "See https://www.debian.org/doc/debian-policy/ and good luck!"
    log-ok "create"
    )
}

function _create-makefile() {
    cat <<EOF > ./Makefile.example
# -*- mode: makefile-gmake; coding: utf-8 -*-
DESTDIR ?= ~

all:

install:
	FIXME: Install your scripts/binaries/libraries/...
	install -vd \$(DESTDIR)/usr/bin
	install -v -m 555 bin/your-script.sh \$(DESTDIR)/usr/bin/
EOF
}

function _create-control() {
    local pkgname="$1"

    log-info "Creating debian/control"
    cat <<EOF > ./debian/control
Source: $pkgname
Section: utils
Priority: extra
Maintainer: $DEBFULLNAME <$DEBEMAIL>
Build-Depends: debhelper (>= 7.0.50~), quilt
Standards-Version: 3.9.8

Package: $pkgname
Architecture: all
Depends: \${misc:Depends}
Description: FIXME: Short description of the $pkgname package
 FIXME: long description about the basic features of the $pkgname package
EOF
}

function _create-rules() {
    log-info "Creating debian/rules"
    cat <<EOF > ./debian/rules
#!/usr/bin/make -f

%:
	dh \$@  # --with quilt,python2,python3
EOF
    chmod +x ./debian/rules
}

function _create-copyright() {
    cat <<EOF > ./debian/copyright
Copyright $(date +%Y) $DEBFULLNAME <$DEBEMAIL>

License: GPL (/usr/share/common-licenses/GPL)
EOF
}
