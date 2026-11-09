#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

app=build/DisplayToggle.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"

for arch in arm64 x86_64; do
    swiftc -O -target "$arch-apple-macos13.0" -o "build/DisplayToggle-$arch" DisplayToggle.swift
done
lipo -create -output "$app/Contents/MacOS/DisplayToggle" build/DisplayToggle-arm64 build/DisplayToggle-x86_64

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
ditto -c -k --keepParent "$app" build/DisplayToggle.zip

rm -rf /Applications/DisplayToggle.app
cp -R "$app" /Applications/
echo "Installed /Applications/DisplayToggle.app"
