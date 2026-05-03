import AppKit
import SwiftUI

final class BreakWindowController: NSWindowController {

    private var onComplete: (() -> Void)?

    init() {
        let screen = NSScreen.main ?? NSScreen.screens[0]

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )

        // Appear above all other windows including full-screen apps
        window.level = .screenSaver

        // Join whichever Space the user is currently on, stay put during Exposé
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary,
        ]

        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Public

    func show(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete

        // Resize to the current main screen — display config may have changed
        // (external monitor (un)plugged) since the window was created.
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            window?.setFrame(screen.frame, display: false)
        }

        // Rebuild the SwiftUI view each time so the countdown resets
        let breakView = BreakOverlayView(onDismiss: { [weak self] in
            self?.dismiss()
        })
        let hosting = NSHostingController(rootView: breakView)
        window?.contentViewController = hosting

        // Belt-and-suspenders: NSHostingController sometimes sizes its view to
        // the SwiftUI content's intrinsic size rather than filling the window,
        // which leaves the overlay anchored in a corner. Pin to the window's
        // content view so the SwiftUI root always fills the screen.
        if let contentView = window?.contentView {
            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hosting.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                hosting.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                hosting.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                hosting.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ])
        }

        // Defer the order-front so any in-flight NSMenu close finishes first,
        // and use orderFrontRegardless because:
        //   • the app is .accessory (can't activate normally)
        //   • the window is .borderless (can't become key)
        // makeKeyAndOrderFront(_:) is unreliable in that combination.
        DispatchQueue.main.async { [weak self] in
            self?.window?.orderFrontRegardless()
        }
    }

    // MARK: - Private

    private func dismiss() {
        window?.orderOut(nil)
        let callback = onComplete
        onComplete = nil
        callback?()
    }
}
