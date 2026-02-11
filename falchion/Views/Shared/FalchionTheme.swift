import SwiftUI

struct FalchionMiniButtonStyle: ButtonStyle {
    var isActive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: FalchionThemeRuntime.current.retroMode ? .monospaced : .default))
            .foregroundStyle(isActive ? Color.falchionPane : Color.falchionTextPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? Color.falchionAccent : Color.falchionCardBase)
            .overlay {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.falchionBorder, lineWidth: 1)
            }
            .cornerRadius(2)
            .opacity(configuration.isPressed ? 0.86 : 1)
    }
}

struct FalchionInputStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 12, design: FalchionThemeRuntime.current.retroMode ? .monospaced : .default))
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(Color.falchionCardSurface)
            .foregroundStyle(Color.falchionTextPrimary)
            .overlay {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.falchionBorder, lineWidth: 1)
            }
            .cornerRadius(2)
    }
}

struct FalchionThemePalette {
    var background: Color
    var pane: Color
    var cardBase: Color
    var cardSurface: Color
    var row: Color
    var rowSelected: Color
    var border: Color
    var borderStrong: Color
    var textPrimary: Color
    var textSecondary: Color
    var accent: Color
    var retroMode: Bool
}

enum FalchionThemeRuntime {
    private static var palette = FalchionThemeFactory.palette(for: .classic, retroMode: false)

    static var current: FalchionThemePalette {
        palette
    }

    static func apply(theme: FalchionThemeOption, retroMode: Bool) {
        palette = FalchionThemeFactory.palette(for: theme, retroMode: retroMode)
    }
}

enum FalchionThemeFactory {
    static func palette(for theme: FalchionThemeOption, retroMode: Bool) -> FalchionThemePalette {
        let base: FalchionThemePalette

        switch theme {
        case .classic:
            base = FalchionThemePalette(
                background: Color(red: 0.07, green: 0.09, blue: 0.11),
                pane: Color(red: 0.10, green: 0.12, blue: 0.15),
                cardBase: Color(red: 0.12, green: 0.15, blue: 0.18),
                cardSurface: Color(red: 0.09, green: 0.11, blue: 0.14),
                row: Color.black.opacity(0.18),
                rowSelected: Color.black.opacity(0.34),
                border: Color.white.opacity(0.12),
                borderStrong: Color.white.opacity(0.25),
                textPrimary: Color(red: 0.92, green: 0.94, blue: 0.96),
                textSecondary: Color(red: 0.68, green: 0.72, blue: 0.77),
                accent: Color(red: 0.52, green: 0.67, blue: 0.96),
                retroMode: retroMode
            )
        case .light:
            base = FalchionThemePalette(
                background: Color(red: 0.93, green: 0.95, blue: 0.98),
                pane: Color(red: 0.98, green: 0.99, blue: 1.0),
                cardBase: Color(red: 0.92, green: 0.95, blue: 0.98),
                cardSurface: Color(red: 0.90, green: 0.93, blue: 0.97),
                row: Color.black.opacity(0.04),
                rowSelected: Color.black.opacity(0.09),
                border: Color.black.opacity(0.12),
                borderStrong: Color.black.opacity(0.24),
                textPrimary: Color(red: 0.13, green: 0.17, blue: 0.24),
                textSecondary: Color(red: 0.30, green: 0.35, blue: 0.45),
                accent: Color(red: 0.16, green: 0.44, blue: 0.86),
                retroMode: retroMode
            )
        case .superdark:
            base = FalchionThemePalette(
                background: Color.black,
                pane: Color.black,
                cardBase: Color.black,
                cardSurface: Color.black,
                row: Color.white.opacity(0.04),
                rowSelected: Color.white.opacity(0.10),
                border: Color.white.opacity(0.10),
                borderStrong: Color.white.opacity(0.24),
                textPrimary: Color.white,
                textSecondary: Color(red: 0.74, green: 0.74, blue: 0.74),
                accent: Color.white,
                retroMode: retroMode
            )
        case .synthwave:
            base = FalchionThemePalette(
                background: Color(hue: 0.72, saturation: 0.45, brightness: 0.15),
                pane: Color(hue: 0.74, saturation: 0.38, brightness: 0.20),
                cardBase: Color(hue: 0.75, saturation: 0.34, brightness: 0.23),
                cardSurface: Color(hue: 0.74, saturation: 0.36, brightness: 0.18),
                row: Color.black.opacity(0.22),
                rowSelected: Color.black.opacity(0.36),
                border: Color.white.opacity(0.14),
                borderStrong: Color.white.opacity(0.26),
                textPrimary: Color(hue: 0.81, saturation: 0.30, brightness: 0.96),
                textSecondary: Color(hue: 0.80, saturation: 0.24, brightness: 0.80),
                accent: Color(hue: 0.53, saturation: 0.77, brightness: 0.95),
                retroMode: retroMode
            )
        case .verdant:
            base = FalchionThemePalette(
                background: Color(hue: 0.39, saturation: 0.35, brightness: 0.14),
                pane: Color(hue: 0.40, saturation: 0.30, brightness: 0.18),
                cardBase: Color(hue: 0.40, saturation: 0.27, brightness: 0.22),
                cardSurface: Color(hue: 0.40, saturation: 0.29, brightness: 0.16),
                row: Color.black.opacity(0.20),
                rowSelected: Color.black.opacity(0.33),
                border: Color.white.opacity(0.14),
                borderStrong: Color.white.opacity(0.27),
                textPrimary: Color(hue: 0.37, saturation: 0.21, brightness: 0.94),
                textSecondary: Color(hue: 0.37, saturation: 0.14, brightness: 0.78),
                accent: Color(hue: 0.12, saturation: 0.82, brightness: 0.95),
                retroMode: retroMode
            )
        case .azure:
            base = FalchionThemePalette(
                background: Color(hue: 0.58, saturation: 0.34, brightness: 0.14),
                pane: Color(hue: 0.58, saturation: 0.30, brightness: 0.18),
                cardBase: Color(hue: 0.58, saturation: 0.28, brightness: 0.22),
                cardSurface: Color(hue: 0.58, saturation: 0.29, brightness: 0.16),
                row: Color.black.opacity(0.20),
                rowSelected: Color.black.opacity(0.33),
                border: Color.white.opacity(0.14),
                borderStrong: Color.white.opacity(0.27),
                textPrimary: Color(hue: 0.57, saturation: 0.25, brightness: 0.95),
                textSecondary: Color(hue: 0.57, saturation: 0.16, brightness: 0.78),
                accent: Color(hue: 0.10, saturation: 0.90, brightness: 0.96),
                retroMode: retroMode
            )
        case .ember:
            base = FalchionThemePalette(
                background: Color(hue: 0.04, saturation: 0.37, brightness: 0.14),
                pane: Color(hue: 0.04, saturation: 0.32, brightness: 0.18),
                cardBase: Color(hue: 0.04, saturation: 0.28, brightness: 0.22),
                cardSurface: Color(hue: 0.04, saturation: 0.30, brightness: 0.16),
                row: Color.black.opacity(0.20),
                rowSelected: Color.black.opacity(0.33),
                border: Color.white.opacity(0.14),
                borderStrong: Color.white.opacity(0.27),
                textPrimary: Color(hue: 0.05, saturation: 0.26, brightness: 0.95),
                textSecondary: Color(hue: 0.05, saturation: 0.16, brightness: 0.79),
                accent: Color(hue: 0.54, saturation: 0.80, brightness: 0.94),
                retroMode: retroMode
            )
        case .amber:
            base = FalchionThemePalette(
                background: Color(hue: 0.09, saturation: 0.36, brightness: 0.14),
                pane: Color(hue: 0.09, saturation: 0.30, brightness: 0.18),
                cardBase: Color(hue: 0.09, saturation: 0.26, brightness: 0.22),
                cardSurface: Color(hue: 0.09, saturation: 0.28, brightness: 0.16),
                row: Color.black.opacity(0.20),
                rowSelected: Color.black.opacity(0.33),
                border: Color.white.opacity(0.14),
                borderStrong: Color.white.opacity(0.27),
                textPrimary: Color(hue: 0.09, saturation: 0.24, brightness: 0.95),
                textSecondary: Color(hue: 0.09, saturation: 0.14, brightness: 0.79),
                accent: Color(hue: 0.56, saturation: 0.86, brightness: 0.96),
                retroMode: retroMode
            )
        case .retro90s:
            base = FalchionThemePalette(
                background: Color(red: 0.78, green: 0.78, blue: 0.72),
                pane: Color(red: 0.83, green: 0.82, blue: 0.76),
                cardBase: Color(red: 0.76, green: 0.75, blue: 0.68),
                cardSurface: Color(red: 0.71, green: 0.70, blue: 0.63),
                row: Color.black.opacity(0.08),
                rowSelected: Color.black.opacity(0.16),
                border: Color.black.opacity(0.25),
                borderStrong: Color.black.opacity(0.40),
                textPrimary: Color(red: 0.10, green: 0.10, blue: 0.10),
                textSecondary: Color(red: 0.24, green: 0.24, blue: 0.24),
                accent: Color(red: 0.13, green: 0.29, blue: 0.55),
                retroMode: true
            )
        case .retro90sDark:
            base = FalchionThemePalette(
                background: Color(red: 0.14, green: 0.13, blue: 0.12),
                pane: Color(red: 0.17, green: 0.16, blue: 0.14),
                cardBase: Color(red: 0.20, green: 0.19, blue: 0.17),
                cardSurface: Color(red: 0.15, green: 0.14, blue: 0.12),
                row: Color.white.opacity(0.05),
                rowSelected: Color.white.opacity(0.12),
                border: Color.white.opacity(0.17),
                borderStrong: Color.white.opacity(0.29),
                textPrimary: Color(red: 0.91, green: 0.89, blue: 0.84),
                textSecondary: Color(red: 0.73, green: 0.70, blue: 0.64),
                accent: Color(red: 0.44, green: 0.62, blue: 0.96),
                retroMode: true
            )
        }

        if retroMode {
            return FalchionThemePalette(
                background: base.background.opacity(0.98),
                pane: base.pane.opacity(0.98),
                cardBase: base.cardBase,
                cardSurface: base.cardSurface,
                row: base.row,
                rowSelected: base.rowSelected,
                border: base.border,
                borderStrong: base.borderStrong,
                textPrimary: base.textPrimary,
                textSecondary: base.textSecondary,
                accent: base.accent,
                retroMode: true
            )
        }

        return base
    }
}

extension Color {
    static var falchionBackground: Color { FalchionThemeRuntime.current.background }
    static var falchionPane: Color { FalchionThemeRuntime.current.pane }
    static var falchionCardBase: Color { FalchionThemeRuntime.current.cardBase }
    static var falchionCardSurface: Color { FalchionThemeRuntime.current.cardSurface }
    static var falchionRow: Color { FalchionThemeRuntime.current.row }
    static var falchionRowSelected: Color { FalchionThemeRuntime.current.rowSelected }
    static var falchionBorder: Color { FalchionThemeRuntime.current.border }
    static var falchionBorderStrong: Color { FalchionThemeRuntime.current.borderStrong }
    static var falchionTextPrimary: Color { FalchionThemeRuntime.current.textPrimary }
    static var falchionTextSecondary: Color { FalchionThemeRuntime.current.textSecondary }
    static var falchionAccent: Color { FalchionThemeRuntime.current.accent }
}
