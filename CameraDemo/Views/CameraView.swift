//
//  CameraView.swift
//  CameraDemo
//
//  Created by Sasha Prokhorenko on 17.01.18.
//  Copyright © 2018 Sasha Prokhorenko. All rights reserved.
//

import UIKit
import AVFoundation

final class CameraView: UIView {

	// MARK: - Instance Properies

	let previewLayer: AVCaptureVideoPreviewLayer!

	// MARK: - View LifeCycle
	
	init(captureSession: AVCaptureSession) {
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		previewLayer.backgroundColor = UIColor.black.cgColor
		previewLayer.videoGravity = .resizeAspect

		super.init(frame: UIScreen.main.bounds)

		layer.addSublayer(previewLayer)
		setNeedsLayout()
		layoutIfNeeded()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("Can't create CameraView!")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		previewLayer.frame = layer.bounds
	}
}
