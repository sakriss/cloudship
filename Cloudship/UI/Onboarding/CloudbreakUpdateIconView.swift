//
//  CloudbreakUpdateIconView.swift
//  Cloudship
//

import UIKit

final class CloudbreakUpdateIconView: UIView {

    private let skyLayer = CAGradientLayer()
    private let sunLayer = CAShapeLayer()
    private let raysLayer = CALayer()
    private let leftCloudLayer = CAShapeLayer()
    private let rightCloudLayer = CAShapeLayer()
    private let pulseLayer = CAShapeLayer()
    private var hasPlayed = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        isUserInteractionEnabled = false
        isAccessibilityElement = true
        accessibilityIdentifier = "cloudbreakUpdateIcon"
        accessibilityLabel = "Clouds parting to sunshine"

        skyLayer.colors = [
            UIColor(red: 0.30, green: 0.69, blue: 0.95, alpha: 1).cgColor,
            UIColor(red: 0.78, green: 0.91, blue: 1.00, alpha: 1).cgColor
        ]
        skyLayer.startPoint = CGPoint(x: 0.25, y: 0)
        skyLayer.endPoint = CGPoint(x: 0.78, y: 1)
        layer.addSublayer(skyLayer)

        pulseLayer.fillColor = UIColor.clear.cgColor
        pulseLayer.strokeColor = UIColor.systemYellow.withAlphaComponent(0.35).cgColor
        pulseLayer.lineWidth = 3
        layer.addSublayer(pulseLayer)

        sunLayer.fillColor = UIColor(red: 1.00, green: 0.78, blue: 0.20, alpha: 1).cgColor
        layer.addSublayer(raysLayer)
        layer.addSublayer(sunLayer)

        leftCloudLayer.fillColor = UIColor.white.withAlphaComponent(0.96).cgColor
        rightCloudLayer.fillColor = UIColor.white.withAlphaComponent(0.96).cgColor
        leftCloudLayer.shadowColor = UIColor(red: 0.18, green: 0.36, blue: 0.55, alpha: 1).cgColor
        rightCloudLayer.shadowColor = leftCloudLayer.shadowColor
        leftCloudLayer.shadowOpacity = 0.18
        rightCloudLayer.shadowOpacity = 0.18
        leftCloudLayer.shadowRadius = 6
        rightCloudLayer.shadowRadius = 6
        leftCloudLayer.shadowOffset = CGSize(width: 0, height: 3)
        rightCloudLayer.shadowOffset = CGSize(width: 0, height: 3)
        layer.addSublayer(leftCloudLayer)
        layer.addSublayer(rightCloudLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        rebuildLayers()
        if UIAccessibility.isReduceMotionEnabled || hasPlayed {
            applyFinalState()
        }
    }

    func playIfNeeded() {
        guard !hasPlayed else { return }
        hasPlayed = true

        rebuildLayers()
        if UIAccessibility.isReduceMotionEnabled {
            applyFinalState()
            return
        }

        let radius = min(bounds.width, bounds.height) * 0.5
        let cloudOffset = radius * 0.28

        sunLayer.opacity = 0
        sunLayer.transform = CATransform3DMakeScale(0.55, 0.55, 1)
        raysLayer.opacity = 0
        raysLayer.transform = CATransform3DMakeRotation(-0.25, 0, 0, 1)
        pulseLayer.opacity = 0
        leftCloudLayer.transform = CATransform3DIdentity
        rightCloudLayer.transform = CATransform3DIdentity

        animate(layer: sunLayer,
                keyPath: "opacity",
                from: 0,
                to: 1,
                beginTime: 0.12,
                duration: 0.36,
                timing: .easeOut)
        animate(layer: sunLayer,
                keyPath: "transform.scale",
                from: 0.55,
                to: 1,
                beginTime: 0.12,
                duration: 0.48,
                timing: .easeOut)
        animate(layer: leftCloudLayer,
                keyPath: "transform.translation.x",
                from: 0,
                to: -cloudOffset,
                beginTime: 0.20,
                duration: 0.62,
                timing: .easeInEaseOut)
        animate(layer: rightCloudLayer,
                keyPath: "transform.translation.x",
                from: 0,
                to: cloudOffset,
                beginTime: 0.20,
                duration: 0.62,
                timing: .easeInEaseOut)
        animate(layer: raysLayer,
                keyPath: "opacity",
                from: 0,
                to: 1,
                beginTime: 0.42,
                duration: 0.35,
                timing: .easeOut)
        animate(layer: raysLayer,
                keyPath: "transform.rotation.z",
                from: -0.25,
                to: 0,
                beginTime: 0.42,
                duration: 0.55,
                timing: .easeOut)
        animate(layer: pulseLayer,
                keyPath: "opacity",
                from: 0.7,
                to: 0,
                beginTime: 0.74,
                duration: 0.55,
                timing: .easeOut)
        animate(layer: pulseLayer,
                keyPath: "transform.scale",
                from: 0.88,
                to: 1.08,
                beginTime: 0.74,
                duration: 0.55,
                timing: .easeOut)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) { [weak self] in
            self?.applyFinalState()
        }
    }

    private func applyFinalState() {
        let radius = min(bounds.width, bounds.height) * 0.5
        let cloudOffset = radius * 0.28
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        sunLayer.opacity = 1
        raysLayer.opacity = 1
        pulseLayer.opacity = 0
        sunLayer.transform = CATransform3DIdentity
        raysLayer.transform = CATransform3DIdentity
        leftCloudLayer.transform = CATransform3DMakeTranslation(-cloudOffset, 0, 0)
        rightCloudLayer.transform = CATransform3DMakeTranslation(cloudOffset, 0, 0)
        CATransaction.commit()
    }

    private func rebuildLayers() {
        let side = min(bounds.width, bounds.height)
        let rect = CGRect(
            x: (bounds.width - side) / 2,
            y: (bounds.height - side) / 2,
            width: side,
            height: side
        ).insetBy(dx: 2, dy: 2)
        let radius = rect.width / 2

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        skyLayer.frame = rect
        skyLayer.cornerRadius = radius

        pulseLayer.frame = rect
        pulseLayer.path = UIBezierPath(ovalIn: rect.insetBy(dx: 4, dy: 4)).cgPath

        let sunRect = CGRect(
            x: rect.midX - radius * 0.26,
            y: rect.midY - radius * 0.42,
            width: radius * 0.52,
            height: radius * 0.52
        )
        sunLayer.path = UIBezierPath(ovalIn: sunRect).cgPath

        rebuildRays(center: CGPoint(x: rect.midX, y: sunRect.midY), radius: radius)

        let cloudY = rect.midY + radius * 0.04
        let cloudSize = CGSize(width: radius * 0.88, height: radius * 0.46)
        leftCloudLayer.path = cloudPath(in: CGRect(
            x: rect.midX - cloudSize.width * 0.88,
            y: cloudY - cloudSize.height * 0.5,
            width: cloudSize.width,
            height: cloudSize.height
        )).cgPath
        rightCloudLayer.path = cloudPath(in: CGRect(
            x: rect.midX - cloudSize.width * 0.12,
            y: cloudY - cloudSize.height * 0.48,
            width: cloudSize.width,
            height: cloudSize.height
        )).cgPath
        CATransaction.commit()
    }

    private func rebuildRays(center: CGPoint, radius: CGFloat) {
        raysLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        raysLayer.frame = bounds

        for index in 0..<10 {
            let angle = CGFloat(index) * (.pi * 2 / 10)
            let start = radius * 0.35
            let end = radius * 0.56
            let path = UIBezierPath()
            path.move(to: CGPoint(
                x: center.x + cos(angle) * start,
                y: center.y + sin(angle) * start
            ))
            path.addLine(to: CGPoint(
                x: center.x + cos(angle) * end,
                y: center.y + sin(angle) * end
            ))

            let ray = CAShapeLayer()
            ray.path = path.cgPath
            ray.strokeColor = UIColor(red: 1.00, green: 0.86, blue: 0.34, alpha: 0.85).cgColor
            ray.lineWidth = max(2, radius * 0.035)
            ray.lineCap = .round
            raysLayer.addSublayer(ray)
        }
    }

    private func cloudPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.98))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.46),
                      controlPoint1: CGPoint(x: rect.minX + rect.width * 0.03, y: rect.minY + rect.height * 0.95),
                      controlPoint2: CGPoint(x: rect.minX + rect.width * 0.03, y: rect.minY + rect.height * 0.50))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.45, y: rect.minY + rect.height * 0.18),
                      controlPoint1: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.22),
                      controlPoint2: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.minY + rect.height * 0.14))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.40),
                      controlPoint1: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.minY - rect.height * 0.02),
                      controlPoint2: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.16))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.88, y: rect.minY + rect.height * 0.98),
                      controlPoint1: CGPoint(x: rect.minX + rect.width * 0.92, y: rect.minY + rect.height * 0.38),
                      controlPoint2: CGPoint(x: rect.minX + rect.width * 0.98, y: rect.minY + rect.height * 0.90))
        path.close()
        return path
    }

    private func animate(layer: CALayer,
                         keyPath: String,
                         from: Any,
                         to: Any,
                         beginTime: CFTimeInterval,
                         duration: CFTimeInterval,
                         timing: CAMediaTimingFunctionName) {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.beginTime = CACurrentMediaTime() + beginTime
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: timing)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        layer.add(animation, forKey: keyPath)
    }
}
