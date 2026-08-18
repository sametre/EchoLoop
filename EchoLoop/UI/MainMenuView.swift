import SwiftUI

struct MainMenuView: View {
    @ObservedObject var store: StoreManager
    @ObservedObject var profile: PlayerProfile
    @ObservedObject private var privacy = PrivacyConsentManager.shared
    @ObservedObject private var ads = AdManager.shared
    let play: () -> Void
    let shop: () -> Void
    let challenges: () -> Void
    let profileAction: () -> Void
    let achievements: () -> Void
    let season: () -> Void
    let practice: () -> Void
    let settings: () -> Void

    private var readyChallenges: Int {
        profile.dailyChallenges.filter { profile.canClaim($0) }.count
    }

    var body: some View {
        ZStack {
            NeonBackground()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    Spacer(minLength: 4)
                    logo
                    playOrb
                    buttons

                    if profile.dailyRewardAvailable { dailyRewardCard }
                    runSummary

                    if !store.adsRemoved && privacy.canRequestAds && ads.isStarted && ConfigurationValidator.adsMayStart {
                        GeometryReader { geometry in
                            AdaptiveBannerView(width: min(geometry.size.width - 32, 420))
                                .frame(maxWidth: .infinity)
                        }
                        .frame(height: 72)
                    }
                }
                .padding(.bottom, 18)
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: profileAction) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(profile.selectedOrb.primaryColor.opacity(0.22)).frame(width: 38, height: 38)
                        Circle().fill(profile.selectedOrb.primaryColor).frame(width: 14, height: 14).shadow(color: profile.selectedOrb.secondaryColor, radius: 8)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("LEVEL \(profile.level)").font(.caption.bold())
                        ProgressView(value: profile.levelProgress).tint(profile.selectedArena.accentColor).frame(width: 76)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("menu.profile")
            Spacer()
            CoinBadge(coins: profile.coins)
            Button(action: settings) {
                Image(systemName: "gearshape.fill")
                    .font(.headline)
                    .padding(11)
                    .background(.black.opacity(0.32), in: Circle())
            }
            .accessibilityIdentifier("menu.settings")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var logo: some View {
        VStack(spacing: 4) {
            Text("ECHO")
                .font(.system(size: 60, weight: .black, design: .rounded))
                .tracking(8)
                .foregroundStyle(LinearGradient(colors: [.white, .cyan, .purple, .pink], startPoint: .leading, endPoint: .trailing))
                .shadow(color: .purple.opacity(0.72), radius: 20)
            Text("OUTRUN YOUR PAST")
                .font(.caption.weight(.semibold)).tracking(4).foregroundStyle(.pink.opacity(0.9))
        }
    }

    private var playOrb: some View {
        ZStack {
            Circle().stroke(profile.selectedArena.accentColor.opacity(0.68), lineWidth: 2).frame(width: 148, height: 148).shadow(color: profile.selectedArena.accentColor, radius: 18)
            Circle().stroke(profile.selectedArena.glowColor.opacity(0.72), lineWidth: 2).frame(width: 114, height: 114).shadow(color: profile.selectedArena.glowColor, radius: 14)
            Circle().fill(profile.selectedOrb.primaryColor).frame(width: 28, height: 28).shadow(color: profile.selectedOrb.secondaryColor, radius: 16)
            Button(action: play) {
                Image(systemName: "play.fill").font(.system(size: 38)).foregroundStyle(.white).padding(34)
            }
            .accessibilityIdentifier("menu.playOrb")
        }
        .padding(.vertical, 2)
    }

    private var buttons: some View {
        VStack(spacing: 11) {
            Button("PLAY", action: play).buttonStyle(NeonButtonStyle(tint: profile.selectedArena.accentColor)).accessibilityIdentifier("menu.play")
            HStack(spacing: 10) {
                Button(action: shop) { Label("SHOP", systemImage: "bag.fill") }.buttonStyle(NeonButtonStyle(tint: .pink, compact: true))
                Button(action: challenges) {
                    ZStack(alignment: .topTrailing) {
                        Label("MISSIONS", systemImage: "scope")
                        if readyChallenges > 0 {
                            Text("\(readyChallenges)").font(.caption2.bold()).foregroundStyle(.black)
                                .frame(width: 18, height: 18).background(.yellow, in: Circle()).offset(x: 8, y: -8)
                        }
                    }
                }
                .buttonStyle(NeonButtonStyle(tint: .purple, compact: true))
                Button(action: achievements) { Image(systemName: "trophy.fill") }
                    .buttonStyle(NeonButtonStyle(tint: .orange, compact: true)).frame(width: 62)
                    .accessibilityIdentifier("menu.achievements")
            }
            HStack(spacing: 10) {
                Button(action: season) { Label("SEASON", systemImage: "sparkles") }
                    .buttonStyle(NeonButtonStyle(tint: .cyan, compact: true))
                    .accessibilityIdentifier("menu.season")
                Button(action: practice) { Label(profile.tutorialRunCompleted ? "PRACTICE" : "TRAINING", systemImage: "figure.run") }
                    .buttonStyle(NeonButtonStyle(tint: .green, compact: true))
                    .accessibilityIdentifier("menu.practice")
            }
        }
        .padding(.horizontal, 20)
    }

    private var dailyRewardCard: some View {
        GlassCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(.yellow.opacity(0.12)).frame(width: 46, height: 46)
                    Image(systemName: "calendar.badge.plus").foregroundStyle(.yellow)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("DAILY SIGNAL • DAY \(max(1, profile.nextLoginStreak))").font(.caption.bold()).foregroundStyle(.yellow)
                    Text("Claim \(profile.nextDailyReward) coins").font(.subheadline).foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
                Button("CLAIM") { _ = profile.claimDailyReward() }
                    .buttonStyle(NeonButtonStyle(tint: .yellow, compact: true)).frame(width: 96)
            }
        }
        .padding(.horizontal, 20)
    }

    private var runSummary: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: "timer").font(.title2).foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 3) {
                    Text("BEST RUN").font(.caption2.bold()).foregroundStyle(.white.opacity(0.55))
                    Text(format(profile.bestTime)).font(.system(.headline, design: .monospaced).weight(.semibold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("HIGH SCORE").font(.caption2.bold()).foregroundStyle(.white.opacity(0.55))
                    Text("\(profile.bestScore)").font(.headline.monospacedDigit()).foregroundStyle(.yellow)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func format(_ value: TimeInterval) -> String {
        let minutes = Int(value) / 60
        let seconds = Int(value) % 60
        let centis = Int((value - floor(value)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, centis)
    }
}
