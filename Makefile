# Makefile

MWGDIR=~/.mwg
BINDIR=~/bin

.PHONY: all pack install
all:

install: $(MWGDIR) $(BINDIR) $(MWGDIR)/mwg.cygps.awk $(BINDIR)/p
$(MWGDIR):
	test -d $@ || mkdir $@
$(BINDIR):
	test -d $@ || mkdir $@
$(MWGDIR)/mwg.cygps.awk: cygps.awk
	cp -p $< $@
$(BINDIR)/p: cygps.sh
	cp -p $< $@

pack:
	cd .. && tar cavf mwg.cygps-src.tlz --exclude='*~' --exclude='*/backup/*' mwg.cygps-src
