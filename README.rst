===
ian
===

*simple tool for the lazy package maintainers*


in a glance
=========


```
#!shell

apt-get source hello
```



commands
========

summary:
  print information about the current directory Debian package.


orig: 
  create or download the .orig file

  backends:

  * orig-from-rule:  execute the rule "get-orig" in the debian/rules
  * orig-uscan:      download latest upstream with uscan
  * orig-from-local: generates .orig from current directory files


build:
  compile Debian sources to generate binary packages.

  * applies quilt patches if present
  * automatically install missing build depends

  backends:

  * build-standard: compile with dpkg-buildpackage
  * build-svn:      compile with svn-buildpackage

binary-contens: 
  list files on generated binary packages

clean:
  remove all generated files and artifacts

  * reverts quilt patches if present

  backends:

  * clean-common: remove deb, orig, changes, dsc, diff, upload, debian.tar.gz
  * clean-svn:    remove svn-buildpackage artifacts: tarballs/*, build-area/*
  * clean-uscan:  remove uscan downloaded files

install:
  installs all generated binary packages in the system.

upload:
  upload binary packages to a remote package repository

  * runs debsign and dupload

remove: 
  remove package from a remote package repository

.. Local Variables:
..  coding: utf-8
..  mode: flyspell
..  ispell-local-dictionary: "american"
.. End: