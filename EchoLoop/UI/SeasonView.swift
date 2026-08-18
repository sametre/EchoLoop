import SwiftUI

struct SeasonView: View {
    @ObservedObject var profile: PlayerProfile
    let close: () -> Void

    var body: some View {
        ZStack {
            NeonBackground()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    seasonHero
                    ForEach(SeasonProgression.tiers) { tier in
                        tierCard(tier)
                    }
                }
                .padding(20)
                .padding(.bottom, 28)
            }
        }
        .foregroundStyle(.white)
        .accessibilityIdentifier("season.screen")
    }

    private var header: some View {
        HStack {
            Button(action: close) {
                Image(systemName: "chevron.left").font(.headline).padding(10)
                    .background(.black.opacity(0.34), in: Circle())
            }
            .accessibilityIdentifier("season.close")
            Spacer()
            Text("SEASON SIGNAL").font(.headline.bold()).tracking(1.6)
            Spacer()
            CoinBadge(coins: profile.coins)
        }
    }

    private var seasonHero: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(SeasonProgression.title).font(.title2.weight(.black))
                        Text("FREE PROGRESSION • SEASON 1").font(.caption.bold()).foregroundStyle(.cyan)
                    }
                    Spacer()
                    Text("TIER \(profile.seasonTier)/\(SeasonProgression.tiers.count)")
                        .font(.caption.bold()).foregroundStyle(.yellow)
                }
                ProgressView(value: profile.seasonProgress)
                    .tint(.cyan)
                Text("\(profile.seasonXP) SIGNAL XP")
                    .font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.58))
            }
        }
    }

    @ViewBuilder
    private func tierCard(_ tier: SeasonTier) -> some View {
        let unlocked = profile.seasonXP >= tier.requiredXP
        let claimed = profile.isSeasonTierClaimed(tier.id)
        GlassCard {
            HStack(spacing: 13) {
                ZStack {
                    Circle().fill((unlocked ? Color.cyan : Color.white).opacity(0.12)).frame(width: 44, height: 44)
                    Text("\(tier.id)").font(.headline.bold()).foregroundStyle(unlocked ? .cyan : .white.opacity(0.4))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(tier.title).font(.subheadline.bold())
                    Text("\(tier.requiredXP) XP • +\(tier.coinReward) COINS")
                        .font(.caption2).foregroundStyle(.white.opacity(0.52))
                }
                Spacer()
                if claimed {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                } else if unlocked {
                    Button("CLAIM") { _ = profile.claimSeasonTier(tier.id) }
                        .buttonStyle(NeonButtonStyle(tint: .cyan, compact: true))
                        .frame(width: 92)
                } else {
                    Image(systemName: "lock.fill").foregroundStyle(.white.opacity(0.28))
                }
            }
        }
    }
}
