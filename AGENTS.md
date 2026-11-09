# AGENTS.md

Single-file AppKit menu bar app (`DisplayToggle.swift`), built with `swiftc` by `build.sh` — no Xcode project, no SwiftPM, no dependencies.

- Build and install: `./build.sh` (writes `build/DisplayToggle.app`, copies it to `/Applications`).
- Check detection without touching any display: `build/DisplayToggle.app/Contents/MacOS/DisplayToggle --list`.
- Reload the running copy after a rebuild: `launchctl kickstart -k gui/$(id -u)/cc.hushcore.DisplayToggle` (if the login agent is installed), otherwise quit and reopen the app.

Toggling a display rearranges the user's windows. Don't disable displays to test a change unless the user asks; `--list` covers detection.

Invariants to keep:
- Never allow disabling the last active display.
- `applicationWillTerminate` re-enables every display the app turned off.
- Names of disabled displays live in `UserDefaults` under `disabledDisplayNames`; they're needed because disabled displays vanish from `NSScreen`.

`CGSConfigureDisplayEnabled` is private and bound with `@_silgen_name`. If a macOS update breaks it, the build still links but the call returns a non-success `CGError` (the app beeps).
