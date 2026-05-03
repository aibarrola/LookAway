import CoreGraphics
import Foundation
import IOKit.pwr_mgt

final class ActivityMonitor {

    /// Returns the number of seconds since the user last moved the mouse,
    /// pressed a key, or interacted with the machine in any way.
    func secondsSinceLastUserInput() -> Double {
        // CGEventSource is the modern, non-deprecated way to get HID idle time.
        // kCGAnyInputEventType (~UInt32(0)) covers keyboard, mouse, tablet, etc.
        // ~UInt32(0) == UInt32.max == kCGAnyInputEventType; the rawValue is always valid here
        let anyInputEvent = CGEventType(rawValue: ~UInt32(0))!
        return CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: anyInputEvent)
    }

    /// Returns true if any process holds a PreventUserIdleDisplaySleep power assertion —
    /// the standard macOS signal that video or media is playing.
    /// Covers Safari, Chrome, Firefox, VLC, IINA, QuickTime, and any other
    /// compliant player. Also fires for presentations in slideshow mode and
    /// screen recorders — all cases where the user is actively consuming content.
    func isVideoPlaying() -> Bool {
        var assertionsRef: Unmanaged<CFDictionary>?
        let result = IOPMCopyAssertionsStatus(&assertionsRef)
        // Must bridge CFDictionary → NSDictionary → [String: AnyObject] because
        // dictionary values are CFNumber objects, not native Swift Ints.
        // A direct cast to [String: Int] returns nil and must be avoided.
        guard result == kIOReturnSuccess,
              let dict = assertionsRef?.takeRetainedValue() as NSDictionary? as? [String: AnyObject],
              let level = dict[kIOPMAssertionTypePreventUserIdleDisplaySleep] as? Int
        else { return false }
        return level > 0
    }
}
