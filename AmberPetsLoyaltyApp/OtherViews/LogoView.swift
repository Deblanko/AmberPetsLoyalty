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
    @State var vm : DataModel
    @State var showPicker = false
    @State var imageUpdated = false
    
    var body: some View {
        if imageUpdated {
            let _ = vm.lastRefresh = Date()
            let _ = presentationMode.wrappedValue.dismiss()
        }
        
        if let customLogo = vm.logoImage {
            Image(uiImage: customLogo)
                .resizable()
                .scaledToFit()

        }
        else if let customLiveLogo = vm.logoLive {
            LivePhotoView(livephoto: customLiveLogo)
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
            ImagePicker(imageUpdated: $imageUpdated)
        }
        .padding()
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
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
