===
ian
===

*simple tool for lazy Debian package maintainers*


at a glance
===========

Compiling a simple package with **ian**::

  $ apt-get source hello
  $ cd hello-2.9
  hello-2.9$ ian build
  ... a lot of stuff ...
  hello-2.9$ ls -la ../hello_*
  -rw-r--r--  1 david david   1798 oct 31 16:02 ../hello_2.9-1_amd64.changes
  -rw-r--r--  1 david david  50462 oct 31 16:02 ../hello_2.9-1_amd64.deb
  -rw-r--r--  1 david david   8584 oct 31 16:02 ../hello_2.9-1.debian.tar.xz
  -rw-r--r--  1 david david    793 oct 31 16:02 ../hello_2.9-1.dsc
  -rw-r--r--  1 david david 730504 oct 31 16:02 ../hello_2.9.orig.tar.gz


**NOTE:** Your user should be a "sudoer" to easly complete several ian tasks.

commands
========

ian help
--------

show help about the specified command.


ian summary
-----------

prints information about the current directory Debian package::

  hello-2.9$ ian summary
  source:              hello
  uptream:             2.9
  watch:               2.10
  version:             2.9-2
  orig:                ../hello_2.9.orig.tar.gz
    methods:           uscan from-local
  changes:             ../hello_2.9-2_i386.changes
  binaries:            hello
  pkg vcs:             none


ian orig
--------

create or download the .orig file.

**ian** chooses between these backends (all of them are commands too):

* orig-uscan:      download latest upstream with uscan
* orig-from-rule:  execute the rule "get-orig" in the debian/rules
* orig-from-local: generates .orig from current directory files


ian build [-c] [-f] [-i] [-m] [-s]
----------------------------------

compiles Debian sources to generate binary packages.

* applies **quilt** patches if present
* automatically install missing build depends

**ian** chooses between these backends:

* build-standard: compile with dpkg-buildpackage
* build-svn:      compile with svn-buildpackage

there are several available options:

* -c: run "ian clean" before "build"
  -f;  force build
* -i: run "ian install" after "build"
* -m: merge ./debian with upstream .orig. bypassing directory contents
* -s: include full source code in upload

ian clean
---------

removes all generated files and artifacts.

* reverts quilt patches if present

**ian** chooses between these backends:

* clean-common: remove deb, orig, changes, dsc, diff, upload, debian.tar.gz
* clean-svn:    remove svn-buildpackage artifacts: tarballs/*, build-area/*
* clean-uscan:  remove uscan downloaded files (available as "ian clean-uscan")


ian install
-----------

install all generated binary packages in the system.


ian release
-----------

creates a new debian package release. It opens your editor asking for comments.


ian release-date [-y] [-m message]
----------------------------------

use a date based version format for the new package.

* -y: do not ask for release comments
* -m: set comment as CLI argument


ian upload
----------

upload binary packages to a remote package repository.

* runs debsign and dupload


ian remove
----------

remove package from a remote package repository.


ian binary-contents
-------------------

list files on generated binary packages.


ian show-generated
------------------

list all generated files


ian create
----------

Basic wizard to create a new debian package


ian lintian-fix
---------------

automatically try to fix some lintian issues (after a successful build).


Configuration
=============

ian requires you define some environment variables. An example:

DEBFULLNAME="John Doe"
DEBEMAIL=john.doe@email.com
DEBSIGN_KEYID=D0FE7AFB
DEBREPO_URL=john.doe@debian.repository.org/var/repo

The latter two are required only if you want upload you package to a remote Debian
repository.

ian can load these variables from a **~/.config/ian/config** if you have one.

FIXME: To do


hooks
=====

ian may execute user provided shell functions AFTER important events in the process. Allowed hooks are:

* ian-clean-hook
* ian-release-hook
* ian-build-start-hook
* ian-build-end-hook
* ian-install-hook

You may provide these functions in your **~/.config/ian/config** file.


Compiling i386 packages in a amd64 computer
===========================================

Create a i386 chroot::

  hello-2.9$ ian-386 jail-upgrade


Compile amd64 version::

  hello-2.9$ ian clean
  hello-2.9$ BUILDOPTIONS=-b ian build


Compile i386 version in its chroot::

  hello-2.9$ ian-386


Similar software
================

* buildtasks: 

** https://github.com/Jimdo/buildtasks 
** https://blog.codeship.com/using-docker-build-debian-packages/

.. Local Variables:
..  coding: utf-8
..  mode: flyspell
..  ispell-local-dictionary: "american"
.. End: