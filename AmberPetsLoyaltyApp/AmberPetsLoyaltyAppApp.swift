//
//  AmberPetsLoyaltyAppApp.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 22/08/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import SwiftUI
import Firebase

@main
struct AmberPetsLoyaltyAppApp: App {
    // MARK: - Life Cycle
    init() {
        FirebaseApp.configure()
    }
  
    // MARK: - UI Elements
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
