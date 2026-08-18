import SwiftUI

struct NeonBackground: View {
    @ObservedObject private var profile = PlayerProfile.shared

    var body: some View {
        let arena = profile.selectedArena
        ZStack {
            arena.backgroundColor.ignoresSafeArea()
            RadialGradient(colors: [arena.glowColor.opacity(0.24), .clear], center: .topTrailing, startRadius: 10, endRadius: 540).ignoresSafeArea()
            RadialGradient(colors: [arena.accentColor.opacity(0.14), .clear], center: .bottomLeading, startRadius: 10, endRadius: 460).ignoresSafeArea()
        }
    }
}

struct NeonButtonStyle: ButtonStyle {
    var tint: Color = .purple
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 14 : 17, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 11 : 15)
            .padding(.horizontal, compact ? 10 : 14)
            .background(tint.opacity(configuration.isPressed ? 0.34 : 0.20), in: RoundedRectangle(cornerRadius: compact ? 14 : 18))
            .overlay(RoundedRectangle(cornerRadius: compact ? 14 : 18).stroke(tint.opacity(0.9), lineWidth: 1.15))
            .shadow(color: tint.opacity(0.42), radius: configuration.isPressed ? 4 : 10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.08), lineWidth: 1))
    }
}
