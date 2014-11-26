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

	install -vd $(DESTDIR)/etc/schroot/chroot.d/
	install -v -m 600 schroot/ian $(DESTDIR)/etc/schroot/chroot.d/ian

	install -vd $(DESTDIR)/etc/schroot/ian/
	install -v -m 644 schroot/fstab $(DESTDIR)/etc/schroot/ian/fstab

	install -vd $(DESTDIR)/usr/bin

	install -vd $(DESTDIR)/etc/bash_completion.d/
	install -v -m 644 completion $(DESTDIR)/etc/bash_completion.d/ian
