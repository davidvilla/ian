#!/bin/bash --
# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-

git checkout debian/changelog
ian remove -y

echo 1 > content
ian build -c
ian upload

echo 2 > content
ian build -c
ian upload

echo -e "\n-- OK ----------\n"

ian remove -y
