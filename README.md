# Matataki (瞬き)

**Blink your MacBook keyboard backlight as a notification.**

[日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

`matataki` slowly blinks the keyboard backlight (default: twice, ~8 seconds)
when something needs your attention — a finished build, a completed backup,
a long-running command. It also ships **Matataki.app**, a menu bar app for
manually controlling the keyboard backlight.

## Features

- CLI `matataki`: get/set brightness, toggle auto-brightness, blink, notify
- `matataki notify "Title" "body"` — Notification Center banner + blink
- Menu bar app: brightness slider, auto-brightness toggle, blink test,
  launch-at-login, live status (level / suppressed / saturated)
- English / 日本語 / 简体中文 (CLI follows `LANG`, app follows system language)
- No Accessibility permissions needed, no sudo, no dependencies

## Install

From [Releases](../../releases):

```sh
unzip matataki.zip
sudo install -m 755 matataki /usr/local/bin/   # or ~/bin, ~/.local/bin
xattr -d com.apple.quarantine matataki          # if downloaded via browser
```

For the app: unzip `Matataki.app.zip`, move `Matataki.app` to `/Applications`.

## Usage

```sh
matataki get                          # current brightness (0.0-1.0)
matataki set 0.5                      # set brightness
matataki auto on                      # ambient-light auto adjustment
matataki status                       # brightness, level(nits), suppressed, saturated
matataki blink                        # slow blink x2 (fade 1.4s + hold 0.5s)
matataki blink 3 1.0 0.3              # 3 blinks, 1.0s fade, 0.3s hold
matataki notify "Build" "finished"    # notification + blink

# examples
make && matataki notify "Build" "succeeded"
sleep 300 && matataki blink           # 5-minute timer that flashes your keys
```

## How it works

macOS has no public API for keyboard backlight. `matataki` talks to the
private `CoreBrightness.framework`, the same framework System Settings uses.

On modern macOS, the convenience class `KeyboardBrightnessClient` accepts
`setBrightness:forKeyboard:` writes that update the stored preference but
never reach the LED. Matataki instead writes the `KeyboardBacklightBrightness`
property through the generic `BrightnessSystemClient` interface, which is the
path that actually propagates to the hardware (`KeyboardBacklightLevel`, in
nits). While blinking, ambient-light auto-adjustment and idle dimming are
temporarily suspended, then restored — and your original brightness fades
back at the end.

> Note: private API — may break in future macOS versions. Verified on
> macOS 27 (Mac17,9). If it stops working, `matataki status` shows whether
> `level` still tracks `brightness`.

## Build

Requires Xcode Command Line Tools (`xcode-select --install`).

```sh
./scripts/build.sh        # builds CLI + Matataki.app into build/
make install              # install CLI to ~/.local/bin
```

## License

MIT
