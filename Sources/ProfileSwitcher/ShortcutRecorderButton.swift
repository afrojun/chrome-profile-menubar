import AppKit

@MainActor
final class ShortcutRecorderButton: NSButton {
    private static weak var active: ShortcutRecorderButton?

    private var shortcut: ProfileHotKey?
    private let onChange: (ProfileHotKey?) -> String?
    private let onFeedback: (String?, Bool) -> Void
    private var eventMonitor: Any?

    init(
        profileName: String,
        shortcut: ProfileHotKey?,
        onChange: @escaping (ProfileHotKey?) -> String?,
        onFeedback: @escaping (String?, Bool) -> Void
    ) {
        self.shortcut = shortcut
        self.onChange = onChange
        self.onFeedback = onFeedback
        super.init(frame: .zero)
        bezelStyle = .rounded
        target = self
        action = #selector(beginRecording)
        setAccessibilityLabel("Shortcut for \(profileName)")
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
        Self.active?.finishRecording()
        Self.active = self
        title = "Press shortcut"
        contentTintColor = .controlAccentColor
        onFeedback("Esc to cancel · Delete to clear", false)
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
            if let error = onChange(nil) {
                finishRecording(feedback: error)
            } else {
                shortcut = nil
                finishRecording()
            }
            return
        }
        guard let newShortcut = ProfileHotKey(event: event) else {
            NSSound.beep()
            onFeedback("Include at least one modifier.", true)
            return
        }
        if let error = onChange(newShortcut) {
            finishRecording(feedback: error)
        } else {
            shortcut = newShortcut
            finishRecording()
        }
    }

    private func finishRecording(feedback: String? = nil) {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        contentTintColor = nil
        if Self.active === self { Self.active = nil }
        updateTitle()
        onFeedback(feedback, feedback != nil)
    }

    private func updateTitle() {
        title = shortcut?.displayName ?? "Add shortcut"
        setAccessibilityValue(shortcut?.displayName ?? "Not set")
    }
}
