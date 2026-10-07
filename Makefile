PREFIX ?= ~/.local/bin

.PHONY: all cli app install install-app clean

all: cli app
	./scripts/build.sh

cli:
	mkdir -p build
	swiftc -O -o build/mknb Sources/Shared/Backlight.swift Sources/CLI/main.swift
	codesign -s - --force build/mknb 2>/dev/null || true

app:
	./scripts/build.sh

install: cli
	mkdir -p $(PREFIX)
	install -m 755 build/mknb $(PREFIX)/mknb
	@echo "installed to $(PREFIX)/mknb"

install-app: app
	-pkill -x MKNB || true
	rm -rf /Applications/MKNB.app
	cp -R build/MKNB.app /Applications/MKNB.app
	@echo "installed to /Applications/MKNB.app — launch it and toggle 'Launch at login' there"

clean:
	rm -rf build
