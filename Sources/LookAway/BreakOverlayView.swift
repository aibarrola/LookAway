import AppKit
import SwiftUI

// Frosted glass background using NSVisualEffectView
private struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .fullScreenUI
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct BreakOverlayView: View {

    let onDismiss: () -> Void

    @State private var secondsRemaining: Int = 20
    @State private var progress: Double = 1.0
    @State private var isCancelled: Bool = false

    private let totalSeconds: Int = 20

    private let cardCornerRadius: CGFloat = 28

    var body: some View {
        ZStack {
            // No full-screen dim — just the card floats over the desktop, HUD-style.
            Color.clear.ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))

                    Text("Time for a break")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text("Look at something 20 feet away")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.10), lineWidth: 14)
                        .frame(width: 220, height: 220)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.blue,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)

                    Text("\(secondsRemaining)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 8)
                }
                .padding(.vertical, 4)

                Button("Skip") {
                    isCancelled = true
                    onDismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .padding(.horizontal, 24)
                .padding(.vertical, 9)
                .background(.white.opacity(0.10), in: Capsule())
            }
            .padding(.horizontal, 44)
            .padding(.vertical, 40)
            .frame(maxWidth: 480)
            // SwiftUI material in a Shape's fill so the rounded corners
            // actually clip the blur. NSVisualEffectView ignores SwiftUI's
            // .clipShape — that's why the previous version had square corners.
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.55), radius: 40, y: 18)
            .padding(48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .onAppear {
            startCountdown()
        }
    }

    // MARK: - Countdown

    private func startCountdown() {
        secondsRemaining = totalSeconds
        progress = 1.0
        tick()
    }

    private func tick() {
        // Bail out if the user hit Skip — stops the pending asyncAfter chain
        // from playing the Glass sound and double-calling onDismiss.
        guard !isCancelled else { return }
        guard secondsRemaining > 0 else {
            NSSound(named: NSSound.Name("Glass"))?.play()
            onDismiss()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            secondsRemaining -= 1
            progress = Double(secondsRemaining) / Double(totalSeconds)
            tick()
        }
    }
}
