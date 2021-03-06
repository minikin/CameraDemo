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

final class CaptureViewController: UIViewController {

	// MARK: - Injections
	// MARK: - Instance Properties
	private lazy var captureSession: AVCaptureSession = {
		let session = AVCaptureSession()
		session.sessionPreset = .high
		return session
	}()
	private var photoOutput: AVCapturePhotoOutput?
	private let cameraShutterSoundID: SystemSoundID = 1108
	private var cameraView: CameraView?
	private var flashLayer: CALayer?
	private let sampleBufferQueue = DispatchQueue.global(qos: .userInteractive)
	private let imageProcessingQueue = DispatchQueue.global(qos: .userInitiated)
	private let ciContext = CIContext()
	private var topHolderView: HolderView?
	private var bottomHolderView: HolderView?

	private var takePhotoButton: CameraButton?

	// MARK: - ViewController LifeCycle

	override func viewDidLoad() {
		super.viewDidLoad()
		UIApplication.shared.isStatusBarHidden = true
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
		guard captureSession.inputs.isEmpty,
		let camera = findCamera() else {
			print("No camera found")
			return
		}

		do {
			let cameraInput = try AVCaptureDeviceInput(device: camera)
			captureSession.addInput(cameraInput)

			cameraView = CameraView(captureSession: captureSession)
			view.addSubview(self.cameraView!)

			// add topHolderView
			topHolderView = HolderView(width: self.view.frame.width, height: 40)
			view.addSubview(topHolderView!)

			// add bottonholder
			bottomHolderView = HolderView(width: self.view.frame.width, height: 120)
			view.addSubview(bottomHolderView!)

			NSLayoutConstraint.activate([
				bottomHolderView!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
				])

			takePhotoButton =  CameraButton(buttonSize: 80, imageForNormalState: #imageLiteral(resourceName: "circle_thin"), imageForSelectedState: #imageLiteral(resourceName: "circle_thin"))
			takePhotoButton?.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
			bottomHolderView?.addSubview(takePhotoButton!)

			NSLayoutConstraint.activate([
				takePhotoButton!.centerXAnchor.constraint(equalTo: (bottomHolderView?.safeAreaLayoutGuide.centerXAnchor)!),
				takePhotoButton!.centerYAnchor.constraint(equalTo: (bottomHolderView?.safeAreaLayoutGuide.centerYAnchor)!)
				])

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

	private func withDeviceLock(on device: AVCaptureDevice, block: (AVCaptureDevice) -> Void) {
		do {
			try device.lockForConfiguration()
			block(device)
			device.unlockForConfiguration()
		} catch {
			// can't acquire lock
		}
	}

	// MARK: - Actions

	@objc
	private func takePhoto() {
		guard let formats = photoOutput?.supportedPhotoPixelFormatTypes(for: .tif) else {
			return
		}
		print("available pixel formats: \(formats)")
		guard let uncompressedPixelType = formats.first else {
			print("No pixel format types available")
			return
		}

		let settings = AVCapturePhotoSettings(format: [
			kCVPixelBufferPixelFormatTypeKey as String: uncompressedPixelType
			])
		settings.flashMode = .auto
		photoOutput?.capturePhoto(with: settings, delegate: self)
	}

	@objc
	func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
		if let error = error {
			// we got back an error!
			let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
			ac.addAction(UIAlertAction(title: "OK", style: .default))
			present(ac, animated: true)
		} else {
			let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
			ac.addAction(UIAlertAction(title: "OK", style: .default))
			present(ac, animated: true)
		}
	}

}

extension CaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
//	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//		let image = CIImage(cvImageBuffer: imageBuffer)
//	}
}

extension CaptureViewController: AVCapturePhotoCaptureDelegate {
	func photoOutput(_ output: AVCapturePhotoOutput,	didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {

		imageProcessingQueue.async {
			guard let pixelBuffer = photo.pixelBuffer else {
				print("No pixel buffer provided. Settings may missing pixel format")
				return
			}

			let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
			guard let cgImage = self.ciContext.createCGImage(ciImage, from: ciImage.extent) else {
				fatalError("Can't create CGImage!")
			}

			let image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
			UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
			print(image)
		}
	}
}
