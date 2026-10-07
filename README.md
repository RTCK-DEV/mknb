# mknb — Mac Keyboard Notification Backlight


**Blink your MacBook keyboard backlight as a notification.**

[日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

`mknb` slowly blinks the keyboard backlight (default: twice, ~8 seconds)
when something needs your attention — a finished build, a completed backup,
a long-running command. It also ships **MKNB.app**, a menu bar app for
manually controlling the keyboard backlight.

## Features

- CLI `mknb`: get/set brightness, toggle auto-brightness, blink, notify
- `mknb notify "Title" "body"` — Notification Center banner + blink
- Menu bar app: brightness slider, auto-brightness toggle, blink test,
  launch-at-login, live status (level / suppressed / saturated)
- English / 日本語 / 简体中文 (CLI follows `LANG`, app follows system language)
- No Accessibility permissions needed, no sudo, no dependencies

## Install

From [Releases](../../releases):

```sh
unzip mknb.zip
sudo install -m 755 mknb /usr/local/bin/   # or ~/bin, ~/.local/bin
xattr -d com.apple.quarantine mknb          # if downloaded via browser
```

For the app: unzip `MKNB.app.zip`, move `MKNB.app` to `/Applications`.

> **Launch at login**: enable the toggle from the copy installed in
> `/Applications` (or a stable path). Registering from `build/` or a folder
> that gets rebuilt/deleted makes macOS silently drop the login item.

## Usage

```sh
mknb get                          # current brightness (0.0-1.0)
mknb set 0.5                      # set brightness
mknb auto on                      # ambient-light auto adjustment
mknb status                       # brightness, level(nits), suppressed, saturated
mknb blink                        # slow blink x2 (fade 1.4s + hold 0.5s)
mknb blink 3 1.0 0.3              # 3 blinks, 1.0s fade, 0.3s hold
mknb notify "Build" "finished"    # notification + blink

# examples
make && mknb notify "Build" "succeeded"
sleep 300 && mknb blink           # 5-minute timer that flashes your keys
```

## How it works

macOS has no public API for keyboard backlight. `mknb` talks to the
private `CoreBrightness.framework`, the same framework System Settings uses.

On modern macOS, the convenience class `KeyboardBrightnessClient` accepts
`setBrightness:forKeyboard:` writes that update the stored preference but
never reach the LED. MKNB instead writes the `KeyboardBacklightBrightness`
property through the generic `BrightnessSystemClient` interface, which is the
path that actually propagates to the hardware (`KeyboardBacklightLevel`, in
nits). While blinking, ambient-light auto-adjustment and idle dimming are
temporarily suspended, then restored — and your original brightness fades
back at the end.

> Note: private API — may break in future macOS versions. Verified on
> macOS 27 (Mac17,9). If it stops working, `mknb status` shows whether
> `level` still tracks `brightness`.

## Build

Requires Xcode Command Line Tools (`xcode-select --install`).

```sh
./scripts/build.sh        # builds CLI + MKNB.app into build/
make install              # install CLI to ~/.local/bin
```

## License

MIT
