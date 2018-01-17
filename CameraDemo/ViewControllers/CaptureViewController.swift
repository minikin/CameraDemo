//
//  CaptureViewController.swift
//  CameraDemo
//
//  Created by Sasha Prokhorenko on 17.01.18.
//  Copyright © 2018 Sasha Prokhorenko. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

class CaptureViewController: UIViewController {

	// MARK: - Injections



	// MARK: - Instance Properties
	lazy var captureSession: AVCaptureSession = {
		let session = AVCaptureSession()
		session.sessionPreset = .high
		return session
	}()
	private var photoOutput: AVCapturePhotoOutput?
	private var cameraView: CameraView?
	private var flashLayer: CALayer?
	private let sampleBufferQueue = DispatchQueue.global(qos: .userInteractive)
	private let imageProcessingQueue = DispatchQueue.global(qos: .userInitiated)
	private let ciContext = CIContext()

	// MARK: - ViewController LifeCycle

	override func viewDidLoad() {
		super.viewDidLoad()

		let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
		view.addGestureRecognizer(tap)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
			setupCaptureSession()
		} else {
			AVCaptureDevice.requestAccess(for: .video, completionHandler: { authorized in
				DispatchQueue.main.async {
					if authorized {
						self.setupCaptureSession()
					}
				}
			})
		}
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		cameraView?.bounds = view.frame
	}

	// MARK: - Actions

	@objc func onTap(_ tap: UITapGestureRecognizer) {
		takePhoto()
	}

	// MARK: - Rotation

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return [.portrait]
	}

	// MARK: - Camera Capture

	private func findCamera() -> AVCaptureDevice? {
		let deviceTypes: [AVCaptureDevice.DeviceType] = [
			.builtInDualCamera,
			.builtInTelephotoCamera,
			.builtInWideAngleCamera
		]

		let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
																										 mediaType: .video,
																										 position: .back)

		return discovery.devices.first
	}

	private func setupCaptureSession() {
		guard captureSession.inputs.isEmpty else { return }
		guard let camera = findCamera() else {
			print("No camera found")
			return
		}

		do {
			let cameraInput = try AVCaptureDeviceInput(device: camera)
			captureSession.addInput(cameraInput)

			cameraView = CameraView(captureSession: captureSession)
			view.addSubview(self.cameraView!)

			let output = AVCaptureVideoDataOutput()
			output.alwaysDiscardsLateVideoFrames = true
			output.setSampleBufferDelegate(self, queue: sampleBufferQueue)

			captureSession.addOutput(output)

			let photoOutput = AVCapturePhotoOutput()
			self.photoOutput = photoOutput
			captureSession.addOutput(photoOutput)


			captureSession.startRunning()
		} catch let e {
			print("Error creating capture session: \(e)")
			return
		}
	}

	func withDeviceLock(on device: AVCaptureDevice, block: (AVCaptureDevice) -> Void) {
		do {
			try device.lockForConfiguration()
			block(device)
			device.unlockForConfiguration()
		} catch {
			// can't acquire lock
		}
	}

	func takePhoto() {
		guard let formats = photoOutput?.supportedPhotoPixelFormatTypes(for: .tif) else { return }
		print("available pixel formats: \(formats)")
		guard let uncompressedPixelType = formats.first else {
			print("No pixel format types available")
			return
		}

		let settings = AVCapturePhotoSettings(format: [
			kCVPixelBufferPixelFormatTypeKey as String : uncompressedPixelType
			])
		settings.flashMode = .auto
		photoOutput?.capturePhoto(with: settings, delegate: self)
	}

	


}

extension CaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
//	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//		let image = CIImage(cvImageBuffer: imageBuffer)
//	}
}

extension CaptureViewController : AVCapturePhotoCaptureDelegate {
	func photoOutput(_ output: AVCapturePhotoOutput,
									 didFinishProcessingPhoto photo: AVCapturePhoto,
									 error: Error?) {

		imageProcessingQueue.async {
			guard let pixelBuffer = photo.pixelBuffer else {
				print("No pixel buffer provided. Settings may missing pixel format")
				return
			}

			let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
			guard let cgImage = self.ciContext.createCGImage(ciImage, from: ciImage.extent) else {
				fatalError()
			}

			let image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
			print(image)
		}
	}
}


