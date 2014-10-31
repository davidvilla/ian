===
ian
===

*simple tool for the lazy package maintainers*


in a glance
===========

Compiling a simple package with **ian**::

  $ apt-get source hello
  $ cd hello-2.9
  hello-2.9$ ian-build
  ... a lot of stuff ...
  hello-2.9$ ls -la ../hello_*
  -rw-r--r--  1 david david   1798 oct 31 16:02 ../hello_2.9-1_amd64.changes
  -rw-r--r--  1 david david  50462 oct 31 16:02 ../hello_2.9-1_amd64.deb
  -rw-r--r--  1 david david   8584 oct 31 16:02 ../hello_2.9-1.debian.tar.xz
  -rw-r--r--  1 david david    793 oct 31 16:02 ../hello_2.9-1.dsc
  -rw-r--r--  1 david david 730504 oct 31 16:02 ../hello_2.9.orig.tar.gz


commands
========

summary
-------

prints information about the current directory Debian package::

  hello-2.9$ ian-summary 
  source:              hello
  uptream:             2.9
  version:             2.9-1
  orig:                hello_2.9.orig.tar.gz
  changes:             hello_2.9-1_amd64.changes
  binaries:            hello
  pkg vcs:             none


orig
----

create or download the .orig file

backends:

* orig-from-rule:  execute the rule "get-orig" in the debian/rules
* orig-uscan:      download latest upstream with uscan
* orig-from-local: generates .orig from current directory files


build
-----

compiles Debian sources to generate binary packages.

* applies quilt patches if present
* automatically install missing build depends

backends:

* build-standard: compile with dpkg-buildpackage
* build-svn:      compile with svn-buildpackage


binary-contens
--------------

list files on generated binary packages

clean
-----

removes all generated files and artifacts

* reverts quilt patches if present

backends:

* clean-common: remove deb, orig, changes, dsc, diff, upload, debian.tar.gz
* clean-svn:    remove svn-buildpackage artifacts: tarballs/*, build-area/*
* clean-uscan:  remove uscan downloaded files

install
-------

installs all generated binary packages in the system.

upload
------

upload binary packages to a remote package repository

* runs debsign and dupload

remove
------

remove package from a remote package repository

.. Local Variables:
..  coding: utf-8
..  mode: flyspell
..  ispell-local-dictionary: "american"
.. End: