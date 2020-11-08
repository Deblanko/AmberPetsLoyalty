//
//  main.swift
//  MakeQRCodes
//
//  Created by Admin on 10/4/20.
//  Copyright © 2020 Deblanko. All rights reserved.
//

import Cocoa

// command line
// -t <type>        Type, eg: Test or Card
// -s <number>      Start at number. Deafult 1
// -c <number>      Count, how many to make, default 10?
// -o <filename>    PDF output file

var type    = "Card"
var startAt = 1
var count   = 10
var outputFile = "out.pdf"
var logoImage:NSImage? = nil

let pattern = "c:s:t:o:l:"
var buffer = Array(pattern.utf8).map { Int8($0) }

while case let option = getopt(CommandLine.argc, CommandLine.unsafeArgv, pattern), option != -1 {
    switch UnicodeScalar(CUnsignedChar(option)) {
    
    case "o":
        outputFile = String(cString: optarg)
    case "c":
        let value = String(cString: optarg)
        count = Int(value) ?? 0
    case "s":
        let value = String(cString: optarg)
        startAt = Int(value) ?? 0
    case "t":
        type = String(cString: optarg)
    case "l":
        let logoFile = String(cString: optarg)
        logoImage = NSImage(byReferencingFile: logoFile)
    case "?":
        let charOption = "\(String(describing: UnicodeScalar(Int(optopt))))"
        if pattern.contains(charOption) && charOption != ":" {
            print("Option '\(charOption)' requires an argument.")
        } else {
            print("Unknown option '\(charOption)'.")
        }
        exit(1)
    default:
        abort()
    }
}


let pdfTool = PDFTools()
let pdf = pdfTool.createPDF(start: startAt, count: count, type: type, logo: logoImage)

pdf.write(toFile: outputFile)


//for index in optind..<C_ARGC {
//    println("Non-option argument '\(String.fromCString(C_ARGV[Int(index)])!)'")
//}

//func createPdfFromView(imageView: UIImageView, saveToDocumentsWithFileName fileName: String)
//{
//    let pdfData = NSMutableData()
//    UIGraphicsBeginPDFContextToData(pdfData, imageView.bounds, nil)
//    UIGraphicsBeginPDFPage()
//
//    let pdfContext = UIGraphicsGetCurrentContext()
//
//    if (pdfContext == nil)
//    {
//        return
//    }
//
//    imageView.layer.renderInContext(pdfContext!)
//    UIGraphicsEndPDFContext()
//
//    if let documentDirectories: AnyObject = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first
//    {
//        let documentsFileName = (documentDirectories as! String)  + ("/\myPDFImage.pdf")
//        debugPrint(documentsFileName, terminator: "")
//        pdfData.writeToFile(documentsFileName, atomically: true)
//    }
//}
