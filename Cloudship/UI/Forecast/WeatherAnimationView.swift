//
//  WeatherAnimationView.swift
//  Cloudship
//
//  Full-screen background weather animation layer. Sits behind the main
//  scroll view and renders CoreAnimation effects for each WeatherCondition.
//  No SpriteKit, no third-party libs, no per-frame callbacks.
//

import UIKit

// MARK: - Internal animation type

private enum WeatherAnimationType: Equatable {
    case none
    case sun
    case stars
    case cloud(count: Int, alpha: Float)
    case rain(birthRate: Float, tint: UIColor)
    case snow(birthRate: Float)
    case thunderstorm
    case fog
    case wind
}

// MARK: - WeatherAnimationView

final class WeatherAnimationView: UIView {

    // MARK: - Public

    private(set) var currentCondition: WeatherCondition = .unknown

    func transition(to condition: WeatherCondition, animated: Bool = true) {
        guard condition != currentCondition else { return }

        if isTransitioning {
            pendingCondition = condition
            return
        }

        currentCondition = condition
        let newType = animationType(for: condition)

        if animated {
            isTransitioning = true
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
                self.alpha = 0
            } completion: { _ in
                self.teardown()
                self.build(newType)
                UIView.animate(withDuration: 0.8) {
                    self.alpha = 1
                } completion: { _ in
                    self.isTransitioning = false
                    if let pending = self.pendingCondition {
                        self.pendingCondition = nil
                        self.transition(to: pending)
                    }
                }
            }
        } else {
            teardown()
            build(newType)
        }
    }

    // MARK: - Private state

    private var activeAnimationType: WeatherAnimationType = .none
    private var activeLayers: [CALayer] = []
    private var emitterLayers: [CAEmitterLayer] = []
    private var lightningTimer: Timer?
    private var activeRainBirthRate: Float = 0
    private var isTransitioning = false
    private var pendingCondition: WeatherCondition?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = true
        observeAppLifecycle()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = true
        observeAppLifecycle()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !bounds.isEmpty else { return }
        // Rebuild when size changes (rotation) to reposition layers
        if activeAnimationType != .none {
            let current = activeAnimationType
            teardown()
            build(current)
        }
    }

    // MARK: - Condition → animation type

    private func animationType(for condition: WeatherCondition) -> WeatherAnimationType {
        let isNight = WeatherCodeMapper.isNighttime()
        switch condition {
        case .clear, .mostlyClear:
            return isNight ? .stars : .sun
        case .partlyCloudy:
            return .cloud(count: 2, alpha: 0.12)
        case .mostlyCloudy:
            return .cloud(count: 3, alpha: 0.15)
        case .cloudy:
            return .cloud(count: 4, alpha: 0.18)
        case .fog, .lightFog:
            return .fog
        case .drizzle:
            return .rain(birthRate: 20, tint: .white)
        case .rain:
            return .rain(birthRate: 55, tint: .white)
        case .heavyRain:
            return .rain(birthRate: 80, tint: .white)
        case .sleet:
            return .rain(birthRate: 50, tint: UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1))
        case .lightSnow:
            return .snow(birthRate: 6)
        case .snow:
            return .snow(birthRate: 15)
        case .heavySnow:
            return .snow(birthRate: 25)
        case .thunderstorm:
            return .thunderstorm
        case .windy:
            return .wind
        case .unknown:
            return .none
        }
    }

    // MARK: - Build

    private func build(_ type: WeatherAnimationType) {
        activeAnimationType = type
        guard !bounds.isEmpty else { return }

        if UIAccessibility.isReduceMotionEnabled {
            buildReducedMotionBackground(type)
            return
        }

        switch type {
        case .none:       break
        case .sun:        buildSun()
        case .stars:      buildStars()
        case .cloud(let count, let alpha): buildClouds(count: count, alpha: alpha)
        case .rain(let rate, let tint):    buildRain(birthRate: rate, tint: tint)
        case .snow(let rate):              buildSnow(birthRate: rate)
        case .thunderstorm:                buildThunderstorm()
        case .fog:                         buildFog()
        case .wind:                        buildWind()
        }
    }

    // MARK: - Teardown

    private func teardown() {
        lightningTimer?.invalidate()
        lightningTimer = nil
        for layer in activeLayers {
            layer.removeAllAnimations()
            layer.removeFromSuperlayer()
        }
        activeLayers.removeAll()
        emitterLayers.removeAll()
        activeAnimationType = .none
        activeRainBirthRate = 0
    }

    // MARK: - Reduce Motion fallback

    private func buildReducedMotionBackground(_ type: WeatherAnimationType) {
        let color: UIColor
        switch type {
        case .sun:          color = UIColor.systemYellow.withAlphaComponent(0.08)
        case .stars:        color = UIColor.systemIndigo.withAlphaComponent(0.06)
        case .cloud:        color = UIColor.systemGray5.withAlphaComponent(0.15)
        case .rain, .thunderstorm: color = UIColor.systemBlue.withAlphaComponent(0.07)
        case .snow:         color = UIColor(white: 0.95, alpha: 0.12)
        case .fog:          color = UIColor.systemGray6.withAlphaComponent(0.20)
        case .wind:         color = UIColor.systemTeal.withAlphaComponent(0.06)
        case .none:         color = .clear
        }
        let overlay = CALayer()
        overlay.frame = bounds
        overlay.backgroundColor = color.cgColor
        layer.addSublayer(overlay)
        activeLayers.append(overlay)
    }

    // MARK: - Sun Rays

    private func buildSun() {
        let isDark = traitCollection.userInterfaceStyle == .dark

        // Glow core — small radial gradient at top-center
        let glowSize: CGFloat = bounds.width * 0.6
        let glow = CAGradientLayer()
        glow.type = .radial
        glow.frame = CGRect(
            x: bounds.midX - glowSize / 2,
            y: -glowSize * 0.3,
            width: glowSize,
            height: glowSize
        )
        let glowAlpha: CGFloat = isDark ? 0.10 : 0.16
        glow.colors = [
            UIColor.systemYellow.withAlphaComponent(glowAlpha).cgColor,
            UIColor.systemOrange.withAlphaComponent(glowAlpha * 0.5).cgColor,
            UIColor.clear.cgColor
        ]
        glow.locations = [0, 0.5, 1]
        glow.startPoint = CGPoint(x: 0.5, y: 0.5)
        glow.endPoint   = CGPoint(x: 1.0, y: 1.0)
        layer.addSublayer(glow)
        activeLayers.append(glow)

        // Conic ray gradient
        let raySize = max(bounds.width, bounds.height) * 2.2
        let rays = CAGradientLayer()
        rays.type = .conic
        rays.frame = CGRect(
            x: bounds.midX - raySize / 2,
            y: -raySize * 0.4,
            width: raySize,
            height: raySize
        )
        let rayAlpha: CGFloat = isDark ? 0.09 : 0.13
        // Alternate amber and clear for 12 ray sectors
        var colors: [CGColor] = []
        for i in 0..<24 {
            colors.append(i.isMultiple(of: 2)
                ? UIColor.systemYellow.withAlphaComponent(rayAlpha).cgColor
                : UIColor.clear.cgColor
            )
        }
        rays.colors = colors
        rays.startPoint = CGPoint(x: 0.5, y: 0.5)
        rays.endPoint   = CGPoint(x: 0.5, y: 0.0)
        layer.addSublayer(rays)
        activeLayers.append(rays)

        // Slow rotation
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.fromValue = 0
        rotate.toValue   = CGFloat.pi * 2
        rotate.duration  = 90.0
        rotate.repeatCount = .infinity
        rotate.isRemovedOnCompletion = false
        rays.add(rotate, forKey: "rayRotation")
    }

    // MARK: - Stars (night)

    private func buildStars() {
        let emitter = CAEmitterLayer()
        emitter.frame = bounds
        emitter.emitterShape  = .rectangle
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterSize   = bounds.size
        emitter.renderMode    = .oldestLast

        let cell = CAEmitterCell()
        cell.contents      = starImage().cgImage
        cell.birthRate     = 0.3
        cell.lifetime      = 999
        cell.velocity      = 0
        cell.scale         = 0.4
        cell.scaleRange    = 0.3
        cell.alphaRange    = 0.6
        cell.alphaSpeed    = 0
        cell.color         = UIColor.white.withAlphaComponent(0.7).cgColor

        // Twinkle via scale pulse
        let twinkle = CABasicAnimation(keyPath: "transform.scale")
        twinkle.fromValue = 0.8
        twinkle.toValue   = 1.2
        twinkle.duration  = Double.random(in: 1.5...3.5)
        twinkle.autoreverses = true
        twinkle.repeatCount  = .infinity

        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)
        activeLayers.append(emitter)
        emitterLayers.append(emitter)

        activeRainBirthRate = cell.birthRate
    }

    private func starImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }

    // MARK: - Clouds

    private func buildClouds(count: Int, alpha: Float) {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let baseColor: UIColor = isDark
            ? UIColor(white: 0.55, alpha: CGFloat(alpha))
            : UIColor(white: 1.0, alpha: CGFloat(alpha))

        let cloudWidth  = bounds.width * 1.4
        let cloudHeight = bounds.height * 0.22
        let durations: [CFTimeInterval] = [38, 48, 55, 44]
        let yOffsets: [CGFloat] = [0.08, 0.18, 0.05, 0.25]
        let heights:  [CGFloat] = [1.0, 0.75, 0.9, 0.6]

        for i in 0..<count {
            let cloud = CALayer()
            let h = cloudHeight * heights[i % heights.count]
            let y = bounds.height * yOffsets[i % yOffsets.count]
            cloud.frame = CGRect(x: -cloudWidth, y: y, width: cloudWidth, height: h)
            cloud.cornerRadius   = h / 2
            cloud.backgroundColor = baseColor.cgColor
            cloud.shadowRadius   = 20
            cloud.shadowOpacity  = 0.06
            cloud.shadowColor    = UIColor.black.cgColor
            layer.addSublayer(cloud)
            activeLayers.append(cloud)

            let drift = CABasicAnimation(keyPath: "position.x")
            drift.fromValue   = -cloudWidth / 2
            drift.toValue     = bounds.width + cloudWidth / 2
            drift.duration    = durations[i % durations.count]
            drift.timeOffset  = durations[i % durations.count] * Double(i) / Double(count)
            drift.repeatCount = .infinity
            drift.timingFunction = CAMediaTimingFunction(name: .linear)
            drift.isRemovedOnCompletion = false
            cloud.add(drift, forKey: "cloudDrift")
        }
    }

    // MARK: - Rain

    private func buildRain(birthRate: Float, tint: UIColor) {
        let emitter = CAEmitterLayer()
        emitter.frame = bounds
        emitter.emitterShape    = .line
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -10)
        emitter.emitterSize     = CGSize(width: bounds.width * 1.2, height: 1)
        emitter.renderMode      = .oldestLast

        let cell = CAEmitterCell()
        cell.contents      = rainDropImage(color: tint).cgImage
        cell.birthRate     = birthRate
        cell.lifetime      = 3.5
        cell.velocity      = 420
        cell.velocityRange = 60
        cell.emissionLongitude = .pi           // downward
        cell.emissionRange     = .pi / 12
        cell.xAcceleration     = 40
        cell.scale             = 0.5
        cell.scaleRange        = 0.15
        cell.alphaSpeed        = -0.15
        cell.color             = tint.withAlphaComponent(0.35).cgColor

        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)
        activeLayers.append(emitter)
        emitterLayers.append(emitter)

        activeRainBirthRate = birthRate
    }

    private func rainDropImage(color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 2, height: 12)).image { ctx in
            let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2, height: 12), cornerRadius: 1)
            color.setFill()
            path.fill()
        }
    }

    // MARK: - Snow

    private func buildSnow(birthRate: Float) {
        let emitter = CAEmitterLayer()
        emitter.frame = bounds
        emitter.emitterShape    = .line
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -10)
        emitter.emitterSize     = CGSize(width: bounds.width * 1.1, height: 1)
        emitter.renderMode      = .oldestLast

        let cell = CAEmitterCell()
        cell.contents      = snowflakeImage().cgImage
        cell.birthRate     = birthRate
        cell.lifetime      = 8.0
        cell.velocity      = 60
        cell.velocityRange = 30
        cell.emissionLongitude = .pi
        cell.emissionRange     = .pi / 3
        cell.xAcceleration     = 15
        cell.yAcceleration     = 12
        cell.spin              = 0.25
        cell.spinRange         = 0.5
        cell.scale             = 0.6
        cell.scaleRange        = 0.3
        cell.alphaSpeed        = -0.04
        cell.color             = UIColor.white.withAlphaComponent(0.7).cgColor

        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)
        activeLayers.append(emitter)
        emitterLayers.append(emitter)

        activeRainBirthRate = birthRate
    }

    private func snowflakeImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 6, height: 6)).image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 6, height: 6))
        }
    }

    // MARK: - Thunderstorm

    private func buildThunderstorm() {
        buildRain(birthRate: 75, tint: .white)
        scheduleNextLightning()
    }

    private func scheduleNextLightning() {
        let delay = Double.random(in: 5.0...18.0)
        lightningTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.flashLightning()
        }
    }

    private func flashLightning() {
        let flash = CALayer()
        flash.frame = bounds
        flash.backgroundColor = UIColor.white.cgColor
        flash.opacity = 0
        layer.addSublayer(flash)

        // First flash
        let fade1 = CAKeyframeAnimation(keyPath: "opacity")
        fade1.values    = [0, 0.65, 0]
        fade1.keyTimes  = [0, 0.3, 1]
        fade1.duration  = 0.18
        fade1.isRemovedOnCompletion = false
        flash.add(fade1, forKey: nil)

        // Second flash after 220ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [weak self, weak flash] in
            guard let self = self, let flash = flash else { return }
            let fade2 = CAKeyframeAnimation(keyPath: "opacity")
            fade2.values   = [0, 0.45, 0]
            fade2.keyTimes = [0, 0.25, 1]
            fade2.duration = 0.20
            fade2.isRemovedOnCompletion = false
            flash.add(fade2, forKey: nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                flash.removeFromSuperlayer()
                if self.activeAnimationType == .thunderstorm {
                    self.scheduleNextLightning()
                }
            }
        }
    }

    // MARK: - Fog

    private func buildFog() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let fogColor: UIColor = isDark
            ? UIColor.systemGray5.withAlphaComponent(0.20)
            : UIColor.systemGray6.withAlphaComponent(0.32)

        let offsets: [CGFloat] = [0, bounds.height * 0.5]
        let durations: [CFTimeInterval] = [14.0, 18.0]

        for i in 0..<2 {
            let grad = CAGradientLayer()
            grad.type   = .axial
            grad.frame  = CGRect(x: 0, y: offsets[i], width: bounds.width, height: bounds.height * 0.6)
            grad.colors = [fogColor.cgColor, UIColor.clear.cgColor, fogColor.cgColor]
            grad.locations = [0, 0.5, 1]
            grad.startPoint = CGPoint(x: 0.5, y: 0)
            grad.endPoint   = CGPoint(x: 0.5, y: 1)
            layer.addSublayer(grad)
            activeLayers.append(grad)

            let drift = CABasicAnimation(keyPath: "position.y")
            drift.byValue    = bounds.height * 0.12 * (i == 0 ? 1 : -1)
            drift.duration   = durations[i]
            drift.autoreverses   = true
            drift.repeatCount    = .infinity
            drift.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            drift.isRemovedOnCompletion = false
            grad.add(drift, forKey: "fogDrift")
        }
    }

    // MARK: - Wind

    private func buildWind() {
        let emitter = CAEmitterLayer()
        emitter.frame = bounds
        emitter.emitterShape    = .line
        emitter.emitterPosition = CGPoint(x: -20, y: bounds.midY)
        emitter.emitterSize     = CGSize(width: 1, height: bounds.height)
        emitter.renderMode      = .oldestLast

        let cell = CAEmitterCell()
        cell.contents      = windStreakImage().cgImage
        cell.birthRate     = 12
        cell.lifetime      = 2.5
        cell.velocity      = 280
        cell.velocityRange = 80
        cell.emissionLongitude = 0            // rightward
        cell.emissionRange     = .pi / 8
        cell.scale             = 0.5
        cell.scaleRange        = 0.3
        cell.alphaSpeed        = -0.2
        cell.color             = UIColor.white.withAlphaComponent(0.28).cgColor

        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)
        activeLayers.append(emitter)
        emitterLayers.append(emitter)

        activeRainBirthRate = cell.birthRate
    }

    private func windStreakImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 40, height: 1)).image { ctx in
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor] as CFArray,
                locations: [0, 0.5, 1]
            )!
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 40, y: 0),
                options: []
            )
        }
    }

    // MARK: - App lifecycle

    private func observeAppLifecycle() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appDidBackground() {
        lightningTimer?.invalidate()
        lightningTimer = nil
        for emitter in emitterLayers { emitter.birthRate = 0 }
    }

    @objc private func appWillForeground() {
        for emitter in emitterLayers { emitter.birthRate = activeRainBirthRate }
        // Restart lightning if we're in a thunderstorm
        if activeAnimationType == .thunderstorm && lightningTimer == nil {
            scheduleNextLightning()
        }
    }

    // MARK: - Dark / light mode

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            transition(to: currentCondition, animated: false)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
