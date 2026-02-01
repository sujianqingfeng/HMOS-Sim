import SwiftUI

// MARK: - Simple Theme
enum Theme {
    // Accent colors - simple blue
    static let accent = Color.accentColor
    static let online = Color.green
    static let offline = Color.secondary
    static let warning = Color.orange
    static let error = Color.red
    
    // Backgrounds - simple, no glass
    static let cardBackground = Color(NSColor.controlBackgroundColor)
    
    // Text
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
}

// MARK: - Simple Animations
enum Animations {
    static let standard = Animation.easeInOut(duration: 0.2)
    static let fast = Animation.easeInOut(duration: 0.15)
}

// MARK: - View Extensions
extension View {
    func simpleCard(cornerRadius: CGFloat = 8) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.cardBackground)
                    .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
            )
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let isOnline: Bool
    
    var body: some View {
        Circle()
            .fill(isOnline ? Theme.online : Theme.offline)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Search Field
struct SimpleSearchField: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Empty State
struct SimpleEmptyState: View {
    var title: String
    var systemImage: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text(title)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
