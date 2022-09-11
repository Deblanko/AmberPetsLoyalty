//
//  AdminView.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 22/08/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import SwiftUI

struct AdminView: View {
    @ObservedObject var vm : DataModel
    @ObservedObject var scannerViewModel = ScannerViewModel.shared
    
    @State private var showingAlert = false
    
    @State var displayName = ""
    @State var email = ""
    
    
    var body: some View {
        VStack {
            QrCodeScannerView()
                .found(r: self.scannerViewModel.onFoundQrCode(_:))
                .interval(delay: self.scannerViewModel.scanInterval)
                .torchLight(isOn: self.scannerViewModel.torchIsOn)
                .scaledToFit()
                .padding()
                .onAppear {
                    self.scannerViewModel.start()
                }
                .onDisappear {
                    self.scannerViewModel.stop()
                }
            
            if let customerData = scannerViewModel.lastQrCode {
                Text("\(customerData.store)-\(customerData.type)")
                if let customerInfo = vm.getUserInfoForId(customerData.userId) {
                    Text("\(customerInfo.fullName):\(customerInfo.email)")
                }
                if let customerPoints = vm.points[customerData.userId] {
                    Stepper {
                        Text("Points:\(customerPoints.total)")
                    } onIncrement: {
                        vm.addPointsForUserId(customerData.userId)
                    } onDecrement: {
                        vm.addPointsForUserId(customerData.userId, points: -1)
                    }
                    .padding()
                    if customerPoints.total >= 10 {
                        Button("Redeem") {
                            vm.addPointsForUserId(customerData.userId, points: -10)
                        }
                        .padding()
                    }
                }
                else {
                    TextField("Name (Optional)", text: $displayName)
                    TextField("Email (Optional)", text: $email)
                    Button("Add as New Customer") {
                        if email.isEmpty || !vm.emailExists(email) {
                            vm.addUser(
                                userId: customerData.userId,
                                displayName: displayName.isEmpty ? "Anonymous" : displayName,
                                email: email.isEmpty ? "N/A" : email )
                        }
                        else {
                            showingAlert = true
                        }
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(
                            title: Text("Email already in use"),
                            message: Text("Use a different email"),
                            dismissButton: .default(Text("OK"))
                            )
                    }
                    .padding()
                }
                Button("Re-Scan") {
                    self.scannerViewModel.start()
                }
                .padding()

            }
            
        }
    }
}

struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DataModel()
        AdminView(vm: vm)
    }
}
