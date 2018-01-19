//
//  CameraButton.swift
//  CameraDemo
//
//  Created by Sasha Prokhorenko on 18.01.18.
//  Copyright © 2018 Sasha Prokhorenko. All rights reserved.
//

import UIKit

class CameraButton: UIButton {

	// MARK: - Instance properties

	let buttonSize: CGFloat
	let imageForNormalState: UIImage
	let imageForSelectedState: UIImage
	override class var requiresConstraintBasedLayout: Bool { return true }

	// MARK: - View lifeCycel

	init(buttonSize: CGFloat, imageForNormalState: UIImage, imageForSelectedState: UIImage) {
		self.buttonSize = buttonSize
		self.imageForNormalState = imageForNormalState
		self.imageForSelectedState = imageForSelectedState
		super.init(frame: CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
		tintColor = .white
		translatesAutoresizingMaskIntoConstraints = false

		adjustsImageWhenHighlighted = false

		setImage(imageForNormalState, for: .normal)
		setImage(imageForSelectedState, for: .selected)

		imageView?.contentMode = .center

		addTarget(self, action: #selector(onButtonTapped), for: .touchUpInside)
	}

	override var intrinsicContentSize: CGSize {
		return CGSize(width: buttonSize, height: buttonSize)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("Can create button for Camera!")
	}

	// MARK: - Actions

	@objc
	func onButtonTapped() {
		isSelected = !isSelected
	}
}
