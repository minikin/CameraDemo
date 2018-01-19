//
//  HolderView.swift
//  CameraDemo
//
//  Created by Sasha Prokhorenko on 18.01.18.
//  Copyright © 2018 Sasha Prokhorenko. All rights reserved.
//

import UIKit

class HolderView: UIView {

	// MARK: - Instance Properies
	let width: CGFloat
	let height: CGFloat
	let visualEffect: UIVisualEffectView

	override class var requiresConstraintBasedLayout: Bool { return true }

	// MARK: - View LifeCycle
	init(width: CGFloat, height:CGFloat) {
		self.width = width
		self.height = height
		self.visualEffect = UIVisualEffectView(effect: UIBlurEffect(style: .light))

		super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))

		visualEffect.frame = self.bounds
		visualEffect.contentView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
		self.addSubview(visualEffect)

		backgroundColor = .clear
		translatesAutoresizingMaskIntoConstraints = false
	}

	override var intrinsicContentSize: CGSize {
		return CGSize(width: width, height: height)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}
}
