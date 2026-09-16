import AppKit
import ApplicationServices
import ServiceManagement

@MainActor
final class ProfileSwitcherAppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var profileItems: [NSStatusItem] = []
    private var utilityItem: NSStatusItem!
    private var profiles: [ChromeProfile] = []
    private let preferences = ProfileShortcutPreferences()
    private lazy var hotKeyRegistrar = GlobalHotKeyRegistrar { [weak self] profile in
        self?.activate(profile)
    }
    private var shortcutSettings: ShortcutSettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        utilityItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        utilityItem.button?.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: "Profile Switcher options")
        refreshProfileIcons()
    }

    private func refreshProfileIcons() {
        profileItems.forEach { NSStatusBar.system.removeStatusItem($0) }
        profileItems.removeAll()

        do {
            profiles = try ChromeProfileStore.load()
            // AppKit inserts each new status item to the left of the previous one.
            if preferences.showProfileIcons {
                profileItems = profiles.reversed().map(makeStatusItem)
            }
            _ = hotKeyRegistrar.register(profiles: profiles, shortcuts: preferences.shortcuts)
            utilityItem.menu = makeUtilityMenu()
        } catch {
            profiles = []
            _ = hotKeyRegistrar.register(profiles: [], shortcuts: [:])
            utilityItem.menu = makeUtilityMenu(error: error.localizedDescription)
        }
    }

    private func makeStatusItem(for profile: ChromeProfile) -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = item.button else { return item }
        button.image = ProfileAvatarRenderer.image(for: profile)
        button.imagePosition = .imageOnly
        button.toolTip = "Switch to or open \(profile.name)"
        button.identifier = NSUserInterfaceItemIdentifier(profile.directory)
        button.target = self
        button.action = #selector(selectProfile(_:))
        button.sendAction(on: .leftMouseUp)
        return item
    }

    private func makeUtilityMenu(error: String? = nil) -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        if let error {
            let item = NSMenuItem(title: error, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(.separator())
        }
        let refresh = NSMenuItem(title: "Refresh Profiles", action: #selector(refreshProfiles), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)
        let shortcuts = NSMenuItem(title: "Keyboard Shortcuts…", action: #selector(openShortcutSettings), keyEquivalent: "")
        shortcuts.target = self
        menu.addItem(shortcuts)
        let profileIcons = NSMenuItem(title: "Show Profile Icons", action: #selector(toggleProfileIcons(_:)), keyEquivalent: "")
        profileIcons.target = self
        profileIcons.state = preferences.showProfileIcons ? .on : .off
        menu.addItem(profileIcons)
        let settings = NSMenuItem(title: "Accessibility Settings…", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        settings.target = self
        menu.addItem(settings)
        let launchAtLogin = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchAtLogin.target = self
        launchAtLogin.state = launchAtLoginState
        menu.addItem(launchAtLogin)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Profile Switcher", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        return menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.items.first { $0.action == #selector(toggleLaunchAtLogin(_:)) }?.state = launchAtLoginState
    }

    @objc private func selectProfile(_ sender: NSStatusBarButton) {
        guard
            let directory = sender.identifier?.rawValue,
            let profile = profiles.first(where: { $0.directory == directory })
        else { return }

        activate(profile)
    }

    @objc private func refreshProfiles() { refreshProfileIcons() }

    @objc private func openShortcutSettings() {
        if let shortcutSettings, shortcutSettings.window?.isVisible == true {
            shortcutSettings.present()
            return
        }

        let controller = ShortcutSettingsWindowController(
            profiles: profiles,
            shortcuts: preferences.shortcuts,
            setShortcut: { [weak self] profile, shortcut in
                self?.setShortcut(shortcut, for: profile) ?? false
            }
        )
        shortcutSettings = controller
        controller.present()
    }

    @objc private func toggleProfileIcons(_ sender: NSMenuItem) {
        preferences.showProfileIcons.toggle()
        refreshProfileIcons()
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled || service.status == .requiresApproval {
                try service.unregister()
            } else {
                try service.register()
                if service.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                }
            }
            sender.state = launchAtLoginState
        } catch {
            show(error: "Launch at Login could not be changed: \(error.localizedDescription)")
        }
    }

    private var launchAtLoginState: NSControl.StateValue {
        switch SMAppService.mainApp.status {
        case .enabled: .on
        case .requiresApproval: .mixed
        default: .off
        }
    }

    private func setShortcut(_ shortcut: ProfileHotKey?, for profile: ChromeProfile) -> Bool {
        let previous = preferences.shortcuts[profile.directory]
        preferences.setShortcut(shortcut, for: profile.directory)
        let failures = hotKeyRegistrar.register(profiles: profiles, shortcuts: preferences.shortcuts)
        guard !failures.contains(profile.directory) else {
            preferences.setShortcut(previous, for: profile.directory)
            _ = hotKeyRegistrar.register(profiles: profiles, shortcuts: preferences.shortcuts)
            return false
        }
        return true
    }

    private func activate(_ profile: ChromeProfile) {
        do {
            try ChromeProfileActivator.activate(profile)
        } catch {
            show(error: error.localizedDescription)
        }
    }

    private func show(error: String) {
        NSApp.activate()
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.icon = NSImage(systemSymbolName: "person.2.circle.fill", accessibilityDescription: "Profile Switcher")
        alert.messageText = "Profile Switcher"
        alert.informativeText = error
        alert.runModal()
    }
}

if CommandLine.arguments.contains("--check-accessibility") {
    if AXIsProcessTrusted() {
        print("PASS: Profile Switcher is trusted for Accessibility")
        exit(0)
    } else {
        FileHandle.standardError.write(Data("FAIL: Profile Switcher is not trusted for Accessibility\n".utf8))
        exit(1)
    }
}

MainActor.assumeIsolated {
    let application = NSApplication.shared
    let delegate = ProfileSwitcherAppDelegate()
    application.delegate = delegate
    application.run()
}
