import SpriteKit
import UIKit

final class EchoScene: SKScene {
    weak var session: GameSession?

    private let profile = PlayerProfile.shared
    private let settings = SettingsStore.shared
    private let player = SKShapeNode(circleOfRadius: 11)
    private let arenaFrame = SKShapeNode()

    private var playerTrail: SKEmitterNode?
    private var targetPoint = CGPoint.zero
    private var previousUpdate: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var simulationTime: TimeInterval = 0
    private var segmentStart: TimeInterval = 0
    private var lastSampleTime: TimeInterval = 0
    private var lastShardSpawn: TimeInterval = 0
    private var lastHazardSpawn: TimeInterval = 0
    private var lastArenaEventSpawn: TimeInterval = 0
    private var arenaEventIndex = 0
    private var activeArenaEvent: ArenaEventKind?
    private var activeArenaEventEndsAt: TimeInterval = 0
    private var blackoutOverlay: SKSpriteNode?
    private var activeBossEncounter: BossEchoKind?
    private var bossEncounterEndsAt: TimeInterval = 0
    private var lastBossEncounterStage = 0
    private var bossHalo: SKShapeNode?
    private var nextDashAvailable: TimeInterval = 0
    private var invulnerableUntil: TimeInterval = 0
    private var renderedStage = 0
    private var qualityController = AdaptiveQualityController()
    private var renderingQuality: RenderingQuality = .high

    private var currentPath: [(t: TimeInterval, p: CGPoint)] = []
    private var echoes: [SKShapeNode] = []
    private var shards: [SKShapeNode] = []
    private var pulseMines: [SKShapeNode] = []
    private var closeCallCooldown: [ObjectIdentifier: TimeInterval] = [:]
    private var starsAdded = false

    convenience init(session: GameSession) {
        self.init(size: CGSize(width: 390, height: 844))
        self.session = session
        scaleMode = .resizeFill
        backgroundColor = profile.selectedArena.uiBackground
        anchorPoint = .zero
        configureArena()
        configurePlayer()
    }

    override func didMove(to view: SKView) {
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true
        view.preferredFramesPerSecond = 60
        if !starsAdded {
            addStars()
            starsAdded = true
        }
        resetSceneState()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        updateArenaFrame(animated: false)
        player.position = clamped(player.position)
        targetPoint = clamped(targetPoint)
    }

    private func configureArena() {
        arenaFrame.fillColor = .clear
        arenaFrame.lineWidth = 1.3
        arenaFrame.zPosition = -2
        addChild(arenaFrame)
        updateArenaFrame(animated: false)
    }

    private func configurePlayer() {
        let orb = profile.selectedOrb
        player.fillColor = orb.uiPrimary
        player.strokeColor = orb.uiSecondary
        player.lineWidth = 2
        player.glowWidth = 9
        player.zPosition = 100
        addChild(player)

        let trailStyle = profile.selectedTrail
        let trail = SKEmitterNode()
        trail.particleBirthRate = trailStyle.birthRate
        trail.particleLifetime = trailStyle.lifetime
        trail.particleSpeed = 0
        trail.particleAlpha = 0.7
        trail.particleAlphaSpeed = -1.35
        trail.particleScale = 0.075
        trail.particleScaleSpeed = -0.05
        trail.particleColor = trailStyle.uiColor
        trail.particleTexture = VisualEffectsFactory.particleTexture()
        trail.targetNode = self
        trail.zPosition = 70
        player.addChild(trail)
        playerTrail = trail
    }

    private func addStars() {
        let arena = profile.selectedArena
        let starCount = SceneComplexityPolicy.starCount(quality: renderingQuality, reducedMotion: settings.reducedMotion)
        for _ in 0..<starCount {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.35...1.2))
            let useAccent = Bool.random()
            dot.fillColor = (useAccent ? arena.uiAccent : UIColor.white).withAlphaComponent(CGFloat.random(in: 0.10...0.50))
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat.random(in: 0...max(size.width, 1)), y: CGFloat.random(in: 0...max(size.height, 1)))
            dot.zPosition = -6
            addChild(dot)
        }

        for scale in [0.20, 0.31, 0.43] {
            let ring = SKShapeNode(circleOfRadius: min(size.width, size.height) * scale)
            ring.strokeColor = arena.uiGlow.withAlphaComponent(0.10)
            ring.lineWidth = 1
            ring.position = CGPoint(x: size.width / 2, y: size.height / 2)
            ring.zPosition = -4
            addChild(ring)
        }
    }

    func resetSceneState() {
        echoes.forEach { $0.removeFromParent() }
        echoes.removeAll()
        shards.forEach { $0.removeFromParent() }
        shards.removeAll()
        pulseMines.forEach { $0.removeFromParent() }
        pulseMines.removeAll()
        closeCallCooldown.removeAll()

        player.position = CGPoint(x: size.width / 2, y: size.height * 0.48)
        targetPoint = player.position
        previousUpdate = 0
        lastUpdateTime = 0
        simulationTime = 0
        segmentStart = 0
        lastSampleTime = 0
        lastShardSpawn = 0
        lastHazardSpawn = 0
        lastArenaEventSpawn = 0
        arenaEventIndex = 0
        clearArenaEvent(registerSurvival: false)
        clearBossEncounter(registerSurvival: false)
        lastBossEncounterStage = 0
        nextDashAvailable = 0
        invulnerableUntil = 0
        renderedStage = 0
        qualityController.reset()
        renderingQuality = .high
        currentPath = []
        player.alpha = 1
        updateArenaFrame(animated: false)
    }

    func revivePlayer() {
        echoes.forEach { $0.removeFromParent() }
        echoes.removeAll()
        shards.forEach { $0.removeFromParent() }
        shards.removeAll()
        pulseMines.forEach { $0.removeFromParent() }
        pulseMines.removeAll()
        closeCallCooldown.removeAll()
        currentPath.removeAll()

        player.position = CGPoint(x: size.width / 2, y: size.height * 0.48)
        targetPoint = player.position
        segmentStart = lastUpdateTime
        lastSampleTime = lastUpdateTime
        lastShardSpawn = lastUpdateTime
        lastHazardSpawn = lastUpdateTime
        lastArenaEventSpawn = lastUpdateTime
        clearArenaEvent(registerSurvival: false)
        clearBossEncounter(registerSurvival: false)
        nextDashAvailable = lastUpdateTime
        invulnerableUntil = lastUpdateTime + 1.1
        player.alpha = 1
        spawnBurst(at: player.position, color: profile.selectedOrb.uiSecondary, count: 34)
        Haptics.success()
        AudioManager.shared.play(.revive)
    }

    func performDash() {
        guard let session, session.canDash, !session.isGameOver, !session.isPaused else { return }
        let now = lastUpdateTime
        guard now >= nextDashAvailable else { return }

        var dx = targetPoint.x - player.position.x
        var dy = targetPoint.y - player.position.y
        var distance = hypot(dx, dy)
        if distance < 4 {
            dx = 0
            dy = 1
            distance = 1
        }

        let start = player.position
        let destination = clamped(CGPoint(
            x: player.position.x + (dx / distance) * AppConfig.Game.dashDistance,
            y: player.position.y + (dy / distance) * AppConfig.Game.dashDistance
        ))

        player.position = destination
        targetPoint = destination
        nextDashAvailable = now + AppConfig.Game.dashCooldown
        invulnerableUntil = now + AppConfig.Game.dashInvulnerability
        session.dashCooldownRemaining = AppConfig.Game.dashCooldown
        spawnBurst(at: start, color: profile.selectedTrail.uiColor, count: settings.reducedMotion ? 8 : 22)
        spawnBurst(at: destination, color: profile.selectedOrb.uiSecondary, count: settings.reducedMotion ? 8 : 18)
        session.registerDash()
        Haptics.dash()
        AudioManager.shared.play(.dash)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { updateTarget(touches) }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { updateTarget(touches) }

    private func updateTarget(_ touches: Set<UITouch>) {
        guard let touch = touches.first, session?.isGameOver == false, session?.isPaused == false else { return }
        targetPoint = clamped(touch.location(in: self))
    }

    private func gameplayMargin() -> CGFloat {
        guard let session else { return 28 }
        return GameRules.gameplayMargin(stage: session.difficultyStage)
    }

    private func clamped(_ point: CGPoint) -> CGPoint {
        let margin = gameplayMargin()
        let topInset: CGFloat = 92
        let bottomInset: CGFloat = 50
        return CGPoint(
            x: min(max(point.x, margin), max(margin, size.width - margin)),
            y: min(max(point.y, margin + bottomInset), max(margin + bottomInset, size.height - margin - topInset))
        )
    }

    override func update(_ currentTime: TimeInterval) {
        guard let session else { return }
        guard !session.isPaused, !session.isGameOver else { return }

        if previousUpdate == 0 {
            previousUpdate = currentTime
            segmentStart = simulationTime
            lastSampleTime = simulationTime
            lastShardSpawn = simulationTime
            lastHazardSpawn = simulationTime
            lastArenaEventSpawn = simulationTime
            currentPath = [(0, player.position)]
            updateArenaFrame(animated: false)
            return
        }

        let rawDelta = currentTime - previousUpdate
        let previousQuality = renderingQuality
        renderingQuality = qualityController.observe(frameDelta: rawDelta, enabled: settings.autoPerformance)
        if renderingQuality != previousQuality { applyRenderingQuality() }
        let dt = GameRules.clampedFrameDelta(rawDelta)
        previousUpdate = currentTime
        simulationTime += dt
        lastUpdateTime = simulationTime
        let now = simulationTime
        session.tick(delta: dt)
        session.dashCooldownRemaining = max(0, nextDashAvailable - now)

        if renderedStage != session.difficultyStage {
            renderedStage = session.difficultyStage
            updateArenaFrame(animated: !settings.reducedMotion)
            if renderedStage > 1 {
                Haptics.levelUp()
                AudioManager.shared.play(.levelUp)
            }
        }

        movePlayer(dt: dt)
        player.position = clamped(player.position)
        targetPoint = clamped(targetPoint)
        samplePath(at: now)

        if now - segmentStart >= session.currentEchoInterval {
            spawnEcho(from: currentPath, at: now)
            segmentStart = now
            lastSampleTime = now
            currentPath = [(0, player.position)]
            Haptics.echoSpawn()
            AudioManager.shared.play(.echoSpawn)
        }

        if now - lastShardSpawn >= AppConfig.Game.shardSpawnInterval, shards.count < AppConfig.Game.maximumShardsOnScreen {
            spawnShard()
            lastShardSpawn = now
        }

        let hazardInterval = GameRules.hazardInterval(stage: session.difficultyStage)
        if session.difficultyStage >= AppConfig.Game.hazardStartStage, now - lastHazardSpawn >= hazardInterval, pulseMines.count < 2 {
            spawnPulseMine(at: now)
            lastHazardSpawn = now
        }

        updateBossEncounter(at: now)
        updateArenaEvent(at: now)
        collectShards()
        updatePulseMines(at: now)
        if session.isGameOver { return }
        checkCollisions(at: now)
    }

    private func movePlayer(dt: TimeInterval) {
        let dx = targetPoint.x - player.position.x
        let dy = targetPoint.y - player.position.y
        let distance = hypot(dx, dy)
        guard distance > 0.5 else { return }
        let maxStep = AppConfig.Game.playerSpeed * CGFloat(dt)
        let step = min(distance, maxStep)
        player.position.x += dx / distance * step
        player.position.y += dy / distance * step
    }

    private func samplePath(at time: TimeInterval) {
        guard time - lastSampleTime >= 0.07 else { return }
        currentPath.append((time - segmentStart, player.position))
        lastSampleTime = time
    }

    private func spawnEcho(from samples: [(t: TimeInterval, p: CGPoint)], at time: TimeInterval) {
        guard samples.count >= 2, let session else { return }
        let spawnIndex = session.echoCount + 1
        let boss = activeBossEncounter
        let kind = boss?.echoKind ?? EchoKind.kind(forSpawnIndex: spawnIndex, stage: session.difficultyStage)
        let transformedSamples: [(t: TimeInterval, p: CGPoint)]

        if kind == .mirror {
            transformedSamples = samples.map { sample in
                (sample.t, clamped(CGPoint(x: size.width - sample.p.x, y: sample.p.y)))
            }
        } else {
            transformedSamples = samples
        }

        let baseRadius: CGFloat = kind == .hunter ? 11.5 : 10
        let ghostRadius = baseRadius * (boss?.scaleMultiplier ?? 1)
        let ghost = SKShapeNode(circleOfRadius: ghostRadius)
        ghost.fillColor = kind.color.withAlphaComponent(kind == .phase ? 0.55 : 0.88)
        ghost.strokeColor = UIColor.white.withAlphaComponent(0.82)
        ghost.lineWidth = boss == nil ? (kind.isSpecial ? 1.8 : 1.4) : 2.4
        ghost.glowWidth = boss == nil ? (kind.isSpecial ? 11 : 7) : 18
        ghost.position = transformedSamples[0].p
        ghost.zPosition = 80
        ghost.name = boss.map { "bossEcho.\($0.rawValue)" } ?? "echo.\(kind.rawValue)"
        ghost.userData = NSMutableDictionary()
        ghost.userData?["collisionMultiplier"] = NSNumber(value: Double(kind.collisionRadiusMultiplier * (boss?.collisionMultiplier ?? 1)))
        ghost.userData?["kind"] = kind.rawValue
        if kind == .phase {
            ghost.userData?["collisionEnabledAt"] = NSNumber(value: time + AppConfig.Game.phaseCollisionDelay)
        }
        addChild(ghost)
        echoes.append(ghost)
        enforceEchoBudget()

        let trail = SKEmitterNode()
        let baseBirthRate: CGFloat = kind.isSpecial ? 70 : 55
        trail.particleBirthRate = SceneComplexityPolicy.trailBirthRate(base: baseBirthRate, quality: renderingQuality, reducedMotion: settings.reducedMotion)
        trail.particleLifetime = settings.reducedMotion ? 0.22 : 0.45
        trail.particleSpeed = 0
        trail.particleAlpha = kind == .phase ? 0.38 : 0.56
        trail.particleAlphaSpeed = -1.2
        trail.particleScale = kind.isSpecial ? 0.085 : 0.07
        trail.particleScaleSpeed = -0.05
        trail.particleColor = kind.color
        trail.particleTexture = VisualEffectsFactory.particleTexture()
        trail.targetNode = self
        ghost.addChild(trail)

        if kind.isSpecial, renderingQuality != .low || boss != nil {
            ghost.addChild(VisualEffectsFactory.makeEchoAura(
                radius: ghostRadius + 8,
                color: kind.color,
                reducedMotion: settings.reducedMotion
            ))
        }

        if kind == .phase, !settings.reducedMotion {
            ghost.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.28, duration: 0.22),
                .fadeAlpha(to: 0.9, duration: 0.22)
            ])), withKey: "phasePulse")
        }

        let speedFactor = GameRules.echoSpeedFactor(stage: session.difficultyStage) * kind.speedMultiplier * (boss?.speedMultiplier ?? 1)
        var actions: [SKAction] = []
        for i in 1..<transformedSamples.count {
            let duration = max(0.018, (transformedSamples[i].t - transformedSamples[i - 1].t) * speedFactor)
            actions.append(SKAction.move(to: transformedSamples[i].p, duration: duration))
        }
        guard !actions.isEmpty else {
            ghost.removeFromParent()
            echoes.removeAll(where: { $0 === ghost })
            return
        }

        if activeArenaEvent == .overdrive {
            ghost.speed = AppConfig.Game.overdriveSpeedMultiplier
        }
        ghost.run(.repeatForever(.sequence(actions)), withKey: "echoPath")
        session.registerEchoSpawn(kind: kind)

        if kind.isSpecial || boss != nil {
            let effectColor = boss?.tint ?? kind.color
            spawnBurst(at: ghost.position, color: effectColor, count: settings.reducedMotion ? 8 : (boss == nil ? 22 : 34))
            if let boss {
                AppLogger.gameplay.notice("Spawned boss echo: \(boss.rawValue, privacy: .public)")
            } else {
                AppLogger.gameplay.debug("Spawned special echo: \(kind.rawValue, privacy: .public)")
            }
        }
    }

    private func spawnShard() {
        let margin = gameplayMargin() + 22
        let minY = margin + 50
        let maxY = max(minY, size.height - margin - 92)
        var point = CGPoint(x: CGFloat.random(in: margin...max(margin, size.width - margin)), y: CGFloat.random(in: minY...maxY))
        if hypot(point.x - player.position.x, point.y - player.position.y) < 90 {
            point.x = point.x < size.width / 2 ? min(size.width - margin, point.x + 110) : max(margin, point.x - 110)
        }

        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 12))
        path.addLine(to: CGPoint(x: 9, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -12))
        path.addLine(to: CGPoint(x: -9, y: 0))
        path.closeSubpath()

        let shard = SKShapeNode(path: path)
        shard.fillColor = profile.selectedArena.uiAccent.withAlphaComponent(0.9)
        shard.strokeColor = .white
        shard.lineWidth = 1.2
        shard.glowWidth = 8
        shard.position = point
        shard.zPosition = 60
        addChild(shard)
        shards.append(shard)

        if !settings.reducedMotion {
            shard.run(.repeatForever(.sequence([
                .group([.rotate(byAngle: .pi, duration: 1.15), .scale(to: 1.18, duration: 0.58)]),
                .scale(to: 0.92, duration: 0.58)
            ])))
        }
    }

    private func collectShards() {
        guard let session else { return }
        for shard in shards.reversed() {
            let distance = hypot(player.position.x - shard.position.x, player.position.y - shard.position.y)
            if distance <= 25 {
                spawnBurst(at: shard.position, color: profile.selectedArena.uiAccent, count: settings.reducedMotion ? 7 : 18)
                shard.removeFromParent()
                shards.removeAll(where: { $0 === shard })
                session.registerShard()
                Haptics.shard()
                AudioManager.shared.play(.shard)
            }
        }
    }

    private func spawnPulseMine(at time: TimeInterval) {
        guard let session else { return }
        let margin = gameplayMargin() + AppConfig.Game.hazardRadius + 10
        let minY = margin + 48
        let maxY = max(minY, size.height - margin - 92)
        var point = CGPoint(
            x: CGFloat.random(in: margin...max(margin, size.width - margin)),
            y: CGFloat.random(in: minY...maxY)
        )
        if hypot(point.x - player.position.x, point.y - player.position.y) < 130 {
            point.x = point.x < size.width / 2 ? min(size.width - margin, point.x + 145) : max(margin, point.x - 145)
        }

        let mine = SKShapeNode(circleOfRadius: AppConfig.Game.hazardRadius)
        mine.position = point
        mine.fillColor = UIColor.systemPink.withAlphaComponent(0.045)
        mine.strokeColor = UIColor.systemPink.withAlphaComponent(0.7)
        mine.lineWidth = 1.4
        mine.glowWidth = 6
        mine.zPosition = 45
        mine.alpha = 0.5
        mine.name = "pulseMine"
        mine.userData = NSMutableDictionary()
        mine.userData?["activeAt"] = time + AppConfig.Game.hazardWarningDuration
        mine.userData?["expiresAt"] = time + AppConfig.Game.hazardWarningDuration + AppConfig.Game.hazardActiveDuration
        mine.userData?["threatened"] = false

        let core = SKShapeNode(circleOfRadius: 5)
        core.fillColor = .systemPink
        core.strokeColor = .white
        core.glowWidth = 8
        mine.addChild(core)

        let ring = SKShapeNode(circleOfRadius: AppConfig.Game.hazardRadius * 0.55)
        ring.strokeColor = UIColor.systemPink.withAlphaComponent(0.8)
        ring.lineWidth = 1
        ring.name = "warningRing"
        mine.addChild(ring)

        addChild(mine)
        pulseMines.append(mine)

        if !settings.reducedMotion {
            ring.run(.repeatForever(.sequence([
                .group([.scale(to: 1.65, duration: 0.48), .fadeAlpha(to: 0.08, duration: 0.48)]),
                .group([.scale(to: 0.72, duration: 0.01), .fadeAlpha(to: 0.9, duration: 0.01)])
            ])))
        }

        let stageBoost = min(0.3, CGFloat(max(0, session.difficultyStage - AppConfig.Game.hazardStartStage)) * 0.04)
        mine.run(.sequence([
            .wait(forDuration: AppConfig.Game.hazardWarningDuration),
            .run { [weak mine] in
                mine?.fillColor = UIColor.systemPink.withAlphaComponent(0.22 + stageBoost)
                mine?.strokeColor = .white
                mine?.glowWidth = 14
            },
            .wait(forDuration: AppConfig.Game.hazardActiveDuration),
            .fadeOut(withDuration: 0.15)
        ]))
    }

    private func updatePulseMines(at time: TimeInterval) {
        guard let session else { return }
        for mine in pulseMines.reversed() {
            guard let activeAt = mine.userData?["activeAt"] as? TimeInterval,
                  let expiresAt = mine.userData?["expiresAt"] as? TimeInterval else { continue }

            let distance = hypot(player.position.x - mine.position.x, player.position.y - mine.position.y)
            if distance < AppConfig.Game.hazardRadius + 60 { mine.userData?["threatened"] = true }

            if time >= activeAt, time <= expiresAt, time >= invulnerableUntil, distance <= AppConfig.Game.hazardRadius {
                spawnBurst(at: player.position, color: .systemPink, count: settings.reducedMotion ? 12 : 40)
                Haptics.death()
                AudioManager.shared.play(.death)
                session.finishLife()
                return
            }

            if time > expiresAt {
                let threatened = (mine.userData?["threatened"] as? Bool) ?? false
                if threatened { session.registerHazardDodge() }
                mine.removeFromParent()
                pulseMines.removeAll(where: { $0 === mine })
            }
        }
    }

    private func updateBossEncounter(at time: TimeInterval) {
        guard let session else { return }

        if let boss = activeBossEncounter {
            if time >= bossEncounterEndsAt {
                finishBossEncounter(boss)
            }
            return
        }

        guard BossEncounterDirector.shouldStart(stage: session.difficultyStage, lastStartedStage: lastBossEncounterStage) else { return }
        startBossEncounter(BossEncounterDirector.boss(for: session.difficultyStage), at: time)
    }

    private func startBossEncounter(_ boss: BossEchoKind, at time: TimeInterval) {
        guard let session else { return }
        clearArenaEvent(registerSurvival: false)
        activeBossEncounter = boss
        bossEncounterEndsAt = time + boss.duration
        lastBossEncounterStage = session.difficultyStage
        session.bossEncounterStarted(boss)

        let halo = SKShapeNode(circleOfRadius: min(size.width, size.height) * 0.36)
        halo.position = CGPoint(x: size.width / 2, y: size.height / 2)
        halo.strokeColor = boss.tint.withAlphaComponent(0.7)
        halo.lineWidth = 2
        halo.glowWidth = 15
        halo.fillColor = .clear
        halo.zPosition = -1
        addChild(halo)
        bossHalo = halo
        if !settings.reducedMotion {
            halo.run(.repeatForever(.sequence([
                .group([.scale(to: 1.08, duration: 0.65), .fadeAlpha(to: 0.35, duration: 0.65)]),
                .group([.scale(to: 0.96, duration: 0.65), .fadeAlpha(to: 1.0, duration: 0.65)])
            ])))
        }
        spawnBurst(at: player.position, color: boss.tint, count: settings.reducedMotion ? 12 : 42)
        Haptics.levelUp()
        AudioManager.shared.play(.levelUp)
        AppLogger.gameplay.notice("Boss encounter started: \(boss.rawValue, privacy: .public)")
    }

    private func finishBossEncounter(_ boss: BossEchoKind) {
        bossHalo?.removeFromParent()
        bossHalo = nil
        activeBossEncounter = nil
        bossEncounterEndsAt = 0
        lastArenaEventSpawn = simulationTime
        session?.bossEncounterFinished(boss, survived: session?.isGameOver == false)
        if session?.isGameOver == false {
            spawnBurst(at: player.position, color: boss.tint, count: settings.reducedMotion ? 10 : 36)
            Haptics.success()
        }
        AppLogger.gameplay.notice("Boss encounter finished: \(boss.rawValue, privacy: .public)")
    }

    private func clearBossEncounter(registerSurvival: Bool) {
        if let boss = activeBossEncounter, registerSurvival {
            session?.bossEncounterFinished(boss, survived: session?.isGameOver == false)
        } else if let boss = activeBossEncounter, session?.activeBossEncounterTitle == boss.title {
            session?.activeBossEncounterTitle = nil
        }
        bossHalo?.removeFromParent()
        bossHalo = nil
        activeBossEncounter = nil
        bossEncounterEndsAt = 0
    }

    private func updateArenaEvent(at time: TimeInterval) {
        guard let session else { return }
        guard activeBossEncounter == nil else { return }

        if let event = activeArenaEvent {
            if time >= activeArenaEventEndsAt {
                finishArenaEvent(event, at: time)
            }
            return
        }

        guard session.difficultyStage >= AppConfig.Game.arenaEventStartStage else { return }
        let interval = ArenaEventDirector.interval(stage: session.difficultyStage)
        guard time - lastArenaEventSpawn >= interval else { return }

        let event = ArenaEventDirector.event(forIndex: arenaEventIndex, stage: session.difficultyStage)
        arenaEventIndex += 1
        startArenaEvent(event, at: time)
    }

    private func startArenaEvent(_ event: ArenaEventKind, at time: TimeInterval) {
        guard let session else { return }
        activeArenaEvent = event
        activeArenaEventEndsAt = time + event.duration
        session.arenaEventStarted(event)
        let pulse = VisualEffectsFactory.makeArenaEventPulse(
            radius: min(size.width, size.height) * 0.18,
            color: profile.selectedArena.uiAccent,
            reducedMotion: settings.reducedMotion
        )
        pulse.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(pulse)
        Haptics.levelUp()
        AudioManager.shared.play(.levelUp)

        switch event {
        case .signalBlackout:
            let overlay = SKSpriteNode(color: .black, size: size)
            overlay.anchorPoint = CGPoint(x: 0, y: 0)
            overlay.position = .zero
            overlay.alpha = settings.reducedMotion ? 0.36 : 0
            overlay.zPosition = 90
            addChild(overlay)
            blackoutOverlay = overlay
            if !settings.reducedMotion {
                overlay.run(.fadeAlpha(to: 0.58, duration: 0.32))
            }
        case .overdrive:
            echoes.forEach { $0.speed = AppConfig.Game.overdriveSpeedMultiplier }
            arenaFrame.run(.sequence([
                .fadeAlpha(to: 0.24, duration: 0.08),
                .fadeAlpha(to: 1, duration: 0.18)
            ]))
        case .shardStorm:
            for _ in 0..<3 { spawnShard() }
        }

        AppLogger.gameplay.notice("Arena event started: \(event.rawValue, privacy: .public)")
    }

    private func finishArenaEvent(_ event: ArenaEventKind, at time: TimeInterval) {
        switch event {
        case .signalBlackout:
            blackoutOverlay?.removeFromParent()
            blackoutOverlay = nil
        case .overdrive:
            echoes.forEach { $0.speed = 1.0 }
        case .shardStorm:
            break
        }
        activeArenaEvent = nil
        activeArenaEventEndsAt = 0
        lastArenaEventSpawn = time
        session?.arenaEventFinished(event, survived: session?.isGameOver == false)
        AppLogger.gameplay.notice("Arena event finished: \(event.rawValue, privacy: .public)")
    }

    private func clearArenaEvent(registerSurvival: Bool) {
        if let event = activeArenaEvent, registerSurvival {
            session?.arenaEventFinished(event, survived: session?.isGameOver == false)
        } else if let event = activeArenaEvent, session?.activeArenaEventTitle == event.title {
            session?.activeArenaEventTitle = nil
        }
        blackoutOverlay?.removeFromParent()
        blackoutOverlay = nil
        echoes.forEach { $0.speed = 1.0 }
        activeArenaEvent = nil
        activeArenaEventEndsAt = 0
    }

    private func spawnBurst(at position: CGPoint, color: UIColor, count: Int) {
        let adjustedCount = SceneComplexityPolicy.particleCount(
            requested: count,
            quality: renderingQuality,
            reducedMotion: settings.reducedMotion
        )
        guard adjustedCount > 0 else { return }
        let burst = VisualEffectsFactory.makeBurst(
            at: position,
            color: color,
            count: adjustedCount,
            reducedMotion: settings.reducedMotion,
            targetNode: self
        )
        addChild(burst)
        burst.run(.sequence([.wait(forDuration: 0.8), .removeFromParent()]))
    }

    private func enforceEchoBudget() {
        guard let session else { return }
        let maximum = SceneComplexityPolicy.maximumActiveEchoes(stage: session.difficultyStage, quality: renderingQuality)
        while echoes.count > maximum {
            guard let index = echoes.firstIndex(where: { !($0.name ?? "").hasPrefix("bossEcho.") }) else { break }
            let retiring = echoes.remove(at: index)
            retiring.removeAllActions()
            retiring.run(.sequence([.fadeOut(withDuration: settings.reducedMotion ? 0.01 : 0.18), .removeFromParent()]))
        }
    }

    private func applyRenderingQuality() {
        let base = profile.selectedTrail.birthRate
        playerTrail?.particleBirthRate = SceneComplexityPolicy.trailBirthRate(
            base: base,
            quality: renderingQuality,
            reducedMotion: settings.reducedMotion
        )
        enforceEchoBudget()
        AppLogger.gameplay.debug("Rendering quality changed to \(String(describing: self.renderingQuality), privacy: .public)")
    }

    private func checkCollisions(at time: TimeInterval) {
        guard let session else { return }
        guard time >= invulnerableUntil else { return }

        for ghost in echoes {
            if let enabledAt = ghost.userData?["collisionEnabledAt"] as? NSNumber, time < enabledAt.doubleValue {
                continue
            }
            let multiplier = (ghost.userData?["collisionMultiplier"] as? NSNumber)?.doubleValue ?? 1.0
            let collisionDistance = AppConfig.Game.collisionDistance * CGFloat(multiplier)
            let closeDistance = AppConfig.Game.closeCallDistance * CGFloat(multiplier)
            let distance = hypot(player.position.x - ghost.position.x, player.position.y - ghost.position.y)
            if distance <= collisionDistance {
                player.run(.sequence([.fadeAlpha(to: 0.15, duration: 0.07), .fadeAlpha(to: 1, duration: 0.07)]))
                spawnBurst(at: player.position, color: .systemPink, count: settings.reducedMotion ? 10 : 34)
                Haptics.death()
                AudioManager.shared.play(.death)
                session.finishLife()
                return
            }
            if distance <= closeDistance {
                let key = ObjectIdentifier(ghost)
                if time - (closeCallCooldown[key] ?? 0) > 1.0 {
                    closeCallCooldown[key] = time
                    session.registerCloseCall()
                    Haptics.closeCall()
                    AudioManager.shared.play(.closeCall)
                }
            }
        }
    }

    private func updateArenaFrame(animated: Bool) {
        guard size.width > 1, size.height > 1 else { return }
        let margin = gameplayMargin()
        let rect = CGRect(
            x: margin,
            y: margin + 50,
            width: max(1, size.width - margin * 2),
            height: max(1, size.height - (margin * 2) - 142)
        )
        arenaFrame.path = CGPath(roundedRect: rect, cornerWidth: 28, cornerHeight: 28, transform: nil)
        arenaFrame.strokeColor = profile.selectedArena.uiAccent.withAlphaComponent(0.28 + min(0.30, CGFloat(max(0, (session?.difficultyStage ?? 1) - 1)) * 0.04))
        arenaFrame.glowWidth = 4
        if animated {
            arenaFrame.removeAction(forKey: "stagePulse")
            arenaFrame.run(.sequence([.fadeAlpha(to: 0.3, duration: 0.08), .fadeAlpha(to: 1, duration: 0.22)]), withKey: "stagePulse")
        }
    }
}
