VERSION=0.1
PACKAGE=PerfORate
RIFT=/c/games/RIFT Game/Interface/AddOns

package:
	rm -rf $(PACKAGE)
	mkdir $(PACKAGE)
	rm -f $(PACKAGE)-$(VERSION).zip
	sed -e "s/VERSION/$(VERSION)/" < RiftAddon.toc > $(PACKAGE)/RiftAddon.toc
	sed -e "s/VERSION/$(VERSION)/" < $(PACKAGE).lua > $(PACKAGE)/$(PACKAGE).lua
	cp -r LibGetOpt $(PACKAGE)/.
	cp *.txt $(PACKAGE)/.

release: package
	zip -r $(PACKAGE)-$(VERSION).zip $(PACKAGE)

install: package
	mkdir -p "$(RIFT)"/$(PACKAGE)
	cp -r $(PACKAGE)/* "$(RIFT)"/$(PACKAGE)
