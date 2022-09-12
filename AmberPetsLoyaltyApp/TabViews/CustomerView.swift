//
//  CustomerView.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 22/08/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import SwiftUI

struct CustomerView: View {
    @ObservedObject var vm : DataModel
    @State private var showUserAdmin = false
    @State private var showRename = false
    @State private var showLogo = false
    
    var body: some View {
        VStack {
            ZStack {
                if let qrImage = vm.qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                }
                if let customImage = vm.logoImage {
                    Image(uiImage: customImage)
                        .resizable()
                        .frame(width: 64, height: 64, alignment: .center)
                        .onTapGesture {
                            showLogo = true
                        }
                }
                else if let customLiveLogo = vm.logoLive {
                    LivePhotoView(livephoto: customLiveLogo, playbackStyle: .full)
                        .frame(width: 64, height: 64, alignment: .center)                        .scaledToFit()
                        .onTapGesture {
                            showLogo = true
                        }
                }
                else {
                    Image("SmallLogo")
                        .onTapGesture {
                            showLogo = true
                        }
                }
            }
            .sheet(isPresented: $showLogo) {
                LogoView(vm:vm)
            }
            Divider()
            ForEach(vm.userTable()) { item in
                CustomerRow(item: item)
            }
            .padding()
            Divider()
            Spacer()
            HStack {
                Button("User Admin") {
                    showUserAdmin = true
                }
                .actionSheet(isPresented: $showUserAdmin) {
                    ActionSheet(
                        title: Text("\(vm.loggedInName)"),
                        message: Text("Logout or Delete\nDelete will require you to re-authenticate first"),
                        buttons: [
                            .default(Text("Logout")) {
                                vm.logout()
                            },
                            .destructive(Text("Delete")) {
                                vm.loginState = .delete
                            },
                            .default(Text("Cancel")) {
                                
                            }
                        ])
                    
                }
                Spacer()
                Button("Rename") {
                    showRename = true
                }
                
            }
            .padding()
            
        }
        .alert(isPresented: $showRename,
               TextAlert(title: "Rename",
                         message: "Old Name:\(vm.loggedInName)",
                         keyboardType: .namePhonePad) { result in
            if let text = result, let userId = vm.loggedInUserId {
                // Text was accepted
                vm.updateUser(userId: userId, displayName: text)
            } else {
                // The dialog was cancelled
            }
        })
        .onAppear() {
            vm.loadLogo()
        }
    }
}

struct CustomerRow: View {
    @State var item : TableInfo
    
    var body: some View {
        HStack {
            Text(item.title)
            Spacer()
            Text(item.details)
        }
        
    }
}



struct CustomerView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DataModel()
        CustomerView(vm: vm)
    }
}
