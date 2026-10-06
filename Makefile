PREFIX ?= ~/.local/bin

.PHONY: all cli app install clean

all: cli app
	./scripts/build.sh

cli:
	mkdir -p build
	swiftc -O -o build/matataki Sources/Shared/Backlight.swift Sources/CLI/main.swift
	codesign -s - --force build/matataki 2>/dev/null || true

app:
	./scripts/build.sh

install: cli
	mkdir -p $(PREFIX)
	install -m 755 build/matataki $(PREFIX)/matataki
	@echo "installed to $(PREFIX)/matataki"

clean:
	rm -rf build
