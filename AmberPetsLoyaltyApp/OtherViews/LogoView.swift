//
//  LogoView.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 08/09/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import SwiftUI
import Photos

struct LogoView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm : DataModel
    @State var showPicker = false
    
    var body: some View {
        if let customLogo = vm.logoImage {
            Image(uiImage: customLogo)
                .resizable()
                .scaledToFit()

        }
        else if let customLiveLogo = vm.logoLive {
            LivePhotoView(livephoto: customLiveLogo, playbackStyle: .hint)
                .scaledToFit()
        }
        else {
            Image("Logo")
                .resizable()
                .scaledToFit()

        }
        Divider()
        Spacer()
        if vm.logoImage != nil || vm.logoLive != nil {
            Button("Reset Logo") {
                vm.removeCustomLogo()
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        
        Button("Choose Custom Image") {
            showPicker = true
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(logoImage: $vm.logoImage, logoLive: $vm.logoLive)
                .ignoresSafeArea(.keyboard)
        }
        .padding()
        Button("OK") {
            presentationMode.wrappedValue.dismiss()
            vm.lastRefresh = Date()
        }
        .padding()
    }
}

struct LogoView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DataModel()
        LogoView(vm: vm)
    }
}
