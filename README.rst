===
ian
===

*simple tool for lazy Debian package maintainers*

``ìan`` is essentially a frontend for several official Debian packaging tools.


at a glance
===========

Compiling a simple package with **ian**::

  $ apt source hello
  $ cd hello-2.10
  hello-2.10$ ian build -f
  ... a lot of stuff ...
  hello-2.10$ ls -la ../hello_*
  -rw-r--r--  1 david david   1798 oct 31 16:02 ../hello_2.10-2_amd64.changes
  -rw-r--r--  1 david david  50462 oct 31 16:02 ../hello_2.10-2_amd64.deb
  -rw-r--r--  1 david david   8584 oct 31 16:02 ../hello_2.10-2.debian.tar.gz
  -rw-r--r--  1 david david    793 oct 31 16:02 ../hello_2.10-2.dsc
  -rw-r--r--  1 david david 730504 oct 31 16:02 ../hello_2.10.orig.tar.gz


**NOTE:** Your user should be a "sudoer" to easly complete several ``ian`` tasks.


commands
========


ian help [command]
------------------

show help about the specified command.

if you just exec ``ian help``, you get a command summary::



ian summary
-----------

prints information about the current directory Debian package::

  hello-2.10$ ian summary
  source:              hello
  upstream:            2.10
  watch:               2.10
  version:             2.10-2
  orig:                ../hello_2.10.orig.tar.gz
  orig methods:        uscan from-local
  changes:             ../hello_2.10-2_amd64.changes
  binaries:            hello
  pkg vcs:             none


ian orig
--------

create or download the .orig file.

**ian** chooses between these backends (all of them are commands too):

* orig-uscan:      download latest upstream with ``uscan``
* orig-from-rule:  execute the rule "get-orig" in the debian/rules
* orig-from-local: generates .orig from current directory files


ian build
---------

compiles Debian sources to generate binary packages.

* applies **quilt** patches if present
* automatically install missing build depends

**ian** chooses between these backends:

* build-standard: compile with dpkg-buildpackage
* build-svn:      compile with svn-buildpackage

there are several available options:

* **-b**: skip 'source' target. See 'dpkg-buildpackage -b'
* **-c**: run "ian clean" before "build"
* **-f**: force build
* **-i**: run "ian install" after "build"
* **-l**: creates orig with "ian orig-from-local"
* **-m**: merge ./debian with upstream .orig. bypassing directory contents
* **-s**: include full source. See 'dpkg-genchanges -sa'


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

* **-i**: increment final version component (like 'dch -i')
* **-y**: do not ask for release comments
* **-m** message: release message for debian/changelog entry


ian release-date
----------------

use a date based version format for the new package.

* **-i**: increment final version component (like 'dch -i')
* **-y**: do not ask for release comments
* **-m** message: release message for debian/changelog entry


ian upload
----------

upload binary packages to the configured package repository.

* run ``debsign``
* configure and run ``dupload``


ian remove
----------

remove package from the configured package repository.

* **-y**: do not ask for confirmation


ian binary-contents
-------------------

list files on generated binary packages.


ian ls
------

list all generated files


ian create
----------

very basic wizard to create a new debian package


ian lintian-fix
---------------

automatically try to fix some common lintian issues (after a successful build).


Configuration
=============

ian requires you define some environment variables. An example::

  DEBFULLNAME="John Doe"
  DEBEMAIL=john.doe@email.com
  DEBSIGN_KEYID=D0FE7AFB
  DEBPOOL=john.doe@debian.repository.org/var/repo


The latter two are required only if you want upload you package to a remote Debian
repository.

``ian`` can load these variables from a **~/.config/ian/config**.


hooks
=====

ian may execute user provided shell functions at important events in the process. Allowed hooks are:

* ian-clean-hook
* ian-release-hook
* ian-build-start-hook
* ian-build-end-hook
* ian-install-hook
* ian-upload-start-hook
* ian-run ian-upload-end-hook
* ian-run ian-remove-hook

You may provide these functions in your **~/.config/ian** file or the by-project **.ian** file.


Compiling i386 packages in an amd64 computer
===========================================

::

  $ ian vagrant-gen-files
  ian: generated: Vagrantfile playbook.yml

  $ ian vagrant-build
  vagrant up --provision amd64
  vagrant ssh amd64 -c "cd /vagrant/<package-directory>; ian build -m"
  vagrant up --provision i386
  vagrant ssh i386 -c "cd /vagrant/<package-directory>; ian build -bm"

  $ ian vagrant-clean


Sign and upload externally compiled packages
==============================

You may upload binaries compiled in a different architecture (ie: RPi armhf) from your desktop computer. You need:

* The same ``debian`` directory and same ``changelog`` version
* Package compiled files in parent directory.

::

  foo/
    mypackage_0.20201223.orig.tar.gz
    mypackage_0.20201223-1_armhf.buildinfo
    mypackage_0.20201223-1_armhf.changes
    mypackage_0.20201223-1_armhf.deb
    mypackage_0.20201223-1_armhf.upload
    mypackage_0.20201223-1.debian.tar.gz
    mypackage_0.20201223-1.dsc
    mypackage_0.20201223.orig.tar.gz
    mypackage/
      debian/
           
Then, at your desktop (amd64), just upload indicating package architecture::

  foo/mypackage$ ian upload armhf


FAQ
===

* **gpg stalls for a while, then says "Timeout"**

  *  gpg is asking for a password though gpg-agent. You may force tty asking adding ``pinentry-program /usr/bin/pinentry-tty`` to your ``~/.gnupg/gpg-agent.conf``. Also install pinentry-tty package.
  


Similar software
================

* https://github.com/Jimdo/buildtasks
* https://blog.codeship.com/using-docker-build-debian-packages/

.. Local Variables:
..  coding: utf-8
..  mode: flyspell
..  ispell-local-dictionary: "american"
.. End:
