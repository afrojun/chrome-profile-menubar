import AppKit

@MainActor
final class ShortcutSettingsWindowController: NSWindowController {
    private var shortcuts: [String: ProfileHotKey]
    private let setShortcut: (ChromeProfile, ProfileHotKey?) -> Bool

    init(
        profiles: [ChromeProfile],
        shortcuts: [String: ProfileHotKey],
        setShortcut: @escaping (ChromeProfile, ProfileHotKey?) -> Bool
    ) {
        self.shortcuts = shortcuts
        self.setShortcut = setShortcut

        let contentWidth: CGFloat = 420
        let rowHeight: CGFloat = 40
        let contentHeight = 94 + rowHeight * CGFloat(profiles.count)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: contentWidth, height: contentHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Keyboard Shortcuts"
        window.isReleasedWhenClosed = false
        super.init(window: window)

        window.contentView = Self.makeContentView(
            profiles: profiles,
            shortcuts: shortcuts,
            onChange: { [weak self] profile, shortcut in
                self?.update(shortcut, for: profile) ?? false
            }
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present() {
        NSApp.activate()
        window?.center()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    private func update(_ shortcut: ProfileHotKey?, for profile: ChromeProfile) -> Bool {
        if let shortcut, shortcuts.contains(where: { directory, assigned in
            directory != profile.directory && assigned == shortcut
        }) {
            showUnavailable("That shortcut is already assigned to another profile.")
            return false
        }
        guard setShortcut(profile, shortcut) else {
            showUnavailable("Another app or macOS is already using that shortcut.")
            return false
        }

        shortcuts[profile.directory] = shortcut
        return true
    }

    private func showUnavailable(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Shortcut unavailable"
        alert.informativeText = message
        if let window { alert.beginSheetModal(for: window) }
    }

    private static func makeContentView(
        profiles: [ChromeProfile],
        shortcuts: [String: ProfileHotKey],
        onChange: @escaping (ChromeProfile, ProfileHotKey?) -> Bool
    ) -> NSView {
        let content = NSView()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        let guidance = NSTextField(wrappingLabelWithString: "Click a profile’s shortcut, then press the keys you want to use. Press Delete to clear it.")
        guidance.textColor = .secondaryLabelColor
        stack.addArrangedSubview(guidance)

        for profile in profiles {
            let avatar = NSImageView(image: ProfileAvatarRenderer.image(for: profile, size: 28))
            avatar.imageScaling = .scaleProportionallyUpOrDown
            avatar.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                avatar.widthAnchor.constraint(equalToConstant: 28),
                avatar.heightAnchor.constraint(equalToConstant: 28),
            ])

            let name = NSTextField(labelWithString: profile.name)
            name.lineBreakMode = .byTruncatingTail
            name.setContentHuggingPriority(.defaultLow, for: .horizontal)

            let recorder = ShortcutRecorderButton(shortcut: shortcuts[profile.directory]) { shortcut in
                onChange(profile, shortcut)
            }
            recorder.translatesAutoresizingMaskIntoConstraints = false
            recorder.widthAnchor.constraint(equalToConstant: 136).isActive = true

            let row = NSStackView(views: [avatar, name, recorder])
            row.orientation = .horizontal
            row.alignment = .centerY
            row.spacing = 10
            row.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -18),
            guidance.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
        return content
    }
}

@MainActor
private final class ShortcutRecorderButton: NSButton {
    private var shortcut: ProfileHotKey?
    private let onChange: (ProfileHotKey?) -> Bool
    private var eventMonitor: Any?

    init(shortcut: ProfileHotKey?, onChange: @escaping (ProfileHotKey?) -> Bool) {
        self.shortcut = shortcut
        self.onChange = onChange
        super.init(frame: .zero)
        bezelStyle = .rounded
        target = self
        action = #selector(beginRecording)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResignKey(_:)),
            name: NSWindow.didResignKeyNotification,
            object: nil
        )
        updateTitle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func beginRecording() {
        title = "Type shortcut…"
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.record(event)
            return nil
        }
    }

    @objc private func windowDidResignKey(_ notification: Notification) {
        guard notification.object as? NSWindow === window else { return }
        finishRecording()
    }

    private func record(_ event: NSEvent) {
        if event.keyCode == 53 {
            finishRecording()
            return
        }
        if event.keyCode == 51 || event.keyCode == 117 {
            if onChange(nil) { shortcut = nil }
            finishRecording()
            return
        }
        guard let newShortcut = ProfileHotKey(event: event) else {
            NSSound.beep()
            return
        }
        if onChange(newShortcut) { shortcut = newShortcut }
        finishRecording()
    }

    private func finishRecording() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        updateTitle()
    }

    private func updateTitle() {
        title = shortcut?.displayName ?? "Record Shortcut"
    }
}
