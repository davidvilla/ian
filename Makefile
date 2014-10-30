#!/usr/bin/make -f
# -*- coding:utf-8 -*-

DESTDIR?=~

FINAL=/usr/share/ian
BASE=$(DESTDIR)$(FINAL)
DOCDIR=$(DESTDIR)/usr/share/doc

clean:
	$(RM) $(shell find -name *~)

install:
	install -vd $(BASE)
	install -v -m 444 bash/*.sh  $(BASE)/
	install -v -m 555 bash/ian-packaging.sh $(BASE)

	install -vd $(DESTDIR)/usr/bin
