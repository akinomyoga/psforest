# -*- mode: makefile-gmake -*-

.PHONY: all
all:

ifeq ($(PREFIX),)
  PREFIX=$(HOME)/.mwg
endif
BINDIR:=$(PREFIX)/bin
SHARE:=$(PREFIX)/share/psforest
directories:= $(BINDIR) $(SHARE)

.PHONY: install
install: $(SHARE)/psforest.awk $(BINDIR)/psforest
$(SHARE)/psforest.awk: psforest.awk | $(SHARE)
	cp -p $< $@
$(BINDIR)/psforest: psforest.sh | $(BINDIR)
	sed 's|\./psforest\.awk|$(SHARE)/psforest.awk|' $< > $@ && chmod +x $@

.PHONY: dist
dist:
	DIR="$${PWD##*/}"; cd ..; tar cavf "$$DIR/dist/psforest.$$(date +'%Y%m%d').tar.xz" \
		--exclude='*~' --exclude='backup' \
		--exclude="./$${DIR}/dist" \
		--exclude="./$${DIR}/.git" \
		--exclude='*.exe' --exclude='*.obj' --exclude='*.o' \
		"./$${DIR}"

$(directories):
	mkdir -p $@
