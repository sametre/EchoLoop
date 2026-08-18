import SwiftUI

struct ProfileView: View {
    @ObservedObject var profile: PlayerProfile
    let close: () -> Void

    var body: some View {
        ZStack {
            NeonBackground()
            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        Button(action: close) { Image(systemName: "chevron.left").padding(12).background(.white.opacity(0.08), in: Circle()) }
                        Spacer(); Text("PROFILE").font(.title2.bold()).tracking(2); Spacer(); Color.clear.frame(width: 44, height: 44)
                    }
                    .foregroundStyle(.white)

                    GlassCard {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle().stroke(profile.selectedArena.accentColor.opacity(0.7), lineWidth: 2).frame(width: 112, height: 112)
                                Circle().fill(profile.selectedOrb.primaryColor).frame(width: 34, height: 34).shadow(color: profile.selectedOrb.secondaryColor, radius: 18)
                            }
                            Text("LEVEL \(profile.level)").font(.title2.bold())
                            ProgressView(value: profile.levelProgress).tint(profile.selectedArena.accentColor)
                            Text("\(profile.xpIntoLevel) / 500 XP").font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.55))
                        }
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statCard("BEST RUN", format(profile.bestTime), "timer")
                        statCard("HIGH SCORE", "\(profile.bestScore)", "star.fill")
                        statCard("RUNS", "\(profile.lifetimeRuns)", "play.circle")
                        statCard("PLAY TIME", formatLong(profile.lifetimeSeconds), "clock")
                        statCard("SHARDS", "\(profile.lifetimeShards)", "diamond.fill")
                        statCard("CLOSE CALLS", "\(profile.lifetimeCloseCalls)", "bolt.fill")
                        statCard("DASHES", "\(profile.lifetimeDashes)", "forward.fill")
                        statCard("MAX STAGE", "\(profile.highestStage)", "chart.line.uptrend.xyaxis")
                        statCard("LOGIN STREAK", "\(profile.loginStreak)", "flame.fill")
                        statCard("COINS", "\(profile.coins)", "hexagon.fill")
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("EQUIPPED").font(.caption.bold()).foregroundStyle(.pink)
                            HStack {
                                Label(profile.selectedOrb.name, systemImage: "circle.fill")
                                Spacer()
                                Label(profile.selectedTrail.name, systemImage: "scribble.variable")
                                Spacer()
                                Label(profile.selectedArena.name, systemImage: "square.grid.3x3.fill")
                            }
                            .font(.caption).foregroundStyle(.white.opacity(0.72))
                        }
                    }
                }
                .padding(20)
                .foregroundStyle(.white)
            }
        }
    }

    private func statCard(_ title: String, _ value: String, _ symbol: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: symbol).foregroundStyle(profile.selectedArena.accentColor)
                Text(value).font(.headline.monospacedDigit())
                Text(title).font(.caption2.bold()).foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func format(_ value: TimeInterval) -> String {
        let minutes = Int(value) / 60
        let seconds = Int(value) % 60
        let centis = Int((value - floor(value)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, centis)
    }

    private func formatLong(_ value: TimeInterval) -> String {
        let total = Int(value)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
