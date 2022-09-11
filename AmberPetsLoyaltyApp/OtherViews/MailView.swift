//
//  MailView.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 10/09/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import AVFoundation
import Foundation
import MessageUI
import SwiftUI
import UIKit

struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentation
    @Binding var result: Result<MFMailComposeResult, Error>?
    var recipients = [String]()
    var subjectLine = ""
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentation: PresentationMode
        @Binding var result: Result<MFMailComposeResult, Error>?
        
        init(presentation: Binding<PresentationMode>,
             result: Binding<Result<MFMailComposeResult, Error>?>)
        {
            _presentation = presentation
            _result = result
        }
        
        func mailComposeController(_: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?)
        {
            defer {
                $presentation.wrappedValue.dismiss()
            }
            guard error == nil else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(result)
            
            if result == .sent {
                AudioServicesPlayAlertSound(SystemSoundID(1001))
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: presentation, result: $result)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setBccRecipients(recipients)
        vc.setSubject(subjectLine)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_: MFMailComposeViewController,
                                context _: UIViewControllerRepresentableContext<MailView>) {
        
    }
}
