define n


endef

.EXPORT_ALL_VARIABLES:

BETA=

ifeq (, $(VERSION))
VERSION=$(shell rg -o --no-filename 'MARKETING_VERSION = ([^;]+).+' -r '$$1' *.xcodeproj/project.pbxproj | head -1 | sd 'b\d+' '')
endif

ifneq (, $(BETA))
FULL_VERSION:=$(VERSION)b$(BETA)
else
FULL_VERSION:=$(VERSION)
endif

RELEASE_NOTES_FILES := $(wildcard ReleaseNotes/*.md)
ENV=Release
DERIVED_DATA_DIR=$(shell ls -td $$HOME/Library/Developer/Xcode/DerivedData/ZoomHider-* | head -1)

.PHONY: build upload release appcast setversion

print-%  : ; @echo $* = $($*)

build: SHELL=fish
build:
	make-app --build --devid --dmg -s ZoomHider -t ZoomHider -c Release --version $(VERSION)
	xcp /tmp/apps/ZoomHider-$(VERSION).dmg Releases/

upload:
	rsync -avzP Releases/*.{delta,dmg} hetzner:/static/lowtechguys/releases/ || true
	rsync -avz Releases/*.html hetzner:/static/lowtechguys/ReleaseNotes/
	rsync -avzP Releases/appcast.xml hetzner:/static/lowtechguys/zoomhider/
	cfcli -d lowtechguys.com purge

release:
	gh release create v$(VERSION) -F ReleaseNotes/$(VERSION).md "Releases/ZoomHider-$(VERSION).dmg#ZoomHider.dmg"

appcast: Releases/ZoomHider-$(FULL_VERSION).html
	rm Releases/ZoomHider.dmg || true
ifneq (, $(BETA))
	rm Releases/ZoomHider$(FULL_VERSION)*.delta >/dev/null 2>/dev/null || true
	generate_appcast --channel beta --maximum-versions 10 --link "https://lowtechguys.com/zoomhider" --full-release-notes-url "https://github.com/FuzzyIdeas/ZoomHider/releases" --release-notes-url-prefix https://files.lowtechguys.com/ReleaseNotes/ --download-url-prefix "https://files.lowtechguys.com/releases/" -o Releases/appcast.xml Releases
else
	rm Releases/ZoomHider$(FULL_VERSION)*.delta >/dev/null 2>/dev/null || true
	rm Releases/ZoomHider-*b*.dmg >/dev/null 2>/dev/null || true
	rm Releases/ZoomHider*b*.delta >/dev/null 2>/dev/null || true
	generate_appcast --maximum-versions 10 --link "https://lowtechguys.com/zoomhider" --full-release-notes-url "https://github.com/FuzzyIdeas/ZoomHider/releases" --release-notes-url-prefix https://files.lowtechguys.com/ReleaseNotes/ --download-url-prefix "https://files.lowtechguys.com/releases/" -o Releases/appcast.xml Releases
	cp Releases/ZoomHider-$(FULL_VERSION).dmg Releases/ZoomHider.dmg
endif


setversion: OLD_VERSION=$(shell rg -o --no-filename 'MARKETING_VERSION = ([^;]+).+' -r '$$1' *.xcodeproj/project.pbxproj | head -1)
setversion: SHELL=fish
setversion:
ifneq (, $(FULL_VERSION))
	sdf '((?:CURRENT_PROJECT|MARKETING)_VERSION) = $(OLD_VERSION);' '$$1 = $(FULL_VERSION);'
endif

Releases/ZoomHider-%.html: ReleaseNotes/$(VERSION)*.md
	@echo Compiling $^ to $@
ifneq (, $(BETA))
	pandoc -f gfm -o $@ --standalone --metadata title="ZoomHider $(FULL_VERSION) - Release Notes" --css https://files.lowtechguys.com/release.css $(shell ls -t ReleaseNotes/$(VERSION)*.md)
else
	pandoc -f gfm -o $@ --standalone --metadata title="ZoomHider $(FULL_VERSION) - Release Notes" --css https://files.lowtechguys.com/release.css ReleaseNotes/$(VERSION).md
endif
