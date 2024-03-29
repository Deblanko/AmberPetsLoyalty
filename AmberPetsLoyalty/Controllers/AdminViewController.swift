//
//  AdminViewController.swift
//  AmberPetsLoyalty
//
//  Created by Admin on 9/14/20.
//  Copyright © 2020 Deblanko. All rights reserved.
//

import UIKit
import AVFoundation
import os.log

class AdminViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var theView: UIView!
    @IBOutlet weak var qrLabel: UILabel!
    @IBOutlet weak var foundUserTable: UITableView!
    
    
    @IBOutlet weak var newUserButton: UIButton!
    @IBOutlet weak var redeemButton: UIButton!
    @IBOutlet weak var addPointsButton: UIButton!
    @IBOutlet weak var minusPointsButton: UIButton!
    @IBOutlet weak var rescanButton: UIButton!

    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var customerId : String?
    
    let dataModel = DataModel.sharedInstance
    var dataObserver : NSKeyValueObservation?

    lazy var captureSessionQueue: OperationQueue = {
      var queue = OperationQueue()
      queue.name = "Capture Session queue"
      queue.maxConcurrentOperationCount = 1
      return queue
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateButtonsState()
        
        self.view.roundButtons()

        self.foundUserTable.delegate = self
        self.foundUserTable.dataSource = self
        
        //view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        var rect = theView.layer.bounds
        rect.size.width -= 40
        previewLayer.frame = rect
        previewLayer.videoGravity = .resizeAspectFill
        theView.layer.addSublayer(previewLayer)

        captureSessionQueue.addOperation {
            self.captureSession.startRunning()
        }
        
        let theSize = (3 * previewLayer.bounds.width) / 5
        let theX = (previewLayer.bounds.width - theSize) / 2
        let theY = (previewLayer.bounds.height / 2) - (theSize / 2)
        let scanRect = CGRect(x: theX, y: theY, width: theSize, height: theSize)
        let rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: scanRect)
        metadataOutput.rectOfInterest = rectOfInterest
        
        // create UIView that will server as a red square to indicate where to place QRCode for scanning
        let scanAreaView = UIView()
        scanAreaView.layer.borderColor = UIColor.red.cgColor
        scanAreaView.layer.borderWidth = 4
        scanAreaView.frame = scanRect
        theView.addSubview(scanAreaView)
        
    }
    


    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        os_log("AdminView viewWillAppear", log: OSLog.adminView, type: .info)

        captureSessionQueue.addOperation {
            if (self.captureSession?.isRunning == false) {
                self.captureSession.startRunning()
            }
        }
        
        dataObserver = dataModel.observe(\.lastRefresh, changeHandler: { (theModel, change) in
            self.updateButtonsState()           // update buttons
            self.foundUserTable.reloadData()    // update table
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        os_log("AdminView viewWillDisappear - Entry", log: OSLog.adminView, type: .info)

        captureSessionQueue.addOperation {
            if (self.captureSession?.isRunning == true) {
                self.captureSession.stopRunning()
            }
        }
        os_log("AdminView viewWillDisappear - Exit", log: OSLog.adminView, type: .info)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSessionQueue.addOperation {
            if (self.captureSession?.isRunning == true) {
                self.captureSession.stopRunning()
            }
            DispatchQueue.main.async {
                self.updateButtonsState()
            }
        }

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
                return
            }
            guard let stringValue = readableObject.stringValue else {
                return
            }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }

        dismiss(animated: true)
    }

    func found(code: String) {
        var title = "N/A"
        if let customerData = DataModel.sharedInstance.customerDataFromBase64String(code) {
            title = "\(customerData.type) : \(customerData.userId)"
            self.customerId = customerData.userId
        }
        qrLabel.text = title
        self.updateButtonsState()
        self.foundUserTable.reloadData()

    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    
    func updateButtonsState() {
        self.newUserButton.isEnabled = false
        self.redeemButton.isEnabled = false
        self.addPointsButton.isEnabled = false
        self.minusPointsButton.isEnabled = false
        if let userId = self.customerId {
            if let customer = DataModel.sharedInstance.customers[userId] {
                self.addPointsButton.isEnabled = true
                if let totalPoints = customer.getPoints(userId: userId) {
                    if totalPoints > 0 {
                        self.minusPointsButton.isEnabled = true
                        if totalPoints >= 10 {
                            self.redeemButton.isEnabled = true
                        }
                    }
                }
            }
            else {
                self.newUserButton.isEnabled = true
            }
        }
        self.rescanButton.isEnabled = !(self.captureSession?.isRunning ?? true)
    }
    
    func addNewUserDialog(message:String = "", name:String? = nil, email:String? = nil) {
        if let userId = self.customerId {
            let alertController = UIAlertController(title: "Add New User", message: message, preferredStyle: .alert)
            alertController.addTextField { (textField) in
                textField.placeholder = "Display Name"
                textField.text = name
            }
            alertController.addTextField { (textField) in
                textField.placeholder = "Email"
                textField.text = email
            }
            alertController.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action) in
                if let name = alertController.textFields?[0].text,
                    let email = alertController.textFields?[1].text {
                    
                    if self.dataModel.emailExists(email) {
                        // warn user
                        self.addNewUserDialog(message: "Email already in use!\nUse a different one.", name: name, email: email)
                    }
                    else {
                        DataModel.sharedInstance.addUser(userId: userId, displayName: name, email: email)
                        self.newUserButton.isEnabled = false
                    }
                }
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                // nothing to do here...
            }))
            self.present(alertController, animated: true) {
                //
                
            }
        }
    }
    
    func confirmRedeem(userId:String) {
        let alert = UIAlertController(title: "Redeem", message: "Are you sure?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { (action) in
            DataModel.sharedInstance.addPointsForUserId(userId, points: -10)
        }))
        self.present(alert, animated: true) {
            
        }
    }
    
    @IBAction func newUserButtonClick(_ sender: UIButton) {
        // show dialog
        self.addNewUserDialog()
    }
    
    @IBAction func redeemButtonClick(_ sender: UIButton) {
        if let userId = self.customerId {
            // do we have more than 10 points?
            if let customer = DataModel.sharedInstance.customers[userId] {
                if let totalPoints = customer.getPoints(userId: userId) {
                    if totalPoints >= 10 {
                        confirmRedeem(userId: userId)
                    }
                    else {
                        // how did we get here?
                    }
                }
            }
        
        }
    }
    
    @IBAction func addPointsButtonClick(_ sender: UIButton) {
        if let userId = self.customerId {
            DataModel.sharedInstance.addPointsForUserId(userId)
        }
    }
    
    @IBAction func minusPointsButtonClick(_ sender: UIButton) {
        if let userId = self.customerId {
            DataModel.sharedInstance.addPointsForUserId(userId, points: -1)
        }
    }
    
    
    @IBAction func rescanButtonClick(_ sender: UIButton) {
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
            self.updateButtonsState()
        }
    }
    
    
}



extension AdminViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let userId = self.customerId ?? ""
        let count = DataModel.sharedInstance.userTable(userId: userId).count
        os_log("Number of rows in section %d = %d", log: OSLog.adminView, type: .info, section, count)
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
        
        let userId = self.customerId ?? ""
        let datum = DataModel.sharedInstance.userTable(userId: userId)[indexPath.row]
        
        cell.textLabel?.text = datum.title
        cell.detailTextLabel?.text = datum.details
        
        return cell
    }
}

extension UIButton {
    
    @objc open override var isEnabled: Bool {
        willSet {
            alpha = isEnabled ? 1.0 : 0.5
        }

    }

//    open override var isEnabled: Bool{
//        willSet {
//            alpha = isEnabled ? 1.0 : 0.5
//        }
//    }

}
