//
//  PageControl.swift
//  PageControl
//
//  Created by John Manos on 2/9/17.
//  Copyright © 2017 John Manos. All rights reserved.
//

import UIKit

extension UIColor {
    func interpolate(between otherColor: UIColor, by fraction: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        if self.cgColor.numberOfComponents == 4 {
            getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        } else {
            let conv = cgColor.converted(to: CGColorSpace(name: CGColorSpace.extendedSRGB)!, intent: CGColorRenderingIntent.defaultIntent, options: nil)!
            r1 = conv.components![0]; g1 = conv.components![1]; b1 = conv.components![2]; a1 = conv.components![3]
        }
        
        if otherColor.cgColor.numberOfComponents == 4 {
            otherColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        } else {
            let conv = otherColor.cgColor.converted(to: CGColorSpace(name: CGColorSpace.extendedSRGB)!, intent: CGColorRenderingIntent.defaultIntent, options: nil)!
            r2 = conv.components![0]; g2 = conv.components![1]; b2 = conv.components![2]; a2 = conv.components![3]
        }
        
        let r = (1 - fraction) * r1 + fraction * r2
        let g = (1 - fraction) * g1 + fraction * g2
        let b = (1 - fraction) * b1 + fraction * b2
        let a = (1 - fraction) * a1 + fraction * a2
        
        return UIColor(red: min(1,max(0,r)), green: min(1,max(0,g)), blue: min(1,max(0,b)), alpha: min(1,max(0,a)))
    }
}

@IBDesignable open class PageControl: UIView {
    public enum Style: Int {
        case scroll = 0, fill, snake, scale
    }
    
    @IBInspectable open var numberOfPages: Int = 0 {
        didSet {
            updatePageCount(to:numberOfPages)
        }
    }
    @IBInspectable open var progress: CGFloat = 0 {
        didSet {
            updateProgress(to: progress)
        }
    }
    @IBInspectable open var IBStyle: Int = 0 {
        didSet {
            guard let newStyle = Style.init(rawValue: IBStyle) else { return }
            style = newStyle
        }
    }
    open var currentPage: Int {
        get {
            return min(numberOfPages - 1, max(0, Int(progress)))
        }
        set {
            progress = CGFloat(currentPage)
        }
    }
    public var style: Style = .snake {
        didSet {
            updatePageIndicators()
            layoutPageIndicators()
            updateProgress(to: progress)
        }
    }
    
    @IBInspectable open var activeTint: UIColor = UIColor.white {
        didSet {
            activeLayer.backgroundColor = activeTint.cgColor
            updatePageIndicators()
            layoutPageIndicators()
            updateProgress(to: progress)
        }
    }
    @IBInspectable open var inactiveTint: UIColor = UIColor(white: 1, alpha: 0.3) {
        didSet {
            updatePageIndicators()
            layoutPageIndicators()
            updateProgress(to: progress)
        }
    }
    @IBInspectable open var indicatorPadding: CGFloat = 10 {
        didSet {
            updatePageIndicators()
            layoutPageIndicators()
        }
    }
    @IBInspectable open var indicatorHeight: CGFloat = 5 {
        didSet {
            updatePageIndicators()
            layoutPageIndicators()
        }
    }
    @IBInspectable open var indicatorWidth: CGFloat = 5 {
        didSet {
            updatePageIndicators()
            layoutPageIndicators()
        }
    }
    
    fileprivate var indicatorLayers: [CAShapeLayer] = []
    fileprivate weak var activeLayer: CALayer!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    /// basic setup of view
    private func setup() {
        let layer = CALayer()
        layer.backgroundColor = self.activeTint.cgColor
        layer.actions = [ "bounds": NSNull(), "frame": NSNull(), "position": NSNull()]
        layer.zPosition = 2
        self.layer.addSublayer(layer)
        self.activeLayer = layer
    }
    /// update indicator layer to handle a change in number of pages
    private func updatePageCount(to count: Int) {
        guard count != indicatorLayers.count else { return }
        
        let delta = count - indicatorLayers.count
        if delta > 0 {
            let newLayers: [CAShapeLayer] = stride(from: 0, to:delta, by:1).map() { _ in
                let layer = CAShapeLayer()
                layer.actions = [ "bounds": NSNull(), "frame": NSNull(), "position": NSNull(), "transform": NSNull(), "lineWidth": NSNull(), "strokeColor": NSNull(), "fillColor": NSNull()]
                layer.backgroundColor = nil
                layer.zPosition = 1
                self.layer.addSublayer(layer)
                return layer
            }
            indicatorLayers.append(contentsOf: newLayers)
        } else {
            indicatorLayers.suffix(-delta).forEach { $0.removeFromSuperlayer() }
        }
        updatePageIndicators()
        layoutPageIndicators()
        updateProgress(to:progress)
        self.invalidateIntrinsicContentSize()
    }
    
    /// Update indicator based on progress and style
    private func updateProgress(to progress: CGFloat) {
        // ignore if progress is outside of page indicators' valid range
        guard progress > -0.2 && progress < CGFloat(numberOfPages) - 0.8 else { return }
        
        switch style {
        case .fill:
            let maxLineWidth = -1 + min(indicatorWidth, indicatorHeight)/2
            for (index, layer) in indicatorLayers.enumerated() {
                let delta = abs(CGFloat(index) - progress)
                
                let lineWidth: CGFloat
                if delta < 1 {
                    lineWidth = 1 + maxLineWidth * (1 - delta)
                    
                    if CGFloat(index) <= progress {
                        layer.strokeColor = activeTint.interpolate(between: inactiveTint, by: delta).cgColor
                    } else {
                        layer.strokeColor = inactiveTint.interpolate(between: activeTint, by: 1-delta).cgColor
                    }
                    
                } else {
                    lineWidth = 1
                    layer.strokeColor = inactiveTint.cgColor
                }
                layer.lineWidth = lineWidth
                let width  = max(0, self.indicatorWidth) - lineWidth
                let height = max(0, self.indicatorHeight) - lineWidth
                let origin = CGPoint(x: CGFloat(index) * (max(0, self.indicatorWidth) + indicatorPadding) + lineWidth/2,y: lineWidth/2)
                
                let cornerRadius = min(width, height)/2
                layer.path = UIBezierPath(roundedRect: CGRect(origin:.zero, size: CGSize(width: width, height: height)), cornerRadius: cornerRadius).cgPath
                layer.frame = CGRect(origin: origin, size: CGSize(width: width, height: height))
            }
        case .scroll:
            let width = max(0, self.indicatorWidth)
            let height = max(0, self.indicatorHeight)
            let origin = CGPoint(x: progress * (width + indicatorPadding),y: 0)
            activeLayer.frame = CGRect(origin: origin, size: CGSize(width: width, height: height))
        case .scale:
            let maxScale = CGFloat(0.5)
            for (index, layer) in indicatorLayers.enumerated() {
                let delta = abs(CGFloat(index) - progress)
                if delta < 1 {
                    
                    if CGFloat(index) <= progress {
                        layer.fillColor = activeTint.interpolate(between: inactiveTint, by: delta).cgColor
                    } else {
                        layer.fillColor = inactiveTint.interpolate(between: activeTint, by: 1-delta).cgColor
                    }
                    
                    layer.transform = CATransform3DMakeScale(1 + maxScale*(1-delta), 1 + maxScale*(1-delta), 1)
                } else {
                    layer.fillColor = inactiveTint.cgColor
                    layer.transform = CATransform3DMakeScale(1, 1, 1)
                }
            }
        case .snake:
            let width = max(0, self.indicatorWidth)
            let height = max(0, self.indicatorHeight)
            
            let distanceFromPage = abs(round(progress) - progress)
            let widthMultiplier = (1 + distanceFromPage * 1.2)
            let finalWidth = width * widthMultiplier
            let centerX = progress * (indicatorWidth + indicatorPadding) + indicatorWidth/2
            let finalX = centerX - finalWidth/2
            activeLayer.frame = CGRect(x: finalX, y: 0, width: finalWidth, height: height)
        }
    }
    /// Update indicator to handle style changes
    private func updatePageIndicators() {
        switch style {
        case .fill:
            activeLayer.opacity = 0
            indicatorLayers.forEach() { $0.fillColor = nil; $0.strokeColor = inactiveTint.cgColor; $0.transform = CATransform3DIdentity }
        case .scroll:
            activeLayer.opacity = 1
            indicatorLayers.forEach() { $0.fillColor = inactiveTint.cgColor; $0.strokeColor = nil; $0.transform = CATransform3DIdentity }
        case .scale:
            activeLayer.opacity = 0
            indicatorLayers.forEach() { $0.fillColor = inactiveTint.cgColor; $0.strokeColor = nil; $0.transform = CATransform3DIdentity }
        case .snake:
            activeLayer.opacity = 1
            indicatorLayers.forEach() { $0.fillColor = inactiveTint.cgColor; $0.strokeColor = nil; $0.transform = CATransform3DIdentity }
        }
    }
    /// layout indicators frames
    private func layoutPageIndicators() {
        let width = max(0, self.indicatorWidth)
        let height = max(0, self.indicatorHeight)
        let size = CGSize(width: width, height: height)
        let cornerRadius = min(width, height)/2
        
        // check if slide
        activeLayer.cornerRadius = cornerRadius
        activeLayer.bounds = CGRect(origin: .zero, size: size)
        
        for (i,layer) in indicatorLayers.enumerated() {
            layer.path = UIBezierPath(roundedRect: CGRect(origin:.zero, size: size), cornerRadius: cornerRadius).cgPath
            let origin = CGPoint(x: CGFloat(i) * (width + indicatorPadding),y: 0)
            layer.frame = CGRect(origin: origin, size: size)
        }
    }
    
    override open var intrinsicContentSize: CGSize {
        guard numberOfPages > 0, indicatorWidth > 0, indicatorHeight > 0 else { return .zero }
        let width = CGFloat(numberOfPages) * (indicatorWidth + indicatorPadding) - indicatorPadding
        return CGSize(width: max(0,width), height: indicatorHeight)
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return intrinsicContentSize
    }
}
