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
* **-l**: creates orig with "ian orig local"
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


Variables ``DEBPOOL`` and ``DEBSIGN_KEYID`` are required only if you want upload you package to a remote Debian
repository. ``DEBSIGN_KEYID`` is your GPG key fingerprint (keyID).

``ian`` can load these variables from a **~/.config/ian/config**.


hooks
=====

ian may execute user provided shell functions at important events in the process. Every command has four hooks,
named after it:

* ``ian-<cmd>-pre-hook``: before the command.
* ``ian-<cmd>-post-hook``: after the command, whatever it did.
* ``ian-<cmd>-success-hook``: after ``post``, only when the command succeeded.
* ``ian-<cmd>-fail-hook``: after ``post``, only when it failed.

For instance ``ian-build-pre-hook``, ``ian-upload-success-hook`` or ``ian-remove-fail-hook``.

Hooks also run when a command is run by another one: ``ian build`` runs those of ``orig`` (which runs those of
``clean``) and, with ``-i``, those of ``install``.

The commands that only show information have no hooks: ``help``, ``name``, ``summary``, ``config``,
``binary-contents``, ``pool-ls`` and ``ls``.

A hook cannot stop its command: its exit code is ignored. Each one runs in a subshell and in the package root
directory, where the commands run, so it may change directory or exit without affecting ian. Defining
``IAN_DISABLE_HOOKS`` disables all of them.

You may provide these functions in your **~/.config/ian** file or the by-project **.ian** file.


deprecated hooks
----------------

The hooks of previous versions of ian still run, in the place of the hook that replaces each one, warning that
they are deprecated. If both the deprecated hook and its replacement are defined, only the replacement runs and
ian warns that the deprecated one was discarded, so you can remove it.

=========================  ==========================
deprecated                 replaced by
=========================  ==========================
ian-clean-hook             ian-clean-post-hook
ian-release-hook           ian-release-post-hook
ian-build-hook             ian-build-post-hook
ian-build-start-hook       ian-build-pre-hook
ian-build-end-hook         ian-build-success-hook
ian-install-hook           ian-install-post-hook
ian-upload-start-hook      ian-upload-pre-hook
ian-upload-end-hook        ian-upload-success-hook
ian-remove-hook            ian-remove-post-hook
=========================  ==========================

Two of them do not run exactly where they used to: ``ian-build-start-hook`` now runs before the whole ``build``
command (the orig, the build dependencies), and not just before ``dpkg-buildpackage``; and ``ian-clean-hook``
after the ``clean`` command instead of at its end.


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


Claude Code plugin
==================

This repository is also a `Claude Code <https://claude.com/claude-code>`_ plugin. It provides
an ``ian`` skill that tells Claude how to use ian: which commands only read and which ones
change your system or the pool, how to avoid the interactive prompts (``release -y -m``,
``remove -y``, sudo, GPG), and the usual release workflow.

Install it from a Claude Code session::

  /plugin install ian --marketplace davidvilla/ian

On Claude Code versions older than 2.1.275, add the marketplace first::

  /plugin marketplace add davidvilla/ian
  /plugin install ian@ian

To try a local checkout, use its path as the marketplace::

  /plugin marketplace add ~/repos/ian

The skill is loaded automatically when you ask Claude to build, release, install or upload
a Debian package. Its source is at ``skills/ian/SKILL.md``.


FAQ
===

* **gpg stalls for a while, then says "Timeout"**

  *  gpg is asking for a password though gpg-agent. You may force tty asking adding ``pinentry-program /usr/bin/pinentry-tty`` to your ``~/.gnupg/gpg-agent.conf``. Also install package ``pinentry-tty``.
  

GPG setup
=========

You need a GPG key to sign and upload compiled debian packages. That's a brief recipe to create and publish your key.
Create key::

  $ gpg --gen-key
  
Key related files (and revocation certificate) are saved at ``./gnupg``. You may export your private key for secure. Save both (private key and revocation certificate) in a private and secure place until your death::

  $ gpg --export-secret-keys -a <your_key_id> > ~/private-key.asc
  
Your GPG public key must be uploaded to a key server::

  $ gpg --keyserver keys.openpgp.org --send-key <your_key_id>
  

Similar software
================

* https://github.com/Jimdo/buildtasks
* https://blog.codeship.com/using-docker-build-debian-packages/

.. Local Variables:
..  coding: utf-8
..  mode: flyspell
..  ispell-local-dictionary: "american"
.. End:
