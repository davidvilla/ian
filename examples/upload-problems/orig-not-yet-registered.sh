#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

hg revert debian/changelog
ian remove -y
echo 1 > content
ian release -yi
ian build -c
ian upload
