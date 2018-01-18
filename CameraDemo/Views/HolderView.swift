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

	override class var requiresConstraintBasedLayout: Bool { return true }

	// MARK: - View LifeCycle
	init(width: CGFloat, height:CGFloat) {
		self.width = width
		self.height = height
		super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
		backgroundColor = .red
		translatesAutoresizingMaskIntoConstraints = false
	}

	override var intrinsicContentSize: CGSize {
		return CGSize(width: width, height: height)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}
}
