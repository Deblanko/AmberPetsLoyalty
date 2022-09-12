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
    @Binding var logoImage: UIImage?
    @Binding var logoLive : PHLivePhoto?


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
            
            
            if provider.hasItemConformingToTypeIdentifier("com.apple.live-photo-bundle") {
                provider.loadObject(ofClass: PHLivePhoto.self) { livePhoto, err in
                    if let photo = livePhoto as? PHLivePhoto {
                        DispatchQueue.main.async {
                            self.parent.logoImage = nil
                            self.parent.logoLive = photo
                        }
                        DataModel.saveLogo(logoImage: nil, logoLive: photo)
                    }
                }
            } else if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, err in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.logoImage = image
                            self.parent.logoLive = nil
                        }
                        DataModel.saveLogo(logoImage: image, logoLive: nil)
                    }
                }
            }
        }
    }
}

struct LivePhotoView: UIViewRepresentable {
    var livephoto: PHLivePhoto
    var playbackStyle : PHLivePhotoViewPlaybackStyle

    func makeUIView(context: Context) -> PHLivePhotoView {
        return PHLivePhotoView()
    }

    func updateUIView(_ lpView: PHLivePhotoView, context: Context) {
        lpView.livePhoto = livephoto
        lpView.startPlayback(with: playbackStyle)
    }
}
