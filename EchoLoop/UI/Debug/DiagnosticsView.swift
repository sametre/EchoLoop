import SwiftUI

struct DiagnosticsView: View {
    @ObservedObject private var profile = PlayerProfile.shared
    @ObservedObject private var ads = AdManager.shared
    @ObservedObject private var privacy = PrivacyConsentManager.shared
    @ObservedObject private var store = StoreManager.shared
    @ObservedObject private var gameCenter = GameCenterManager.shared
    @ObservedObject private var cloud = CloudSyncManager.shared
    let close: () -> Void

    var body: some View {
        ZStack {
            NeonBackground()
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button(action: close) {
                            Image(systemName: "chevron.left")
                                .padding(12)
                                .background(.white.opacity(0.08), in: Circle())
                        }
                        Spacer()
                        Text("DIAGNOSTICS").font(.title2.bold()).tracking(2)
                        Spacer()
                        Color.clear.frame(width: 44, height: 44)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            row("VERSION", "\(AppConfig.marketingVersion) (\(AppConfig.buildNumber))", .cyan)
                            row("SAVE SCHEMA", "V\(profile.save.schemaVersion)", profile.recoveredFromBackup ? .orange : .green)
                            row("SAVE SOURCE", profile.lastLoadSource.uppercased(), profile.recoveredFromBackup ? .orange : .white)
                            row("GAME CENTER", gameCenter.isAuthenticated ? "CONNECTED" : "OFFLINE", gameCenter.isAuthenticated ? .green : .orange)
                            row("STOREKIT", store.products.isEmpty ? "NO PRODUCTS" : "\(store.products.count) PRODUCTS", store.products.isEmpty ? .orange : .green)
                            row("CONSENT", privacy.canRequestAds ? "ADS ALLOWED" : "NOT READY", privacy.canRequestAds ? .green : .orange)
                            row("ADMOB", ads.isStarted ? "STARTED" : "STOPPED", ads.isStarted ? .green : .orange)
                            row("CLOUD SYNC", cloud.state.rawValue.uppercased(), cloud.state == .ready ? .green : (cloud.state == .disabled ? .cyan : .orange))
                            row("SAVE REVISION", "\(profile.syncRevision)", .white)
                        }
                    }

                    ForEach(ConfigurationValidator.issues) { issue in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(issue.severity.rawValue)
                                    .font(.caption2.bold())
                                    .foregroundStyle(color(for: issue.severity))
                                Text(issue.title).font(.headline)
                                Text(issue.detail).font(.footnote).foregroundStyle(.white.opacity(0.62))
                            }
                        }
                    }

                    if ConfigurationValidator.issues.isEmpty {
                        GlassCard {
                            Label("No configuration issues detected.", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding(20)
                .foregroundStyle(.white)
            }
        }
    }

    private func row(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title).font(.caption.bold()).foregroundStyle(.white.opacity(0.55))
            Spacer()
            Text(value).font(.caption.bold()).foregroundStyle(color)
        }
    }

    private func color(for severity: ConfigurationIssue.Severity) -> Color {
        switch severity {
        case .info: return .cyan
        case .warning: return .orange
        case .blocking: return .red
        }
    }
}
