import SwiftUI

struct ChallengesView: View {
    @ObservedObject var profile: PlayerProfile
    let close: () -> Void

    var body: some View {
        ZStack {
            NeonBackground()
            ScrollView {
                VStack(spacing: 18) {
                    header
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DAILY SIGNAL").font(.caption.bold()).foregroundStyle(.pink)
                                Text("Complete missions before the day resets.").font(.subheadline).foregroundStyle(.white.opacity(0.68))
                            }
                            Spacer()
                            CoinBadge(coins: profile.coins)
                        }
                    }

                    ForEach(profile.dailyChallenges) { challenge in
                        challengeCard(challenge)
                    }

                }
                .padding(20)
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: close) { Image(systemName: "chevron.left").padding(12).background(.white.opacity(0.08), in: Circle()) }
            Spacer()
            Text("MISSIONS").font(.title2.bold()).tracking(2)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .foregroundStyle(.white)
    }

    private func challengeCard(_ challenge: DailyChallenge) -> some View {
        let progress = profile.progress(for: challenge)
        let claimed = profile.isClaimed(challenge)
        let ready = profile.canClaim(challenge)

        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: challenge.symbol)
                        .font(.title2).foregroundStyle(ready ? .yellow : .cyan)
                        .frame(width: 42, height: 42)
                        .background(.white.opacity(0.05), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(challenge.title).font(.headline)
                        Text(challenge.subtitle).font(.caption).foregroundStyle(.white.opacity(0.58))
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "hexagon.fill").foregroundStyle(.yellow)
                        Text("\(challenge.reward)").font(.subheadline.bold())
                    }
                    .frame(width: 92, alignment: .trailing)
                }

                ProgressView(value: Double(progress), total: Double(challenge.target))
                    .tint(ready || claimed ? .yellow : .cyan)
                HStack {
                    Text("\(progress) / \(challenge.target)").font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    if claimed {
                        Label("CLAIMED", systemImage: "checkmark.circle.fill").font(.caption.bold()).foregroundStyle(.green)
                    } else if ready {
                        Button("CLAIM") { _ = profile.claim(challenge) }
                            .buttonStyle(NeonButtonStyle(tint: .yellow, compact: true))
                            .frame(width: 120)
                    }
                }
            }
        }
    }
}
