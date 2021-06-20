//
//  CameraViewController.swift
//  BMSCard
//
//  Created by Mikhail Baranov on 14.12.2020.
//  Copyright © 2020 ASD Group. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit

protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewControllerDidSetupCaptureSession(_ controller: CameraViewController)
    func cameraViewControllerDidFailToSetupCaptureSession(_ controller: CameraViewController)
    func cameraViewControllerDidToogleTorchMode()
    func cameraViewController(_ controller: CameraViewController,
                              didOutput sampleBuffer: CMSampleBuffer)
}

final class CameraViewController: UIViewController {
    
    enum FocusViewType {
        case oneDimension
        case twoDimensions
    }
    
    weak var delegate: CameraViewControllerDelegate?
    var barCodeFocusViewType: FocusViewType = .oneDimension
    // MARK: UI properties
    private lazy var focusView: UIView = makeFocusView()
    /// Button that opens settings to allow camera usage
    private lazy var settingsButton: UIButton = makeSettingsButton()
    private var regularFocusViewConstraints = [NSLayoutConstraint]()
    private var animatedFocusViewConstraints = [NSLayoutConstraint]()

    // MARK: Video
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var captureDevice: AVCaptureDevice?
    private lazy var captureSession: AVCaptureSession = AVCaptureSession()
    private let permissionService = VideoPermissionService()
    private var canRunning: Bool = false
    
    private(set) var torchMode: TorchMode = .off {
        didSet {
            delegate?.cameraViewControllerDidToogleTorchMode()
            guard let captureDevice = captureDevice,
                  captureDevice.hasFlash,
                  captureDevice.isTorchModeSupported(torchMode.captureTorchMode) else {
                return
            }

            try? captureDevice.lockForConfiguration()
            captureDevice.torchMode = torchMode.captureTorchMode
            captureDevice.unlockForConfiguration()
        }
    }

    // MARK: Initialization
    deinit {
        stopCapturing()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        layoutVideoPreviewLayer()
        animateFocusView()
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.layoutVideoPreviewLayer()
        }, completion: { [weak self] _ in
            self?.animateFocusView()
        })
    }
    
    // MARK: - Setup
    
    private func setup() {
        view.backgroundColor = .black
        setupPreviewLayer()
        setupCameraLiveView()
        setupFocusView()
        setupObserver()
    }
    
    private func setupFocusView() {
        focusView.isHidden = true
        view.addSubview(focusView)
        focusView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        let oneDimensionTypeSize = CGSize(width: 280, height: 80)
        let twoDimensionsTypeSize = CGSize(width: 180, height: 180)
        let animatedFocusViewSize = CGSize(width: 210, height: 210)
        
        let regularFocusViewSize = barCodeFocusViewType == .oneDimension
            ? oneDimensionTypeSize
            : twoDimensionsTypeSize

        regularFocusViewConstraints = [
            focusView.widthAnchor.constraint(equalToConstant: regularFocusViewSize.width),
            focusView.heightAnchor.constraint(equalToConstant: regularFocusViewSize.height)
        ]
        animatedFocusViewConstraints = [
            focusView.widthAnchor.constraint(equalToConstant: animatedFocusViewSize.width),
            focusView.heightAnchor.constraint(equalToConstant: animatedFocusViewSize.height)
        ]
        NSLayoutConstraint.activate(regularFocusViewConstraints)
  }
    
    private func makeFocusView() -> UIView {
        let view = UIView()
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 5
        view.layer.shadowColor = UIColor.white.cgColor
        view.layer.shadowRadius = 10.0
        view.layer.shadowOpacity = 0.9
        view.layer.shadowOffset = .zero
        view.layer.masksToBounds = false
        
        return view
    }
    
    func makeSettingsButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Разрешить доступ к камере", comment: "Settings"),
                        for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.sizeToFit()
        button.addTarget(self,
                         action: #selector(handleSettingsButtonTap),
                         for: .touchUpInside)
        let size = button.frame.size
        
        view.addSubview(button)
        button.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(size)
        }
        
        return button
    }
    
    // MARK: Camera setup
      
    private func setupCameraLiveView() {
        permissionService.checkPersmission { [weak self] error in
            guard let self = self else {
                return
            }
            
            self.settingsButton.isHidden = error == nil
            
            guard error == nil else {
                self.delegate?.cameraViewControllerDidFailToSetupCaptureSession(self)
                return
            }
            
            let videoDevice = AVCaptureDevice.default(for: .video)
            let captureSession = self.captureSession
            captureSession.sessionPreset = .high

            guard let device = videoDevice,
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: device),
                  captureSession.canAddInput(videoDeviceInput) else {
                self.delegate?.cameraViewControllerDidFailToSetupCaptureSession(self)
                return
            }
            
            self.canRunning = true
            self.captureDevice = videoDevice
            
            captureSession.addInput(videoDeviceInput)

            let captureOutput = AVCaptureVideoDataOutput()
            captureSession.addOutput(captureOutput)
            // Set video sample rate
            captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            captureOutput.setSampleBufferDelegate(self, queue: .global())
            
            self.delegate?.cameraViewControllerDidSetupCaptureSession(self)
        }
    }
    
    private func setupPreviewLayer() {
        let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer.videoGravity = .resizeAspectFill
        cameraPreviewLayer.connection?.videoOrientation = .portrait
        
        view.layer.addSublayer(cameraPreviewLayer)
        videoPreviewLayer = cameraPreviewLayer
        layoutVideoPreviewLayer()
    }
    
    private func layoutVideoPreviewLayer() {
        videoPreviewLayer?.frame = view.layer.bounds
    }

    // MARK: - Video capturing

    func startCapturing() {
        guard canRunning else {
            return
        }
        
        torchMode = .off
        focusView.isHidden = false
        if (!captureSession.isRunning) {
            captureSession.startRunning()
        }
    }

    func stopCapturing() {
        guard canRunning else {
            return
        }
        
        torchMode = .off
        focusView.isHidden = true
        if (captureSession.isRunning) {
            captureSession.stopRunning()
        }
    }
    
    func toggleTorchMode() {
        guard canRunning, captureSession.isRunning else {
            return
        }
        
        torchMode = torchMode.next
    }

    // MARK: - Actions

    private func setupObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
											   name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    @objc private func appWillEnterForeground() {
        torchMode = .off
        animateFocusView()
    }
    
    @objc private func handleSettingsButtonTap() {
		guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        UIApplication.shared.open(settingsURL)
    }

    // MARK: - Animations

    private func animateFocusView() {
        // Restore to initial state
        focusView.layer.removeAllAnimations()
        
        NSLayoutConstraint.deactivate(animatedFocusViewConstraints)
        NSLayoutConstraint.activate(regularFocusViewConstraints)
        view.layoutIfNeeded()

        NSLayoutConstraint.deactivate(regularFocusViewConstraints)
        NSLayoutConstraint.activate(animatedFocusViewConstraints)

        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       options: [.repeat, .autoreverse, .beginFromCurrentState],
                       animations: { [self] in
                           view.layoutIfNeeded()
                       })
    }
    
}

// MARK: - AVCapture Delegation

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        delegate?.cameraViewController(self, didOutput: sampleBuffer)
    }

}
