import AppKit
import CoreGraphics

// Private CoreGraphics call that detaches a display from the window server without unplugging it.
// It is the same mechanism BetterDisplay and similar tools use; there is no public equivalent.
@_silgen_name("CGSConfigureDisplayEnabled")
func CGSConfigureDisplayEnabled(_ config: CGDisplayConfigRef, _ display: CGDirectDisplayID, _ enabled: Bool) -> CGError

struct Display {
    let id: CGDirectDisplayID
    let name: String
    let active: Bool
}

enum Displays {
    // Disabled displays drop out of NSScreen and the active list, so their names are remembered here.
    private static let namesKey = "disabledDisplayNames"

    static var disabledNames: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: namesKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: namesKey) }
    }

    static func list() -> [Display] {
        var count: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &count)
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetOnlineDisplayList(count, &ids, &count)

        var names: [CGDirectDisplayID: String] = [:]
        for screen in NSScreen.screens {
            if let n = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
                names[n.uint32Value] = screen.localizedName
            }
        }
        let remembered = disabledNames

        var seen = Set<CGDirectDisplayID>()
        var result: [Display] = []
        for id in ids.prefix(Int(count)) {
            seen.insert(id)
            let active = CGDisplayIsActive(id) != 0
            let name = names[id] ?? remembered[String(id)] ?? "Display \(id)"
            result.append(Display(id: id, name: name, active: active))
        }
        for (key, name) in remembered {
            if let id = CGDirectDisplayID(key), !seen.contains(id) {
                result.append(Display(id: id, name: name, active: false))
            }
        }
        return result.sorted { $0.name < $1.name }
    }

    @discardableResult
    static func setEnabled(_ display: Display, _ enabled: Bool) -> Bool {
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let config else { return false }
        guard CGSConfigureDisplayEnabled(config, display.id, enabled) == .success else {
            CGCancelDisplayConfiguration(config)
            return false
        }
        guard CGCompleteDisplayConfiguration(config, .permanently) == .success else { return false }

        var names = disabledNames
        names[String(display.id)] = enabled ? nil : display.name
        disabledNames = names
        return true
    }

    static func enableAll() {
        for d in list() where !d.active { setEnabled(d, true) }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.button?.image = NSImage(systemSymbolName: "display.2", accessibilityDescription: "Displays")
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let displays = Displays.list()
        let activeCount = displays.filter(\.active).count

        for d in displays {
            let item = NSMenuItem(title: d.name, action: #selector(toggle(_:)), keyEquivalent: "")
            item.target = self
            item.state = d.active ? .on : .off
            item.representedObject = d
            // Never allow turning off the last active display; there would be no way back.
            item.isEnabled = !(d.active && activeCount == 1)
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let all = NSMenuItem(title: "Turn On All Displays", action: #selector(enableAll), keyEquivalent: "a")
        all.target = self
        all.isEnabled = activeCount < displays.count
        menu.addItem(all)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func toggle(_ sender: NSMenuItem) {
        guard let d = sender.representedObject as? Display else { return }
        if !Displays.setEnabled(d, !d.active) {
            NSSound.beep()
        }
    }

    @objc private func enableAll() {
        Displays.enableAll()
    }

    func applicationWillTerminate(_ notification: Notification) {
        Displays.enableAll()
    }
}

if CommandLine.arguments.contains("--list") {
    _ = NSApplication.shared
    for d in Displays.list() {
        print("\(d.id)\t\(d.active ? "on " : "off")\t\(d.name)")
    }
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
