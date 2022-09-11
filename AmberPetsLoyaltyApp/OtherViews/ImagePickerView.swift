//
//  ImagePickerView.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 07/09/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import PhotosUI
import SwiftUI
import os.log

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageUpdated: Bool


    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // most of (all?) of the work is done in the coordinator
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        let log = OSLog(subsystem: OSLogger.subsystem, category: "PhotoPicker")

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else {
                return
            }
            
            
            if provider.canLoadObject(ofClass: PHLivePhoto.self) {
                provider.loadObject(ofClass: PHLivePhoto.self) { livePhoto, err in
                    if let photo = livePhoto as? PHLivePhoto {
                        DataModel.saveLogo(logoImage: nil, logoLive: photo)
                        DispatchQueue.main.async {
                            self.parent.imageUpdated = true
                        }
                    }
                }
            } else if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, err in
                    if let image = image as? UIImage {
                        DataModel.saveLogo(logoImage: image, logoLive: nil)
                        DispatchQueue.main.async {
                            self.parent.imageUpdated = true
                        }
                    }
                }
            }
            
            
        }
    }
}

struct LivePhotoView: UIViewRepresentable {
    var livephoto: PHLivePhoto

    func makeUIView(context: Context) -> PHLivePhotoView {
        return PHLivePhotoView()
    }

    func updateUIView(_ lpView: PHLivePhotoView, context: Context) {
        lpView.livePhoto = livephoto
    }
}
