# DisplayToggle

A minimal macOS menu bar app that turns connected displays off and on without unplugging them. A disabled display disappears from macOS entirely: windows move off it and the menu bar and Dock can't land on it.

Click the menu bar icon to see every display with a checkmark if it's on, then click one to toggle it. **Turn On All Displays** restores everything, and quitting the app does the same. The last active display can't be turned off.

## Build and install

Requires macOS 13+ and the Xcode command line tools.

```bash
./build.sh
```

This compiles `DisplayToggle.swift`, ad-hoc signs the bundle, and installs it to `/Applications/DisplayToggle.app`.

## Start at login

```bash
cp cc.hushcore.DisplayToggle.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/cc.hushcore.DisplayToggle.plist
```

To remove it:

```bash
launchctl bootout gui/$(id -u)/cc.hushcore.DisplayToggle && rm ~/Library/LaunchAgents/cc.hushcore.DisplayToggle.plist
```

## How it works

macOS has no public API for disabling a display. DisplayToggle calls the private `CGSConfigureDisplayEnabled` inside a `CGBeginDisplayConfiguration` transaction, the same mechanism larger display utilities use. Being private, it may break in a future macOS release.

Disabled displays drop out of `NSScreen`, so their names are kept in `UserDefaults`. Display IDs can change after a reboot or reconnect; if a display doesn't come back, unplug and replug it.

## License

[MIT](LICENSE)
