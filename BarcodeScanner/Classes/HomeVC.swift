//
//  HomeVC.swift
//  BarcodeScanner
//
//  Created by Nirzar Gandhi on 02/06/25.
//

import UIKit
import AVFoundation
import Vision

class HomeVC: BaseVC {
    
    // MARK: - IBOutlets
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var detectedLabel: UILabel!
    
    @IBOutlet weak var detectBarcodeBtn: UIButton!
    
    @IBOutlet weak var detectBarcodeBtnBottom: NSLayoutConstraint!
    
    
    // MARK: - Properties
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    
    // MARK: -
    // MARK: - View init Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Home"
        
        self.setControlsProperty()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.tintColor = .white
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.hidesBackButton = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.stopCaptureSession()
    }
    
    fileprivate func setControlsProperty() {
        
        self.view.backgroundColor = .white
        self.view.isOpaque = false
        
        // Camera View
        self.cameraView.backgroundColor = .black
        self.cameraView.addRadiusWithBorder(radius: 10.0)
        self.cameraView.clipsToBounds = true
        self.cameraView.isHidden = true
        
        // ImageView
        self.imgView.backgroundColor = .black
        self.imgView.addRadiusWithBorder(radius: 10.0)
        self.imgView.contentMode = .scaleAspectFit
        self.imgView.clipsToBounds = true
        self.imgView.isHidden = true
        
        // Detected Label
        self.detectedLabel.backgroundColor = .clear
        self.detectedLabel.textColor = .black
        self.detectedLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.detectedLabel.numberOfLines = 0
        self.detectedLabel.lineBreakMode = .byTruncatingTail
        self.detectedLabel.textAlignment = .left
        self.detectedLabel.text = ""
        
        // Detect Barcode Button
        self.detectBarcodeBtn.setBackgroundColor(color: .black, forState: .normal)
        self.detectBarcodeBtn.setTitleColor(.white, for: .normal)
        self.detectBarcodeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        self.detectBarcodeBtn.titleLabel?.lineBreakMode = .byClipping
        self.detectBarcodeBtn.addRadiusWithBorder(radius: 10.0)
        self.detectBarcodeBtn.layer.masksToBounds = true
        self.detectBarcodeBtn.setTitle("Detect Barcode", for: .normal)
        
        self.detectBarcodeBtnBottom.constant = UIDevice.current.hasNotch ? getBottomSafeAreaHeight() : 20
    }
}


// MARK: - Call back
extension HomeVC {
    
    fileprivate func requestCameraPermission() {
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .authorized:
            self.showBottomSheetAlert()
            
        case .notDetermined:
            
            AVCaptureDevice.requestAccess(for: .video) { granted in
                
                DispatchQueue.main.async {
                    
                    if granted {
                        self.showBottomSheetAlert()
                    } else {
                        self.cameraPermissionDeniedAlert()
                    }
                }
            }
            
        case .denied, .restricted:
            self.cameraPermissionDeniedAlert()
            
        @unknown default:
            print("Unknown camera authorization status.")
        }
    }
    
    fileprivate func showBottomSheetAlert() {
        
        let actionSheetController = UIAlertController(title: "Options", message: "Choose an action", preferredStyle: .actionSheet)
        
        let galleryAction = UIAlertAction(title: "Gallery", style: .default) { _ in
            self.openImageGallery()
        }
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            self.setupCamera()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        
        actionSheetController.addAction(galleryAction)
        actionSheetController.addAction(cameraAction)
        actionSheetController.addAction(cancelAction)
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    fileprivate func openImageGallery() {
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    fileprivate func setupCamera() {
        
        self.cameraView.isHidden = false
        
        self.captureSession = AVCaptureSession()
        
        // Set up camera input
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              self.captureSession.canAddInput(videoInput)
        else {
            self.detectedLabel.text = "Error: Failed to access camera"
            return
        }
        
        self.captureSession.addInput(videoInput)
        
        // Set up barcode output
        let metadataOutput = AVCaptureMetadataOutput()
        if self.captureSession.canAddOutput(metadataOutput) {
            
            self.captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .qr, .ean13, .ean8, .code128, .pdf417, .code39
            ]
            
        } else {
            
            self.detectedLabel.text = "Error: Failed to add metadata output"
            return
        }
        
        // Preview layer setup
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer.frame = self.cameraView.layer.bounds
        self.previewLayer.videoGravity = .resizeAspectFill
        self.cameraView.layer.addSublayer(self.previewLayer)
        
        // Start camera
        self.captureSession.startRunning()
    }
    
    fileprivate func detectBarcode(from image: UIImage) {
        
        guard let cgImage = image.cgImage else { return }
        
        let request = VNDetectBarcodesRequest { request, error in
            
            if let results = request.results as? [VNBarcodeObservation], results.count > 0 {
                
                for barcode in results {
                    self.detectedLabel.text = "Found barcode: \(barcode.payloadStringValue ?? "Unknown")"
                    break
                }
                
            } else if let err = error {
                self.detectedLabel.text = "Error: \(err.localizedDescription)"
            } else {
                self.detectedLabel.text = Constants.Generic.ERROR_MESSAGE
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    
    fileprivate func stopCaptureSession() {
        
        if self.captureSession?.isRunning == true {
            self.captureSession.stopRunning()
        }
    }
    
    fileprivate func clearData() {
        
        if self.previewLayer != nil {
            self.previewLayer.sublayers?.removeAll()
        }
        
        self.imgView.image = nil
        self.detectedLabel.text = ""
        
        self.cameraView.isHidden = true
        self.imgView.isHidden = true
    }
}


// MARK: - UIImagePickerController Delegate
extension HomeVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            
            self.imgView.image = image
            self.detectBarcode(from: image)
            
            self.imgView.isHidden = false
        }
    }
}


// MARK: - AVCaptureMetadataOutputObjects Delegate
extension HomeVC: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue {
            
            self.stopCaptureSession()
            self.detectedLabel.text = "🔍 Detected barcode: \(stringValue)"
        }
    }
}


// MARK: - Button Touch & Action
extension HomeVC {
    
    @IBAction func detectBarcodeBtnTouch(_ sender: UIButton) {
        
        self.clearData()
        self.requestCameraPermission()
    }
}
