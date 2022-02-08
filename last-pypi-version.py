#!/usr/bin/env python
# -*- coding: utf-8; mode: python; -*-

import sys
import json
import urllib2
from distutils.version import StrictVersion


def versions(package_name):
    try:
        url = "https://pypi.python.org/pypi/%s/json" % (package_name,)
        data = json.load(urllib2.urlopen(urllib2.Request(url)))
        versions = data["releases"].keys()
        versions.sort(key=StrictVersion)
        return versions
    except urllib2.HTTPError:
        return [None]


if len(sys.argv) != 2:
    print("usage: {} <package-name>".format(sys.argv[0]))
    sys.exit(1)

print(versions(sys.argv[1])[-1])
