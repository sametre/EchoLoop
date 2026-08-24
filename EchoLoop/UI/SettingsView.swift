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

                    if privacy.privacyOptionsRequired {
                        Button("PRIVACY OPTIONS") {
                            Task { await privacy.presentPrivacyOptions() }
                        }
                        .buttonStyle(NeonButtonStyle(tint: .cyan, compact: true))
                    }
                }
                .padding(20)
                .foregroundStyle(.white)
            }
        }
    }

    private func toggle(_ title: String, _ symbol: String, _ binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.title3)
                    .frame(width: 28, alignment: .center)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .tint(.cyan)
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(.horizontal, 2)
    }

}
