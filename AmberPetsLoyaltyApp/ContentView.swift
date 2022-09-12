//
//  ContentView.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 22/08/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var firebase = DataModel()

    @State private var tabSelection = 1
    
    var body: some View {
        return TabView(selection: $tabSelection) {
            switch firebase.loginState {
            case .unknown:
                Text("Please Wait...")
            case.loggedIn:
                if firebase.isAdmin {
                    AdminView(vm: firebase)
                        .tabItem {
                            Label("Admin", systemImage: "person.crop.circle.fill.badge.plus")
                        }
                        .tag(1)
                    UsersView(vm: firebase)
                        .tabItem {
                            Label("Users", systemImage: "rectangle.stack.person.crop.fill")
                        }
                        .tag(2)
                    RedeemedView(vm: firebase)
                        .tabItem {
                            Label("Redeem", systemImage: "sterlingsign.circle.fill")
                        }
                        .tag(3)
                    CustomerView(vm: firebase)
                        .tabItem {
                            Label("Customer", systemImage: "person.circle.fill")
                        }
                        .tag(4)

                }
                else {
                    CustomerView(vm: firebase)
                }
                
            case .loggedOut:
                LoginView(vm: firebase)
            case .delete:
                DeleteView(vm: firebase)
            }
        
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
