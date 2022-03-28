define n


endef

.EXPORT_ALL_VARIABLES:

SCHEME=ZoomHider
ENV=Release
DISABLE_NOTARIZATION := ${DISABLE_NOTARIZATION}

CHANGELOG.md: $(RELEASE_NOTES_FILES)
	tail -n +1 `ls -r ReleaseNotes/*.md` | sed -E 's/==> ReleaseNotes\/(.+)\.md <==/# \1/g' > CHANGELOG.md

Releases/CHANGELOG.html: CHANGELOG.md
	@echo Compiling $< to $@
	@md2html --github -o $@ $<

changelog: Releases/CHANGELOG.html

release: changelog
	echo "$(VERSION)" > /tmp/release_file_$(VERSION).md
	echo "" >> /tmp/release_file_$(VERSION).md
	echo "" >> /tmp/release_file_$(VERSION).md
	cat ReleaseNotes/$(VERSION).md >> /tmp/release_file_$(VERSION).md
	gh release create v$(VERSION) -F /tmp/release_file_$(VERSION).md "Releases/$(SCHEME)-$(VERSION).zip#$(SCHEME).zip"

setversion: OLD_VERSION=$(shell xcodebuild -scheme "$(SCHEME)" -configuration $(ENV) -showBuildSettings -json 2>/dev/null | jq -r .buildSettings.MARKETING_VERSION)
setversion:
ifneq (, $(VERSION))
	rg -l 'VERSION = "?$(OLD_VERSION)"?' && sed -E -i .bkp 's/VERSION = "?$(OLD_VERSION)"?/VERSION = $(VERSION)/g' $$(rg -l 'VERSION = "?$(OLD_VERSION)"?')
endif

clean:
	xcodebuild -scheme "$(SCHEME)" -configuration $(ENV) ONLY_ACTIVE_ARCH=NO clean

build: BEAUTIFY=1
build: ONLY_ACTIVE_ARCH=NO
build: setversion
ifneq ($(BEAUTIFY),0)
	xcodebuild -scheme "$(SCHEME)" -configuration $(ENV) ONLY_ACTIVE_ARCH=$(ONLY_ACTIVE_ARCH) | tee /tmp/$(SCHEME)-$(ENV)-build.log | xcbeautify
else
	xcodebuild -scheme "$(SCHEME)" -configuration $(ENV) ONLY_ACTIVE_ARCH=$(ONLY_ACTIVE_ARCH) | tee /tmp/$(SCHEME)-$(ENV)-build.log
endif

appcast: GENERATE_APPCAST=$(shell dirname $$(dirname $$(dirname $$(xcodebuild -scheme "$(SCHEME)" -configuration $(ENV) -showBuildSettings -json 2>/dev/null | jq -r .[0].buildSettings.BUILT_PRODUCTS_DIR))))/SourcePackages/artifacts/sparkle/bin/generate_appcast
appcast: Releases/$(SCHEME)-$(VERSION).html Releases/CHANGELOG.html
	$(GENERATE_APPCAST) Releases/

Releases/$(SCHEME)-%.html: ReleaseNotes/%.md
	@echo Compiling $< to $@
	@md2html --github -o $@ $<

upload:
	rsync -avzP Releases/ darkwoods:/static/lowtechguys/$(SCHEME)
	cfcli -d lowtechguys.com purge

