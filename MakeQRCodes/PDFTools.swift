//
//  PDFTools.swift
//  MakeQRCodes
//
//  Created by Admin on 10/4/20.
//  Copyright © 2020 Deblanko. All rights reserved.
//

import Cocoa

import PDFKit

struct CustomerQRData : Codable {
    var store = "AmberPets"
    let type:String
    let userId:String
}

class PDFTools: NSObject {
    
    func base64StringFromCustomerData(customerData:CustomerQRData) -> String? {
        var result:String? = nil
        let jsonEncoder = JSONEncoder()
        if let jsonData = try? jsonEncoder.encode(customerData) {
            let base64Encoded = jsonData.base64EncodedData()
            result = String(data: base64Encoded, encoding: .utf8)
        }
        return result
    }
    
    /// generated a new QR Code in the form of CIImage - Convert to UIImage
    /// - parameter content: String that will be embedded into QR Code
    func generateQrCode(_ content: String)  -> NSImage? {
        let data = content.data(using: String.Encoding.ascii, allowLossyConversion: false)
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("Q", forKey: "inputCorrectionLevel")
        
        if let qrCodeImage = (filter?.outputImage){
            
            let scaleX = 100.0 / qrCodeImage.extent.size.width
            let scaleY = 100.0 / qrCodeImage.extent.size.height
            let transformedQRImage = qrCodeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            
            let rep = NSCIImageRep(ciImage: transformedQRImage)
            let nsImage = NSImage(size: rep.size)
            nsImage.addRepresentation(rep)
            
            return nsImage
        }
        return nil
    }
    

    
    
    func createPDF(start:Int, count:Int, type:String, logo:NSImage?) -> PDFDocument {
        let pdf = PDFDocument()
        let sizeA4 = NSSize(width: 595, height: 842)
        
        let qrSize:CGFloat = 100
        
        let maxRow:CGFloat = 5
        let maxColumn:CGFloat = 3
        
        let xMult = sizeA4.width / maxColumn
        let yMult = sizeA4.height / maxRow
        
        var index = 0
        
        // 16 items per page
        for pageIndex in 0..<(count / (5*3)) {
            var row:CGFloat = 0.0
            var column:CGFloat = 0.0
            
            let image = NSImage(size: sizeA4, flipped: true) { (rect) -> Bool in
                while true {
                    let customerQRData = CustomerQRData(type: "ID", userId: "\(type)\(start+index)")
                    if let customerQRString = self.base64StringFromCustomerData(customerData: customerQRData) {
                        if let qrImage = self.generateQrCode(customerQRString) {
                            let xx = (column * xMult) + ((xMult - qrSize) / 2)
                            let yy = (row * yMult) + 20.0
                            let inRect = NSRect(x: xx, y: yy, width: qrSize, height: qrSize)
                            qrImage.draw(in: inRect)
                            
                            
                            logo?.draw(in: NSRect(x: xx + (qrSize/2) - (30/2), y: yy + (qrSize/2) - (30/2), width: 30, height: 30))
                            
                            let label = NSString(string: "ID:\(type)\(start+index)")
                            let textRect = label.size()
                            let xx2 = (column * xMult) + ((xMult - textRect.width) / 2)
                            let point = NSPoint(x: xx2, y: (row * yMult) + 120)
                            label.draw(at: point)
                            
                            let border = NSRect(x: (column * xMult) + 10 , y: (row * yMult) + 10, width: xMult - 20, height: yMult - 40)
                            let path = NSBezierPath(rect: border)
                            path.stroke()
                            
                        }
                    }
                    index += 1
                    if index == count {
                        break
                    }
                    column += 1
                    if column == maxColumn {
                        row += 1
                        column = 0
                    }
                    if row == maxRow {
                        break
                    }
                    
                }
                return true
            }
            if let page = PDFPage(image: image) {
                pdf.insert(page, at: pageIndex)
            }
        }
        
        return pdf
        
//
//
//        PDFDocument *pdf = [[PDFDocument alloc] init];
//        NSImage *image =[NSImage imageNamed:@"sample"];
//        PDFPage *page = [[PDFPage alloc] initWithImage:image];
//        [page setBounds:NSMakeRect(0, 0, 500,700) forBox:kPDFDisplayBoxMediaBox];
//        [pdf insertPage:page atIndex: [pdf pageCount]];
//        if([pdf writeToFile: fileName]){
//                   [self showAlert:@"Design pdf has been saved."];
//               }
    }
    

}
