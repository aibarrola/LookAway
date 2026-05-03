import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, WorkTimerManagerDelegate {

    // MARK: - Properties

    // Strong reference required — if statusItem falls out of scope, icon vanishes
    private var statusItem: NSStatusItem!
    private var workTimerManager: WorkTimerManager!
    private var breakWindowController: BreakWindowController!
    private var menuBarUpdateTimer: Timer?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        workTimerManager = WorkTimerManager()
        workTimerManager.delegate = self
        workTimerManager.start()

        breakWindowController = BreakWindowController()

        setupMenuBar()
        startMenuBarUpdates()
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarUpdateTimer?.invalidate()
        workTimerManager.stop()
    }

    // MARK: - WorkTimerManagerDelegate

    func workTimerManagerDidTriggerBreak() {
        breakWindowController.show {
            self.workTimerManager.breakCompleted()
        }
    }

    // MARK: - Menu bar setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem.button else { return }
        button.image = eyeImage(for: workTimerManager.secondsUntilBreak)

        let menu = NSMenu()
        menu.addItem(withTitle: "LookAway", action: nil, keyEquivalent: "")
        menu.addItem(.separator())

        // Time-until-break item — updated every second so it's readable when opened
        let timeItem = NSMenuItem(title: menuTimeTitle(), action: nil, keyEquivalent: "")
        timeItem.tag = 42
        menu.addItem(timeItem)

        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Trigger Break Now",
            action: #selector(triggerBreakNow),
            keyEquivalent: ""
        )
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit LookAway",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        statusItem.menu = menu
    }

    private func startMenuBarUpdates() {
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMenuBarIcon()
        }
        RunLoop.main.add(timer, forMode: .common)
        menuBarUpdateTimer = timer
    }

    @objc private func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }

        if workTimerManager.isOnBreak {
            button.image = symbolImage(name: "eye.trianglebadge.exclamationmark", color: .systemOrange)
        } else {
            button.image = eyeImage(for: workTimerManager.secondsUntilBreak)
        }

        // Keep the dropdown menu item fresh too
        statusItem.menu?.item(withTag: 42)?.title = menuTimeTitle()
    }

    @objc private func triggerBreakNow() {
        workTimerManager.triggerBreakManually()
    }

    // MARK: - Icon helpers

    /// Eye icon: green >10 min, yellow 5–10 min, red <5 min, grey when idle/paused
    private func eyeImage(for secondsRemaining: Int) -> NSImage {
        let minutes = secondsRemaining / 60
        let color: NSColor
        if workTimerManager.isUserIdle  { color = .secondaryLabelColor }
        else if minutes > 10            { color = .systemGreen }
        else if minutes > 5             { color = .systemYellow }
        else                            { color = .systemRed }
        return symbolImage(name: "eye.fill", color: color)
    }

    private func symbolImage(name: String, color: NSColor) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let base = NSImage(systemSymbolName: name, accessibilityDescription: "LookAway")?
            .withSymbolConfiguration(config) ?? NSImage()
        return tinted(base, color: color)
    }

    private func tinted(_ image: NSImage, color: NSColor) -> NSImage {
        let result = NSImage(size: image.size, flipped: false) { rect in
            image.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
        return result
    }

    private func menuTimeTitle() -> String {
        if workTimerManager.isOnBreak { return "Break in progress…" }
        let remaining = workTimerManager.secondsUntilBreak
        let prefix: String
        if workTimerManager.isUserIdle          { prefix = "Paused — " }
        else if workTimerManager.isVideoPlaying { prefix = "Video playing — " }
        else                                    { prefix = "" }
        return "\(prefix)\(formatTime(remaining)) until break"
    }

    // MARK: - Helpers

    private func formatTime(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
