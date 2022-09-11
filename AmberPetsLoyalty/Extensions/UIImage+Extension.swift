//
//  UIImage+Extension.swift
//  AmberPetsLoyalty
//
//  Created by Admin on 9/19/20.
//  Copyright © 2020 Deblanko. All rights reserved.
//

import UIKit

extension UIImage {
    

    /// generated a new QR Code in the form of CIImage - Convert to UIImage
       /// - parameter content: String that will be embedded into QR Code
       class func generateQrCode(_ content: String)  -> UIImage? {
           let data = content.data(using: String.Encoding.ascii, allowLossyConversion: false)

           let filter = CIFilter(name: "CIQRCodeGenerator")

           filter?.setValue(data, forKey: "inputMessage")
           filter?.setValue("Q", forKey: "inputCorrectionLevel")
           
           if let qrCodeImage = (filter?.outputImage){
               let context = CIContext()
               if let qrCodeCGImage = context.createCGImage(qrCodeImage, from: qrCodeImage.extent) {
                   return UIImage(cgImage: qrCodeCGImage)
               }
               //                return UIImage(ciImage: qrCodeImage)
           }
           
           return nil
       }
    
    /// place the imageView inside a container view
    /// - parameter superView: the containerView that you want to place the Image inside
    /// - parameter width: width of imageView, if you opt to not give the value, it will take default value of 100
    /// - parameter height: height of imageView, if you opt to not give the value, it will take default value of 30
    func addToCenter(of superView: UIView, width: CGFloat = 100, height: CGFloat = 30) {
        let overlayImageView = UIImageView(image: self)
        
        overlayImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayImageView.contentMode = .scaleAspectFit
        superView.addSubview(overlayImageView)
        
        let centerXConst = NSLayoutConstraint(item: overlayImageView, attribute: .centerX, relatedBy: .equal, toItem: superView, attribute: .centerX, multiplier: 1, constant: 0)
        let widthConst = NSLayoutConstraint(item: overlayImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width)
        let heightConst = NSLayoutConstraint(item: overlayImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height)
        let centerYConst = NSLayoutConstraint(item: overlayImageView, attribute: .centerY, relatedBy: .equal, toItem: superView, attribute: .centerY, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activate([widthConst, heightConst, centerXConst, centerYConst])
    }
}
