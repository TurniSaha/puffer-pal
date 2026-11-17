# Command Line Tools ship Swift Testing outside the default search path.
CLT_FW := /Library/Developer/CommandLineTools/Library/Developer/Frameworks
CLT_LIB := /Library/Developer/CommandLineTools/Library/Developer/usr/lib
TEST_FLAGS := -Xswiftc -Xfrontend -Xswiftc -disable-cross-import-overlays -Xswiftc -F -Xswiftc $(CLT_FW) -Xlinker -F -Xlinker $(CLT_FW) \
	-Xlinker -rpath -Xlinker $(CLT_FW) -Xlinker -rpath -Xlinker $(CLT_LIB)

.PHONY: test app install plugin-install plugin-check

test:
	cd mac && swift test $(TEST_FLAGS)

app:
	mac/scripts/bundle.sh

install: app plugin-install
	mkdir -p "$(HOME)/Applications"
	rm -rf "$(HOME)/Applications/Puffer Pal.app"
	cp -R "mac/build/Puffer Pal.app" "$(HOME)/Applications/"

# Adds this repo as a local plugin marketplace the first time, refreshes it after that.
plugin-install:
	claude plugin marketplace update puffer-pal || claude plugin marketplace add "$(CURDIR)"
	claude plugin update puffer-pal@puffer-pal || claude plugin install puffer-pal@puffer-pal

plugin-check:
	claude plugin validate claude-plugin
	claude plugin test claude-plugin
