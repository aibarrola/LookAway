# LookAway

A lightweight macOS menu bar app that reminds you to follow the **20-20-20 rule** — a simple eye health habit: every 20 minutes of screen time, look at something 20 feet away for 20 seconds.

## How it works

LookAway runs quietly in your menu bar and tracks how long you've been actively using your computer. After 20 minutes of active use, it covers your screen with a full-screen overlay and counts down 20 seconds. When the countdown ends, it plays a soft chime and dismisses automatically.

- **Smart activity detection** — the timer only runs when you're actually using your computer. It pauses when you step away (no mouse/keyboard activity for 60+ seconds) and resumes when you return. Your progress is never lost, just paused.
- **Video-aware** — if a video or media player is running and blocking your display from sleeping, LookAway counts that as active time too.
- **No Dock icon** — lives entirely in the menu bar. The icon shows a live countdown so you always know how much time is left.

## Requirements

- macOS 12 or later
- Xcode Command Line Tools (`xcode-select --install`)

## Build & Run

```bash
swift build -c release
.build/release/LookAway &
```

To trigger a break immediately, click the menu bar icon and choose **Trigger Break Now**.

## Stack

- Swift 5.9 + Swift Package Manager
- AppKit for the app lifecycle and window management
- SwiftUI for the break overlay
- CoreGraphics + IOKit for idle time and video-playback detection
