#!/usr/bin/make -f
# -*- coding:utf-8 -*-

DESTDIR?=~

FINAL=/usr/share/ian
BASE=$(DESTDIR)$(FINAL)
DOCDIR=$(DESTDIR)/usr/share/doc

clean:
	$(RM) $(shell find -name *~)

tests:
	test/shell-commodity-tests.sh
	test/ian-tests.sh

install:
	install -vd $(BASE)
	install -v -m 444 shell-commodity.sh  $(BASE)/
	install -v -m 444 unittest.sh  $(BASE)/
	install -v -m 555 ian*.sh $(BASE)
	install -v -m 444 vagrant/* $(BASE)/

	install -vd $(DESTDIR)/usr/bin
	install -v -m 555 last-pypi-version.py $(DESTDIR)/usr/bin/last-pypi-version
	install -v -m 555 version-summary.sh $(DESTDIR)/usr/bin/version-summary

	install -vd $(DESTDIR)/usr/share/bash-completion/completions
	install -v -m 644 completion $(DESTDIR)/usr/share/bash-completion/completions/ian

	install -vd $(DESTDIR)/usr/share/man/man1
	install ian.1 $(DESTDIR)/usr/share/man/man1
