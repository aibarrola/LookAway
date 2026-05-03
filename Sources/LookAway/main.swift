import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Set before run() to avoid a brief Dock icon flash
app.setActivationPolicy(.accessory)
app.run()
