//
//  PageControl.swift
//  PageControl
//
//  Created by John Manos on 2/9/17.
//  Copyright © 2017 John Manos. All rights reserved.
//

import UIKit

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
            updateProgress(to: progress)
        }
    }
    
    @IBInspectable open var activeTint: UIColor = UIColor.white {
        didSet {
            updatePageIndicators()
            updateProgress(to: progress)
        }
    }
    @IBInspectable open var inactiveTint: UIColor = UIColor(white: 1, alpha: 0.3) {
        didSet {
            updatePageIndicators()
            updateProgress(to: progress)
        }
    }
    @IBInspectable open var indicatorPadding: CGFloat = 10 {
        didSet {
            layoutPageIndicators()
        }
    }
    @IBInspectable open var indicatorHeight: CGFloat = 5 {
        didSet {
            layoutPageIndicators()
        }
    }
    @IBInspectable open var indicatorWidth: CGFloat = 5 {
        didSet {
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
                layer.actions = [ "bounds": NSNull(), "frame": NSNull(), "position": NSNull()]
                layer.backgroundColor = nil
                layer.zPosition = 1
                self.layer.addSublayer(layer)
                return layer
            }
            indicatorLayers.append(contentsOf: newLayers)
        } else {
            indicatorLayers.suffix(-delta).forEach { $0.removeFromSuperlayer() }
        }
        
        layoutPageIndicators()
        updateProgress(to:progress)
        self.invalidateIntrinsicContentSize()
    }
    
    /// Update indicator based on progress and style
    private func updateProgress(to progress: CGFloat) {
        // ignore if progress is outside of page indicators' valid range
        guard progress > -0.5 && progress < CGFloat(numberOfPages) - 0.5 else { return }
        
        switch style {
        case .fill:
            let maxLineWidth = min(indicatorWidth, indicatorHeight)
            for (index, layer) in indicatorLayers.enumerated() {
                let delta = abs(CGFloat(index) - progress)
                if delta < 1 {
                    layer.strokeColor = activeTint.cgColor
                    layer.lineWidth = maxLineWidth * delta
                } else {
                    layer.strokeColor = inactiveTint.cgColor
                    layer.lineWidth = 1
                }
            }
        case .scroll:
            let width = max(0, self.indicatorWidth)
            let height = max(0, self.indicatorHeight)
            let origin = CGPoint(x: progress * (width + indicatorPadding),y: 0)
            activeLayer.frame = CGRect(origin: origin, size: CGSize(width: width, height: height))
        case .scale:
            let maxScale = CGFloat(2)
            for (index, layer) in indicatorLayers.enumerated() {
                let delta = abs(CGFloat(index) - progress)
                if delta < 1 {
                    layer.fillColor = activeTint.cgColor
                    layer.transform = CATransform3DMakeScale(maxScale*delta, maxScale*delta, 1)
                } else {
                    layer.fillColor = inactiveTint.cgColor
                    layer.transform = CATransform3DMakeScale(1, 1, 1)
                }
            }
        case .snake:
            let denormalizedProgress = progress * (indicatorWidth + indicatorPadding)
            let distanceFromPage = abs(round(progress) - progress)
            var newFrame = activeLayer.frame
            let widthMultiplier = (1 + distanceFromPage*2)
            newFrame.origin.x = denormalizedProgress
            newFrame.size.width = newFrame.height * widthMultiplier
            activeLayer.frame = newFrame
        }
    }
    /// Update indicator to handle style changes
    private func updatePageIndicators() {
        switch style {
        case .fill:
            activeLayer.opacity = 0
            indicatorLayers.forEach() { $0.fillColor = nil; $0.strokeColor = inactiveTint.cgColor }
        case .scroll:
            activeLayer.opacity = 1
            indicatorLayers.forEach() { $0.fillColor = inactiveTint.cgColor; $0.strokeColor = nil }
        case .scale:
            activeLayer.opacity = 1
            indicatorLayers.forEach() { $0.fillColor = inactiveTint.cgColor; $0.strokeColor = nil }
        case .snake:
            activeLayer.opacity = 0
            indicatorLayers.forEach() { $0.fillColor = inactiveTint.cgColor; $0.strokeColor = nil }
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
