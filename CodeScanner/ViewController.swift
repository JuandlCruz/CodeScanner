//
//  ViewController.swift
//  CodeScanner
//
//  Created by Juan de la Cruz Sanchez Agudo on 15/3/23.
//


/*
 ejemplos:
 172341234587489 ok
 572341234587489 no ok
 17234123458748923456 ok
 57234123458748923456 no ok
 343434 no ok
 3423452345346346546456457457665765 no ok
 */

import AVFoundation
import UIKit

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    @IBOutlet weak var barcodeLabel: UILabel!
    
    private var qrURL: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        barcodeLabel.isHidden = true
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Error al configurar la entrada de video: \(error.localizedDescription)")
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            print("No se pudo agregar la entrada de video")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.code128]
        } else {
            print("No se pudo agregar la salida de metadatos")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        view.bringSubviewToFront(barcodeLabel)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            showFoundCode(code: stringValue)
        }
    }
    
    func showFoundCode(code: String) {
        if isValidCode(code: code) {
            barcodeLabel.isHidden = false
            barcodeLabel.text = code
            showAlert(title: "Correcto", message: "Paquete escaneado correctamente:\n \(code)")
        } else {
            showAlert(title: "Error", message: "Código no válido:\n \(code)")
        }
    }
    
    func reloadCaptureSession() {
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
        barcodeLabel.isHidden = true
    }
    
//    REGEX ANTIGUO
//    func isValidCode(code: String) -> Bool {
//        let regexPattern = "^[1-3]\\d{14,19}$"
//        if let regex = try? NSRegularExpression(pattern: regexPattern) {
//            let range = NSRange(location: 0, length: code.utf16.count)
//            if regex.firstMatch(in: code, options: [], range: range) != nil {
//                return true
//            }
//        }
//        return false
//    }
    
    func isValidCode(code: String) -> Bool {
        let regex = /^[1-3]\d{14,19}$/
        if let _ = code.firstMatch(of: regex) {
            return true
        }
        return false
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in
            self.reloadCaptureSession()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
