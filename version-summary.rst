================
version-summary
================

----------------------------------------------------------------------------
show a package version as seen by setup.py, PyPI and the Debian repository
----------------------------------------------------------------------------

:Author: David Villa Alises
:date:   2026-08-04
:Manual section: 1

SYNOPSIS
========

``version-summary``

DESCRIPTION
===========

Run from the root of a project checkout, ``version-summary`` prints
the version reported by ``setup.py --version``, by PyPI (via
``last-pypi-version``\ (1)), and, when a ``debian`` directory is
present, by ``debian/changelog`` and by the candidate version in the
configured APT repository.

See https://bitbucket.org/DavidVilla/ian/src/tip/README.rst


COPYRIGHT
=========

Copyright © 2012-2026 David Villa Alises

This manual page was written for the Debian(TM) distribution because
the original program does not have a manual page. Permission is
granted to copy, distribute and/or modify this document under the
terms of the GNU General Public License, Version 3 or any later
version published by the Free Software Foundation.

On Debian systems, the complete text of the GNU General Public
License can be found in /usr/share/common-licenses/GPL.
