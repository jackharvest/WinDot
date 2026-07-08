import Cocoa

let sizes = [16, 32, 128, 256, 512]
let iconsetPath = "icon.iconset"

try? FileManager.default.removeItem(atPath: iconsetPath)
try! FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

func renderIcon(pixelSize: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: pixelSize * 0.22, yRadius: pixelSize * 0.22)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.98, green: 0.36, blue: 0.42, alpha: 1.0),
        NSColor(calibratedRed: 0.98, green: 0.62, blue: 0.20, alpha: 1.0)
    ])
    gradient?.draw(in: bgPath, angle: -90)

    // "⌘." mark — matches the menu bar glyph and doubles as a reminder of the hotkey.
    let text = "\u{2318}." as NSString // ⌘.
    let font = NSFont.systemFont(ofSize: pixelSize * 0.44, weight: .heavy)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
    let textSize = text.size(withAttributes: attrs)
    let textRect = NSRect(
        x: (pixelSize - textSize.width) / 2,
        y: (pixelSize - textSize.height) / 2 - pixelSize * 0.02,
        width: textSize.width,
        height: textSize.height
    )
    text.draw(in: textRect, withAttributes: attrs)

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to encode PNG for \(path)")
    }
    FileManager.default.createFile(atPath: path, contents: data)
}

for size in sizes {
    savePNG(renderIcon(pixelSize: CGFloat(size)), to: "\(iconsetPath)/icon_\(size)x\(size).png")
    savePNG(renderIcon(pixelSize: CGFloat(size * 2)), to: "\(iconsetPath)/icon_\(size)x\(size)@2x.png")
}

print("Iconset written to \(iconsetPath)")
