#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

hg revert debian/changelog
echo 1 > content
ian release -qi
ian build -c
ian upload
echo 2 > content
ian build -c
ian upload
