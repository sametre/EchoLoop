import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var store = StoreManager.shared
    @ObservedObject private var gameCenter = GameCenterManager.shared
    @ObservedObject private var profile = PlayerProfile.shared
    @ObservedObject private var privacy = PrivacyConsentManager.shared
    @ObservedObject private var ads = AdManager.shared
    @State private var showDiagnostics = false
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
                        VStack(alignment: .leading, spacing: 13) {
                            status("GAME CENTER", gameCenter.isAuthenticated ? "CONNECTED" : "NOT CONNECTED", gameCenter.isAuthenticated ? .green : .orange, "trophy.fill")
                            status("ADS", adsStatusText, adsStatusColor, "rectangle.on.rectangle")
                            status("STOREKIT", storeStatusText, store.products.isEmpty ? .orange : .green, "apple.logo")
                            status("SAVE SCHEMA", "V\(profile.save.schemaVersion)", profile.lastSaveSucceeded ? .green : .red, "externaldrive.fill.badge.checkmark")
                            if profile.recoveredFromBackup {
                                status("SAVE RECOVERY", "RECOVERED FROM BACKUP", .orange, "arrow.counterclockwise.circle.fill")
                            }
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

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("RELEASE READINESS").font(.caption.bold()).foregroundStyle(.cyan)
                            if ConfigurationValidator.issues.isEmpty {
                                Label("No configuration issues detected.", systemImage: "checkmark.seal.fill")
                                    .font(.footnote)
                                    .foregroundStyle(.green)
                            } else {
                                ForEach(ConfigurationValidator.issues.prefix(3)) { issue in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: issue.severity == .blocking ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                                            .foregroundStyle(issue.severity == .blocking ? .red : .orange)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(issue.title).font(.footnote.bold())
                                            Text(issue.detail).font(.caption2).foregroundStyle(.white.opacity(0.55))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    #if DEBUG
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DEVELOPER TOOLS").font(.caption.bold()).foregroundStyle(.orange)
                            Text("Local profile contains \(profile.coins) coins and Level \(profile.level). These actions are DEBUG-only.")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.58))
                            Button("OPEN DIAGNOSTICS") { showDiagnostics = true }
                                .buttonStyle(NeonButtonStyle(tint: .cyan, compact: true))
                            Button("RESET LOCAL PROGRESS") { profile.resetProgressForDevelopment() }
                                .buttonStyle(NeonButtonStyle(tint: .red, compact: true))
                            Button("SHOW ONBOARDING AGAIN") {
                                settings.resetOnboardingForDevelopment()
                                close()
                            }
                            .buttonStyle(NeonButtonStyle(tint: .purple, compact: true))
                            Button("RESET CONSENT TEST STATE") { privacy.resetConsentForDevelopment() }
                                .buttonStyle(NeonButtonStyle(tint: .orange, compact: true))
                        }
                    }
                    #endif

                    Text("ECHO LOOP • V10 RELEASE CANDIDATE • \(AppConfig.marketingVersion) (\(AppConfig.buildNumber))")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.34))
                        .padding(.top, 8)
                }
                .padding(20)
                .foregroundStyle(.white)
            }
        }
        #if DEBUG
        .fullScreenCover(isPresented: $showDiagnostics) {
            DiagnosticsView(close: { showDiagnostics = false })
        }
        #endif
    }

    private var adsStatusText: String {
        if store.adsRemoved { return "REMOVED" }
        if !ConfigurationValidator.adsMayStart { return "BLOCKED BY CONFIG" }
        if ads.isStarted { return "READY" }
        return privacy.canRequestAds ? "STARTING" : "WAITING FOR CONSENT"
    }

    private var adsStatusColor: Color {
        if store.adsRemoved { return .green }
        if !ConfigurationValidator.adsMayStart { return .red }
        if ads.isStarted { return .cyan }
        return .orange
    }

    private var storeStatusText: String {
        if store.isLoadingProducts { return "LOADING" }
        return store.products.isEmpty ? "WAITING FOR PRODUCTS" : "READY"
    }

    private func toggle(_ title: String, _ symbol: String, _ binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Label(title, systemImage: symbol).font(.subheadline.weight(.semibold))
        }
        .tint(.cyan)
        .padding(.vertical, 12)
    }

    private func status(_ title: String, _ value: String, _ color: Color, _ symbol: String) -> some View {
        HStack {
            Label(title, systemImage: symbol).font(.subheadline.weight(.semibold))
            Spacer()
            Text(value).font(.caption.bold()).foregroundStyle(color)
        }
    }
}
