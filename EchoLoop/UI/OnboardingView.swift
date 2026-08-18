import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        .init(symbol: "point.topleft.down.to.point.bottomright.curvepath", title: "MOVE", subtitle: "Drag anywhere. Your orb follows your finger.", tint: .cyan),
        .init(symbol: "clock.arrow.2.circlepath", title: "REMEMBER", subtitle: "Every few seconds, your exact path returns as an echo.", tint: .purple),
        .init(symbol: "bolt.horizontal.circle.fill", title: "OUTRUN", subtitle: "Dash through danger, collect shards and never touch your past.", tint: .pink)
    ]

    var body: some View {
        ZStack {
            NeonBackground()
            VStack(spacing: 22) {
                HStack {
                    Text("ECHO LOOP").font(.caption.bold()).tracking(3).foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Button("SKIP") { finish() }.font(.caption.bold()).foregroundStyle(.white.opacity(0.55))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 28) {
                            Spacer()
                            ZStack {
                                Circle().stroke(item.tint.opacity(0.18), lineWidth: 2).frame(width: 230, height: 230)
                                Circle().stroke(item.tint.opacity(0.38), lineWidth: 2).frame(width: 168, height: 168)
                                Image(systemName: item.symbol)
                                    .font(.system(size: 58, weight: .light))
                                    .foregroundStyle(.white)
                                    .shadow(color: item.tint, radius: 18)
                            }
                            VStack(spacing: 10) {
                                Text(item.title).font(.system(size: 36, weight: .black, design: .rounded)).tracking(4)
                                Text(item.subtitle)
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.62))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 36)
                            }
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button(page == pages.count - 1 ? "ENTER THE LOOP" : "CONTINUE") {
                    AudioManager.shared.play(.tap)
                    if page == pages.count - 1 { finish() }
                    else { withAnimation(.easeInOut(duration: 0.25)) { page += 1 } }
                }
                .buttonStyle(NeonButtonStyle(tint: pages[page].tint))
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .foregroundStyle(.white)
        }
    }

    private func finish() {
        settings.completeOnboarding()
        Haptics.success()
        AudioManager.shared.play(.revive)
        AnalyticsManager.shared.track(.onboardingCompleted)
    }
}

private struct OnboardingPage {
    let symbol: String
    let title: String
    let subtitle: String
    let tint: Color
}
