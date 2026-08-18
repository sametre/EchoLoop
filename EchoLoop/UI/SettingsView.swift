import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var privacy = PrivacyConsentManager.shared
    let close: () -> Void

    var body: some View {
        ZStack {
            NeonBackground()
            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        Button(action: close) {
                            Image(systemName: "chevron.left")
                                .padding(12)
                                .background(.white.opacity(0.08), in: Circle())
                        }
                        Spacer()
                        Text("SETTINGS").font(.title2.bold()).tracking(2)
                        Spacer()
                        Color.clear.frame(width: 44, height: 44)
                    }

                    GlassCard {
                        VStack(spacing: 0) {
                            toggle("HAPTIC FEEDBACK", "iphone.radiowaves.left.and.right", $settings.hapticsEnabled)
                            Divider().overlay(.white.opacity(0.08))
                            toggle("SOUND EFFECTS", "speaker.wave.2.fill", $settings.soundEffectsEnabled)
                            Divider().overlay(.white.opacity(0.08))
                            toggle("AMBIENT MUSIC", "music.note", $settings.musicEnabled)
                            Divider().overlay(.white.opacity(0.08))
                            toggle("REDUCE MOTION", "figure.walk.motion", $settings.reducedMotion)
                            Divider().overlay(.white.opacity(0.08))
                            toggle("ADAPTIVE EFFECTS", "gauge.with.dots.needle.67percent", $settings.autoPerformance)
                            Divider().overlay(.white.opacity(0.08))
                            toggle("GAMEPLAY HINTS", "lightbulb.fill", $settings.tutorialHints)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 11) {
                            Text("PRIVACY").font(.caption.bold()).foregroundStyle(.pink)
                            Text(privacy.lastError ?? "Consent is refreshed on app launch. Ads only initialize after the consent SDK reports that ad requests are allowed.")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.62))
                            if privacy.privacyOptionsRequired {
                                Button("PRIVACY OPTIONS") {
                                    Task { await privacy.presentPrivacyOptions() }
                                }
                                .buttonStyle(NeonButtonStyle(tint: .cyan, compact: true))
                            }
                        }
                    }

                    Text("ECHO LOOP • \(AppConfig.marketingVersion) (\(AppConfig.buildNumber))")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.34))
                        .padding(.top, 8)
                }
                .padding(20)
                .foregroundStyle(.white)
            }
        }
    }

    private func toggle(_ title: String, _ symbol: String, _ binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Label(title, systemImage: symbol).font(.subheadline.weight(.semibold))
        }
        .tint(.cyan)
        .padding(.vertical, 12)
    }

}
