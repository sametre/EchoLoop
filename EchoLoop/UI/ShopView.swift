import SwiftUI
import StoreKit

enum ShopTab: String, CaseIterable, Identifiable {
    case orbs = "ORBS"
    case trails = "TRAILS"
    case arenas = "ARENAS"
    case premium = "PREMIUM"
    var id: String { rawValue }
}

struct ShopView: View {
    @ObservedObject var store: StoreManager
    @ObservedObject var profile: PlayerProfile
    let close: () -> Void
    @State private var tab: ShopTab = .orbs

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            NeonBackground()
            ScrollView {
                VStack(spacing: 18) {
                    header

                    Picker("Store section", selection: $tab) {
                        ForEach(ShopTab.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch tab {
                    case .orbs: orbGrid
                    case .trails: trailGrid
                    case .arenas: arenaGrid
                    case .premium: premiumSection
                    }
                }
                .padding(20)
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: close) {
                Image(systemName: "chevron.left").padding(12).background(.white.opacity(0.08), in: Circle())
            }
            Spacer()
            VStack(spacing: 2) {
                Text("NEON STORE").font(.title2.bold()).tracking(2)
                Text("COSMETICS ONLY • NO PAY-TO-WIN").font(.caption2).foregroundStyle(.white.opacity(0.42))
            }
            Spacer()
            CoinBadge(coins: profile.coins)
        }
        .foregroundStyle(.white)
    }

    private var orbGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(OrbCosmetic.all) { item in orbCard(item) }
        }
    }

    private var trailGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(TrailCosmetic.all) { item in trailCard(item) }
        }
    }

    private var arenaGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(ArenaCosmetic.all) { item in arenaCard(item) }
        }
    }

    private func orbCard(_ item: OrbCosmetic) -> some View {
        let owned = profile.ownsOrb(item) || (item.premiumOnly && store.premiumUnlocked)
        let selected = profile.selectedOrb.id == item.id
        return cosmeticCard(
            title: item.name,
            price: item.price,
            premiumOnly: item.premiumOnly,
            owned: owned,
            selected: selected,
            preview: AnyView(
                ZStack {
                    Circle().stroke(item.secondaryColor.opacity(0.5), lineWidth: 2).frame(width: 70, height: 70)
                    Circle().fill(item.primaryColor).frame(width: 26, height: 26).shadow(color: item.secondaryColor, radius: 16)
                }
            ),
            action: {
                if item.premiumOnly && !store.premiumUnlocked { tab = .premium }
                else if owned { profile.selectOrb(item, premiumUnlocked: store.premiumUnlocked) }
                else { _ = profile.buyOrb(item) }
            }
        )
    }

    private func trailCard(_ item: TrailCosmetic) -> some View {
        let owned = profile.ownsTrail(item) || (item.premiumOnly && store.premiumUnlocked)
        let selected = profile.selectedTrail.id == item.id
        return cosmeticCard(
            title: item.name,
            price: item.price,
            premiumOnly: item.premiumOnly,
            owned: owned,
            selected: selected,
            preview: AnyView(
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        Circle().fill(item.color.opacity(Double(index + 1) / 7.0)).frame(width: CGFloat(5 + index), height: CGFloat(5 + index))
                    }
                }
                .shadow(color: item.color, radius: 9)
                .frame(height: 70)
            ),
            action: {
                if item.premiumOnly && !store.premiumUnlocked { tab = .premium }
                else if owned { profile.selectTrail(item, premiumUnlocked: store.premiumUnlocked) }
                else { _ = profile.buyTrail(item) }
            }
        )
    }

    private func arenaCard(_ item: ArenaCosmetic) -> some View {
        let owned = profile.ownsArena(item) || (item.premiumOnly && store.premiumUnlocked)
        let selected = profile.selectedArena.id == item.id
        return cosmeticCard(
            title: item.name,
            price: item.price,
            premiumOnly: item.premiumOnly,
            owned: owned,
            selected: selected,
            preview: AnyView(
                ZStack {
                    RoundedRectangle(cornerRadius: 18).fill(item.backgroundColor).frame(height: 82)
                    Circle().stroke(item.accentColor.opacity(0.75), lineWidth: 2).frame(width: 55, height: 55).shadow(color: item.glowColor, radius: 10)
                    Circle().fill(item.accentColor).frame(width: 8, height: 8).offset(x: 21, y: -18)
                }
            ),
            action: {
                if item.premiumOnly && !store.premiumUnlocked { tab = .premium }
                else if owned { profile.selectArena(item, premiumUnlocked: store.premiumUnlocked) }
                else { _ = profile.buyArena(item) }
            }
        )
    }

    private func cosmeticCard(
        title: String,
        price: Int,
        premiumOnly: Bool,
        owned: Bool,
        selected: Bool,
        preview: AnyView,
        action: @escaping () -> Void
    ) -> some View {
        GlassCard {
            VStack(spacing: 11) {
                preview
                Text(title).font(.caption.bold()).lineLimit(1).minimumScaleFactor(0.7)
                Button(action: action) {
                    if selected {
                        Label("EQUIPPED", systemImage: "checkmark.circle.fill")
                    } else if premiumOnly && !store.premiumUnlocked {
                        Label("PREMIUM", systemImage: "crown.fill")
                    } else if owned {
                        Text("EQUIP")
                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: "hexagon.fill").foregroundStyle(.yellow)
                            Text("\(price)")
                        }
                    }
                }
                .buttonStyle(NeonButtonStyle(tint: selected ? .green : (premiumOnly ? .purple : .cyan), compact: true))
                .disabled(selected)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var premiumSection: some View {
        VStack(spacing: 14) {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("PREMIUM NEON PACK", systemImage: "crown.fill").font(.headline).foregroundStyle(.yellow)
                    Text("Unlock PRISM orb, NOVA trail and SINGULARITY arena. Gameplay remains identical for every player.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.65))
                    HStack(spacing: 18) {
                        Circle().fill(OrbCosmetic.item("prism").primaryColor).frame(width: 28, height: 28).shadow(color: .pink, radius: 12)
                        Image(systemName: "scribble.variable").foregroundStyle(TrailCosmetic.item("nova").color)
                        Circle().stroke(ArenaCosmetic.item("singularity").accentColor, lineWidth: 2).frame(width: 34, height: 34)
                    }
                }
            }

            if store.products.isEmpty {
                GlassCard {
                    VStack(spacing: 10) {
                        ProgressView().tint(.cyan)
                        Text("StoreKit products are not available in this build environment yet. Create the product IDs from AppConfig.swift in App Store Connect to test real purchases.")
                            .font(.footnote).foregroundStyle(.white.opacity(0.62)).multilineTextAlignment(.center)
                    }
                }
            } else {
                ForEach(store.products, id: \.id) { product in productCard(product) }
            }

            Button("RESTORE PURCHASES") { Task { await store.restore() } }
                .buttonStyle(NeonButtonStyle(tint: .purple))

            if let error = store.lastError {
                Text(error).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        let owned = store.purchasedIDs.contains(product.id)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName).font(.headline)
                        Text(product.description).font(.caption).foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    Text(product.displayPrice).font(.headline).foregroundStyle(.yellow)
                }
                Button(owned ? "OWNED" : "BUY") {
                    if !owned { Task { await store.purchase(product) } }
                }
                .buttonStyle(NeonButtonStyle(tint: owned ? .green : .pink))
                .disabled(owned)
            }
        }
    }
}
