# -*- mode: makefile-gmake -*-

.PHONY: all
all:

ifeq ($(PREFIX),)
  PREFIX=$(HOME)/.mwg
endif
BINDIR:=$(PREFIX)/bin
SHARE:=$(PREFIX)/share/cygps
directories:= $(BINDIR) $(SHARE)

.PHONY: install
install: $(SHARE)/cygps.awk $(BINDIR)/cygps
$(SHARE)/cygps.awk: cygps.awk | $(SHARE)
	cp -p $< $@
$(BINDIR)/cygps: cygps.sh | $(BINDIR)
	sed 's|%share%|$(SHARE)|' $< > $@

.PHONY: dist
dist:
	DIR="$${PWD##*/}"; cd ..; tar cavf "$$DIR/dist/cygps.$$(date +'%Y%m%d').tar.xz" \
		--exclude='*~' --exclude='backup' \
		--exclude="./$${DIR}/dist" \
		--exclude="./$${DIR}/.git" \
		--exclude='*.exe' --exclude='*.obj' --exclude='*.o' \
		"./$${DIR}"

$(directories):
	mkdir -p $@
