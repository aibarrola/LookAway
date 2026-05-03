# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Build (release)
swift build -c release

# Restart after changes
pkill LookAway; sleep 0.5 && .build/release/LookAway &

# Trigger a break immediately via the menu bar → "Trigger Break Now"
```

The XCTest xcrun warning about `PlatformPath` is harmless — ignore it.

No Xcode project exists; this is pure SPM. There are no SwiftUI Previews available without extra setup.

## Architecture

The app is a menu bar accessory (no Dock icon). Data flows in one direction:

```
ActivityMonitor ──poll──► WorkTimerManager ──delegate──► AppDelegate ──► BreakWindowController
                                                                                    │
                                                                          BreakOverlayView (SwiftUI)
```

- **`WorkTimerManager`** — central state machine. Polls every 5 s. Accumulates `activeSeconds` only when the user is active (mouse/keyboard idle < 60 s, or a video/media player holds a `PreventUserIdleDisplaySleep` power assertion). Fires the delegate at 1200 s (20 min). Idle pauses the count; it does not reset.
- **`ActivityMonitor`** — two queries: `CGEventSource` for HID idle time, `IOPMCopyAssertionsStatus` for video-playing detection.
- **`AppDelegate`** — owns the `NSStatusItem`, a 1 s menu-bar update timer (added to `.common` RunLoop mode so it fires while a menu is open), and wires `WorkTimerManager` → `BreakWindowController`.
- **`BreakWindowController`** — creates the `NSWindow` once at init (level `.screenSaver`, `canJoinAllSpaces`). On each break it rebuilds the SwiftUI hosting controller so the countdown resets cleanly.
- **`BreakOverlayView`** — SwiftUI view with a `DispatchQueue.main.asyncAfter` tick loop (not a Timer). Plays `NSSound("Glass")` on countdown completion.

## Key Constraints

- `setActivationPolicy(.accessory)` must be called **before** `app.run()` in `main.swift` to avoid a Dock icon flash.
- `CGEventType(rawValue: ~UInt32(0))!` — the force-unwrap is intentional and safe; `kCGAnyInputEventType` is always a valid raw value.
- To shorten the work interval for testing, pass a custom `workDurationSeconds` to `WorkTimerManager(workDurationSeconds:)` in `AppDelegate.applicationDidFinishLaunching`.
