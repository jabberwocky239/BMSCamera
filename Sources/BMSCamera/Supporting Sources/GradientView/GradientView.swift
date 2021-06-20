//
//  GradientView.swift
//  BMSCard
//
//  Created by Mikhail Baranov on 04.04.2020.
//  Copyright © 2020 ASD Group. All rights reserved.
//

import UIKit

final public class GradientView: UIView {

    @IBInspectable public var startColor: UIColor = UIColor.clear {
        didSet {
            updateParams()
        }
    }
    @IBInspectable public var endColor: UIColor = UIColor.clear {
        didSet {
            updateParams()
        }
    }
    @IBInspectable public var startPoint: CGPoint = CGPoint(x: 0.5, y: 0) {
        didSet {
            updateParams()
        }
    }
    @IBInspectable public var endPoint: CGPoint = CGPoint(x: 0.5, y: 1) {
        didSet {
            updateParams()
        }
    }
    @IBInspectable public var zPosition: CGFloat = -1 {
        didSet {
            updateParams()
        }
    }

    private lazy var gradient: CAGradientLayer = {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.zPosition = zPosition
        layer.addSublayer(gradient)

        return gradient
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        updateParams()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func awakeFromNib() {
        super.awakeFromNib()

        updateParams()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        updateFrame()
    }

    private func updateParams() {
        gradient.colors = [startColor.cgColor, endColor.cgColor]
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        gradient.zPosition = zPosition
    }

    private func updateFrame() {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        gradient.frame = bounds
        CATransaction.commit()
    }

}
