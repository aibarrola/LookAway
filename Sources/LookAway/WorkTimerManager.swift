import AppKit

protocol WorkTimerManagerDelegate: AnyObject {
    func workTimerManagerDidTriggerBreak()
}

final class WorkTimerManager {

    // MARK: - Configuration

    let workDurationSeconds: Int
    private let idleThresholdSeconds: Double = 60.0
    private let pollIntervalSeconds: Double = 5.0

    // MARK: - State

    private(set) var activeSeconds: Int = 0
    private(set) var isOnBreak: Bool = false
    private(set) var isUserIdle: Bool = false
    private(set) var isVideoPlaying: Bool = false

    // Wallclock anchor — the moment of the previous "active" tick.
    // nil means "don't bill on the next tick" (first tick, after wake, after going idle).
    private var lastActiveTickAt: Date?

    var secondsUntilBreak: Int {
        max(0, workDurationSeconds - activeSeconds)
    }

    // MARK: - Dependencies

    weak var delegate: WorkTimerManagerDelegate?
    private let activityMonitor: ActivityMonitor
    private var pollTimer: Timer?

    // MARK: - Init

    init(workDurationSeconds: Int = 20 * 60, activityMonitor: ActivityMonitor = ActivityMonitor()) {
        self.workDurationSeconds = workDurationSeconds
        self.activityMonitor = activityMonitor
    }

    // MARK: - Lifecycle

    func start() {
        let timer = Timer(timeInterval: pollIntervalSeconds, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // .common mode ensures the timer fires even while a menu is open
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer

        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(systemWillSleep),
                       name: NSWorkspace.willSleepNotification, object: nil)
        nc.addObserver(self, selector: #selector(systemDidWake),
                       name: NSWorkspace.didWakeNotification, object: nil)
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Break management

    func breakCompleted() {
        isOnBreak = false
        activeSeconds = 0
        lastActiveTickAt = nil
    }

    /// Manually trigger a break from the menu. Routes through the same path
    /// as the timer-driven trigger so isOnBreak/state stay consistent.
    func triggerBreakManually() {
        guard !isOnBreak else { return }
        triggerBreak()
    }

    // MARK: - Sleep / wake

    @objc private func systemWillSleep(_ note: Notification) {
        // Drop the anchor so the next post-wake tick doesn't bill sleep time as active.
        lastActiveTickAt = nil
    }

    @objc private func systemDidWake(_ note: Notification) {
        // Belt-and-suspenders: also drop on wake. CGEventSource will already
        // report a large idle time, so the next tick will classify the user
        // as idle until they actually interact.
        lastActiveTickAt = nil
    }

    // MARK: - Private

    private func tick() {
        guard !isOnBreak else { return }

        let now = Date()
        let idleSeconds = activityMonitor.secondsSinceLastUserInput()
        isVideoPlaying = activityMonitor.isVideoPlaying()

        // Active if either: HID input within the idle window, or a media
        // player is holding a PreventUserIdleDisplaySleep assertion.
        let isActive = idleSeconds < idleThresholdSeconds || isVideoPlaying
        isUserIdle = !isActive

        guard isActive else {
            // Pause (don't reset). Clear the anchor so a future active streak
            // doesn't bill the idle gap.
            lastActiveTickAt = nil
            return
        }

        defer { lastActiveTickAt = now }

        // First active tick of a streak — start the clock, don't bill yet.
        guard let last = lastActiveTickAt else { return }

        // Bill wallclock elapsed since the previous active tick. Cap at 2× the
        // poll interval so a delayed timer (system load, brief sleep that we
        // didn't catch) can't suddenly add minutes of "active" time.
        let elapsed = now.timeIntervalSince(last)
        let billable = max(0.0, min(elapsed, pollIntervalSeconds * 2))
        activeSeconds += Int(billable.rounded())

        if activeSeconds >= workDurationSeconds {
            triggerBreak()
        }
    }

    private func triggerBreak() {
        isOnBreak = true
        activeSeconds = 0
        lastActiveTickAt = nil
        delegate?.workTimerManagerDidTriggerBreak()
    }
}
