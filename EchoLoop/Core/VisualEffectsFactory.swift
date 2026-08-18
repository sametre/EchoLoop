import SpriteKit
import UIKit

enum VisualEffectsFactory {
    static func particleTexture(color: UIColor = .white) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { context in
            color.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 1, y: 1, width: 6, height: 6))
        }
        return SKTexture(image: image)
    }

    static func makeBurst(
        at position: CGPoint,
        color: UIColor,
        count: Int,
        reducedMotion: Bool,
        targetNode: SKNode
    ) -> SKEmitterNode {
        let burst = SKEmitterNode()
        burst.particleBirthRate = 0
        burst.numParticlesToEmit = max(0, count)
        burst.particleLifetime = reducedMotion ? 0.25 : 0.52
        burst.particleSpeed = reducedMotion ? 55 : 125
        burst.particleSpeedRange = 55
        burst.emissionAngleRange = .pi * 2
        burst.particleAlpha = 0.9
        burst.particleAlphaSpeed = -1.8
        burst.particleScale = 0.075
        burst.particleScaleRange = 0.04
        burst.particleColor = color
        burst.particleTexture = particleTexture()
        burst.position = position
        burst.targetNode = targetNode
        burst.zPosition = 110
        return burst
    }

    static func makeEchoAura(radius: CGFloat, color: UIColor, reducedMotion: Bool) -> SKShapeNode {
        let aura = SKShapeNode(circleOfRadius: radius)
        aura.fillColor = .clear
        aura.strokeColor = color.withAlphaComponent(0.42)
        aura.lineWidth = 1.2
        aura.glowWidth = 9
        aura.alpha = reducedMotion ? 0.48 : 0.72
        aura.zPosition = -1
        aura.name = "echoAura"

        if !reducedMotion {
            aura.run(.repeatForever(.sequence([
                .group([.scale(to: 1.38, duration: 0.55), .fadeAlpha(to: 0.12, duration: 0.55)]),
                .group([.scale(to: 0.92, duration: 0.01), .fadeAlpha(to: 0.72, duration: 0.01)])
            ])), withKey: "auraPulse")
        }
        return aura
    }

    static func makeArenaEventPulse(
        radius: CGFloat,
        color: UIColor,
        reducedMotion: Bool
    ) -> SKShapeNode {
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.fillColor = .clear
        ring.strokeColor = color.withAlphaComponent(0.65)
        ring.lineWidth = 2
        ring.glowWidth = 14
        ring.alpha = reducedMotion ? 0.35 : 0.9
        ring.zPosition = 89
        ring.name = "arenaEventPulse"

        if !reducedMotion {
            ring.run(.sequence([
                .group([.scale(to: 1.75, duration: 0.52), .fadeOut(withDuration: 0.52)]),
                .removeFromParent()
            ]))
        } else {
            ring.run(.sequence([.wait(forDuration: 0.18), .removeFromParent()]))
        }
        return ring
    }
}
