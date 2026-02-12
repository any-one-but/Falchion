import AppKit
import SwiftUI

struct FalchionMiniButtonStyle: ButtonStyle {
    var isActive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(isActive ? Color.white : Color.falchionTextPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isActive ? Color.accentColor : Color.falchionCardBase)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.falchionBorder, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

struct FalchionInputStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.falchionCardSurface)
            .foregroundStyle(Color.falchionTextPrimary)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.falchionBorder, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

enum FalchionThemeRuntime {
    static func apply(theme: FalchionThemeOption) {
        _ = theme
    }
}

extension Color {
    static var falchionBackground: Color { Color(nsColor: .windowBackgroundColor) }
    static var falchionPane: Color { Color(nsColor: .controlBackgroundColor) }
    static var falchionCardBase: Color { Color(nsColor: .underPageBackgroundColor) }
    static var falchionCardSurface: Color { Color(nsColor: .textBackgroundColor) }
    static var falchionRow: Color { Color(nsColor: .controlBackgroundColor) }
    static var falchionRowSelected: Color { Color(nsColor: .selectedContentBackgroundColor).opacity(0.2) }
    static var falchionBorder: Color { Color(nsColor: .separatorColor) }
    static var falchionBorderStrong: Color { Color(nsColor: .separatorColor).opacity(0.9) }
    static var falchionTextPrimary: Color { Color(nsColor: .labelColor) }
    static var falchionTextSecondary: Color { Color(nsColor: .secondaryLabelColor) }
    static var falchionAccent: Color { Color.accentColor }
}
