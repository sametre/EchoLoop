import SwiftUI

struct CoinBadge: View {
    let coins: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "hexagon.fill")
                .foregroundStyle(.yellow)
                .shadow(color: .yellow.opacity(0.65), radius: 6)
            Text("\(coins)")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.35), in: Capsule())
        .overlay(Capsule().stroke(.yellow.opacity(0.25), lineWidth: 1))
    }
}
