#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

app=build/DisplayToggle.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"

swiftc -O -o "$app/Contents/MacOS/DisplayToggle" DisplayToggle.swift

cat > "$app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>DisplayToggle</string>
    <key>CFBundleIdentifier</key><string>cc.hushcore.DisplayToggle</string>
    <key>CFBundleExecutable</key><string>DisplayToggle</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
EOF

codesign --force --sign - "$app"

rm -rf /Applications/DisplayToggle.app
cp -R "$app" /Applications/
echo "Installed /Applications/DisplayToggle.app"
