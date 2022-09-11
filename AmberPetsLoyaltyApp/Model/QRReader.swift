//
//  QRReader.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 23/08/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import Foundation
import AVFoundation
import SwiftUI
import os.log

// MARK: Data Model
class ScannerViewModel: ObservableObject {
    
    static let shared = ScannerViewModel()
    
    let log = OSLog(subsystem: OSLogger.subsystem, category: "ScannerViewModel")
    
    public let session = AVCaptureSession()
    public let delegate = QrCodeCameraDelegate()
    public let metadataOutput = AVCaptureMetadataOutput()
    
    /// Defines how often we are going to try looking for a new QR-code in the camera feed.
    let scanInterval: Double = 1.0
    
    @Published var torchIsOn: Bool = false
    @Published var lastQrCode: CustomerQRData?
    
    
    func onFoundQrCode(_ code: String) {
        self.lastQrCode = customerDataFromBase64String(code)
        self.stop()
    }
    
    func customerDataFromBase64String(_ base64String:String) -> CustomerQRData? {
        var result: CustomerQRData?
        if let base64Data = Data(base64Encoded: base64String) {
            let jsonDecoder = JSONDecoder()
            result = try? jsonDecoder.decode(CustomerQRData.self, from: base64Data)
        }
        return result
    }
    
    public func start() {
        os_log("Starting QR Capture", log:self.log, type: .info)
        session.startRunning()
    }
    
    public func stop() {
        os_log("Stoping QR Capture", log:self.log, type: .info)
        session.stopRunning()
    }
}

// MARK: Delegate
class QrCodeCameraDelegate: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    var scanInterval: Double = 1.0
    var lastTime = Date(timeIntervalSince1970: 0)
    
    var onResult: (String) -> Void = { _  in }
    var mockData: String?
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else {
                return
            }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            foundBarcode(stringValue)
        }
    }
    
    @objc func onSimulateScanning(){
        foundBarcode(mockData ?? "Simulated QR-code result.")
    }
    
    func foundBarcode(_ stringValue: String) {
        let now = Date()
        if now.timeIntervalSince(lastTime) >= scanInterval {
            lastTime = now
            self.onResult(stringValue)
        }
    }
}

class CameraPreview: UIView {
    
    private var label:UILabel?
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    var session = AVCaptureSession()
    weak var delegate: QrCodeCameraDelegate?
    
    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        self.session = session
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createSimulatorView(delegate: QrCodeCameraDelegate){
        self.delegate = delegate
        self.backgroundColor = UIColor.black
        label = UILabel(frame: self.bounds)
        label?.numberOfLines = 4
        label?.text = "Click here to simulate scan"
        label?.textColor = UIColor.white
        label?.textAlignment = .center
        if let label = label {
            addSubview(label)
        }
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onClick))
        self.addGestureRecognizer(gesture)
    }
    
    @objc func onClick(){
        delegate?.onSimulateScanning()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        #if targetEnvironment(simulator)
            label?.frame = self.bounds
        #else
            previewLayer?.frame = self.bounds
        #endif
    }
}

// MARK: View
struct QrCodeScannerView: UIViewRepresentable {
    let log = OSLog(subsystem: OSLogger.subsystem, category: "QRCodeScannerView")
    
    var supportedBarcodeTypes: [AVMetadataObject.ObjectType] = [.qr]
    typealias UIViewType = CameraPreview
    
    let session = ScannerViewModel.shared.session
    let delegate = ScannerViewModel.shared.delegate
    let metadataOutput = ScannerViewModel.shared.metadataOutput

    
    
    func torchLight(isOn: Bool) -> QrCodeScannerView {
        if let backCamera = AVCaptureDevice.default(for: AVMediaType.video) {
            if backCamera.hasTorch {
                try? backCamera.lockForConfiguration()
                if isOn {
                    backCamera.torchMode = .on
                } else {
                    backCamera.torchMode = .off
                }
                backCamera.unlockForConfiguration()
            }
        }
        return self
    }
    
    func interval(delay: Double) -> QrCodeScannerView {
        delegate.scanInterval = delay
        return self
    }
    
    func found(r: @escaping (String) -> Void) -> QrCodeScannerView {
        delegate.onResult = r
        return self
    }
    
    func simulator(mockBarCode: String)-> QrCodeScannerView{
        delegate.mockData = mockBarCode
        return self
    }
    
    func cleanup() {
        for input in session.inputs {
            os_log("Removing input %{public}@", log: self.log, type: .info, input)
            session.removeInput(input)
        }
        for output in session.outputs{
            os_log("Removing output %{public}@", log: self.log, type: .info, output)
            session.removeOutput(output)
        }
    }
    
    func setupCamera(_ uiView: CameraPreview) {
        if let backCamera = AVCaptureDevice.default(for: AVMediaType.video) {
            if let input = try? AVCaptureDeviceInput(device: backCamera) {
                session.sessionPreset = .photo
                cleanup()
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                else {
                    os_log("Error cannot add AVCaptureSession input", log:self.log, type:.error)
                }
                if session.canAddOutput(metadataOutput) {
                    session.addOutput(metadataOutput)
                    
                    metadataOutput.metadataObjectTypes = supportedBarcodeTypes
                    metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
                }
                else {
                    os_log("Error cannot add AVCaptureSession output", log:self.log, type:.error)
                }
                let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                
                uiView.backgroundColor = UIColor.gray
                previewLayer.videoGravity = .resizeAspectFill
                uiView.layer.addSublayer(previewLayer)
                uiView.previewLayer = previewLayer
            }
        }
    }
    
    func makeUIView(context: UIViewRepresentableContext<QrCodeScannerView>) -> QrCodeScannerView.UIViewType {
        let cameraView = CameraPreview(session: session)
        
        #if targetEnvironment(simulator)
        cameraView.createSimulatorView(delegate: self.delegate)
        #else
        checkCameraAuthorizationStatus(cameraView)
        #endif
        
        return cameraView
    }
    
    static func dismantleUIView(_ uiView: CameraPreview, coordinator: ()) {
        uiView.session.stopRunning()
    }
    
    private func checkCameraAuthorizationStatus(_ uiView: CameraPreview) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraAuthorizationStatus == .authorized {
            setupCamera(uiView)
        } else {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.sync {
                    if granted {
                        self.setupCamera(uiView)
                    }
                }
            }
        }
    }
    
    func updateUIView(_ uiView: CameraPreview, context: UIViewRepresentableContext<QrCodeScannerView>) {
        uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        uiView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }
    
}
