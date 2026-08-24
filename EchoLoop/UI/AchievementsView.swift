import SwiftUI

struct AchievementsView: View {
    @ObservedObject var profile: PlayerProfile
    @ObservedObject private var gameCenter = GameCenterManager.shared
    let close: () -> Void

    private var completedCount: Int {
        AchievementCatalog.all.filter { $0.progress(using: profile.achievementSnapshot) >= 1 }.count
    }

    var body: some View {
        ZStack {
            NeonBackground()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    summary
                    LazyVStack(spacing: 12) {
                        ForEach(AchievementCatalog.all) { achievement in
                            achievementCard(achievement)
                        }
                    }

                    Button {
                        GameCenterManager.shared.showDashboard()
                    } label: {
                        Label("OPEN GAME CENTER", systemImage: "trophy.fill")
                    }
                    .buttonStyle(NeonButtonStyle(tint: .orange))
                    .accessibilityIdentifier("achievements.gameCenter")
                }
                .padding(20)
                .padding(.bottom, 30)
            }
        }
        .foregroundStyle(.white)
        .accessibilityIdentifier("achievements.screen")
    }

    private var header: some View {
        HStack {
            Button(action: close) {
                Image(systemName: "chevron.left")
                    .font(.headline.bold())
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.35), in: Circle())
            }
            .accessibilityIdentifier("achievements.close")

            VStack(alignment: .leading, spacing: 2) {
                Text("ACHIEVEMENTS").font(.title2.bold())
                Text("Master the loop, not just the leaderboard.")
                    .font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
    }

    private var summary: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(.purple.opacity(0.16)).frame(width: 58, height: 58)
                    Image(systemName: "trophy.fill").font(.title2).foregroundStyle(.yellow)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("PROGRESSION").font(.caption.bold()).foregroundStyle(.white.opacity(0.5))
                    Text("\(completedCount) / \(AchievementCatalog.all.count) COMPLETE")
                        .font(.headline.monospacedDigit())
                    ProgressView(value: Double(completedCount), total: Double(AchievementCatalog.all.count))
                        .tint(.yellow)
                }
                Spacer()
            }
        }
    }

    private func achievementCard(_ achievement: AchievementDefinition) -> some View {
        let progress = achievement.progress(using: profile.achievementSnapshot)
        let complete = progress >= 1
        return GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill((complete ? Color.yellow : Color.purple).opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: achievement.symbol)
                        .foregroundStyle(complete ? .yellow : .cyan)
                }
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(LocalizedStringKey(achievement.title)).font(.subheadline.bold())
                        Spacer()
                        Text(achievement.currentValue(using: profile.achievementSnapshot))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Text(LocalizedStringKey(achievement.subtitle)).font(.caption).foregroundStyle(.white.opacity(0.5))
                    ProgressView(value: progress).tint(complete ? .yellow : .cyan)
                }
                if complete {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.yellow)
                }
            }
        }
        .accessibilityIdentifier("achievement.\(achievement.id)")
    }

}
