#!/usr/bin/swift
import AppKit

// Renders the LookAway icon at a given pixel size and saves to a PNG file.
func renderIcon(size: Int, to path: String) {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s), flipped: false) { rect in

        let ctx = NSGraphicsContext.current!.cgContext

        // --- Background: dark rounded square with a subtle teal gradient ---
        let cornerRadius = s * 0.22
        let bgPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(bgPath)
        ctx.clip()

        let colors = [
            NSColor(red: 0.04, green: 0.12, blue: 0.20, alpha: 1).cgColor,  // deep navy
            NSColor(red: 0.03, green: 0.22, blue: 0.28, alpha: 1).cgColor,  // dark teal
        ]
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0, 1]
        )!
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: s),
            end: CGPoint(x: s, y: 0),
            options: []
        )

        // --- Eye symbol using SF Symbols ---
        let symbolSize = s * 0.52
        let config = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .medium)
        if let eye = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: nil)?
                        .withSymbolConfiguration(config) {

            // Tint the symbol white
            let tinted = NSImage(size: eye.size, flipped: false) { r in
                eye.draw(in: r)
                NSColor.white.withAlphaComponent(0.92).set()
                r.fill(using: .sourceAtop)
                return true
            }

            let ex = (s - tinted.size.width)  / 2
            let ey = (s - tinted.size.height) / 2
            tinted.draw(in: CGRect(x: ex, y: ey, width: tinted.size.width, height: tinted.size.height))
        }

        // --- Subtle mint glow ring beneath the eye ---
        let ringInset = s * 0.12
        let ringRect = CGRect(x: ringInset, y: ringInset, width: s - ringInset*2, height: s - ringInset*2)
        let ringPath = CGPath(ellipseIn: ringRect, transform: nil)
        ctx.addPath(ringPath)
        ctx.setStrokeColor(NSColor(red: 0.25, green: 0.95, blue: 0.75, alpha: 0.18).cgColor)
        ctx.setLineWidth(s * 0.03)
        ctx.strokePath()

        return true
    }

    // Write PNG
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to render size \(size)")
        return
    }
    do {
        try png.write(to: URL(fileURLWithPath: path))
        print("Written: \(path)")
    } catch {
        print("Error writing \(path): \(error)")
    }
}

// Required sizes for a macOS .iconset
let sizes = [16, 32, 64, 128, 256, 512, 1024]
let iconsetPath = "/Users/angeloibarrola/Coding Projects/LookAway/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for size in sizes {
    // 1x
    renderIcon(size: size, to: "\(iconsetPath)/icon_\(size)x\(size).png")
    // 2x (Retina) — skip for 1024 since there's no 2048 slot
    if size <= 512 {
        renderIcon(size: size * 2, to: "\(iconsetPath)/icon_\(size)x\(size)@2x.png")
    }
}

print("Done — iconset ready at \(iconsetPath)")
