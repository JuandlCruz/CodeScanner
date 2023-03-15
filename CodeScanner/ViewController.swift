//
//  ScannerViewController.swift
//  CodeScanner
//
//  Created by Juan de la Cruz Sanchez Agudo on 15/3/23.
//

import AVFoundation
import UIKit

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    @IBOutlet weak var barcodeLabel: UILabel!
    @IBOutlet weak var openQRLabel: UIButton!
    @IBOutlet weak var reloadCaptureSessionButton: UIButton!
    
    private var qrURL: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        barcodeLabel.isHidden = true
        openQRLabel.isHidden = true
        reloadCaptureSessionButton.isHidden = true
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .qr]
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        view.bringSubviewToFront(openQRLabel)
        view.bringSubviewToFront(barcodeLabel)
        view.bringSubviewToFront(reloadCaptureSessionButton)

        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            showFoundCode(code: stringValue, type: metadataObject.type)
        }
        
        dismiss(animated: true)
    }

    func showFoundCode(code: String, type: AVMetadataObject.ObjectType ) {
        if type == .qr && isURLValid(code){
            openQRLabel.isHidden = false
            qrURL = code
            openQRLabel.setTitle(code, for: .normal)
        } else {
            barcodeLabel.isHidden = false
            barcodeLabel.text = code
        }
        print(code)
        self.reloadCaptureSessionButton.isHidden = false
    }
    
    @IBAction func openURL(_ sender: UIButton) {
        guard let url = URL(string: qrURL) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @IBAction func reloadCaptureSession(_ sender: UIButton) {
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
        reloadCaptureSessionButton.isHidden = true
        barcodeLabel.isHidden = true
        openQRLabel.isHidden = true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    func isURLValid(_ string: String) -> Bool {
        if let url = URL(string: string), url.scheme != nil, url.host != nil {
            return true
        }
        return false
    }
}
