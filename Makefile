PREFIX ?= ~/.local/bin

.PHONY: all cli app install clean

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

clean:
	rm -rf build
