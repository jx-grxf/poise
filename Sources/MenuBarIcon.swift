import AppKit

/// Renders the menu bar symbol tinted with native system colors.
/// Images are cached; the sensor pipeline must not allocate per sample.
@MainActor
enum MenuBarIcon {
    private static var cache: [String: NSImage] = [:]

    static func image(symbol: String, color: NSColor) -> NSImage {
        let key = "\(symbol)-\(color.description)"
        if let cached = cache[key] { return cached }

        let configuration = NSImage.SymbolConfiguration(pointSize: 13.5, weight: .semibold)
            .applying(.init(paletteColors: [color]))
        let base = NSImage(systemSymbolName: symbol, accessibilityDescription: "Poise")
        let image = base?.withSymbolConfiguration(configuration) ?? NSImage()
        image.isTemplate = false
        cache[key] = image
        return image
    }

    static func image(for store: PostureStore) -> NSImage {
        let symbol: String
        let color: NSColor
        switch store.connection {
        case .unavailable:
            symbol = "ear.trianglebadge.exclamationmark"
            color = .systemOrange
        case .paused:
            symbol = "pause.circle"
            color = .secondaryLabelColor
        case .waiting:
            symbol = "airpods"
            color = .secondaryLabelColor
        case .tracking:
            if !store.isCalibrated {
                symbol = "figure.stand"
                color = .secondaryLabelColor
            } else {
                switch store.level {
                case .good:
                    symbol = "figure.stand"
                    color = .systemGreen
                case .warning:
                    symbol = "figure.stand"
                    color = .systemOrange
                case .bad:
                    symbol = "figure.fall"
                    color = .systemRed
                }
            }
        }
        return image(symbol: symbol, color: color)
    }
}
