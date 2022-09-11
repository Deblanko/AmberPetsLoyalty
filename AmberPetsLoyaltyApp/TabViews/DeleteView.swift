//
//  DeleteView.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 25/08/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import SwiftUI
import Firebase
import FirebaseOAuthUI
import FirebaseEmailAuthUI

extension String: Identifiable {
    public typealias ID = Int
    public var id: Int {
        return hash
    }
}

struct DeleteView: View {
    @ObservedObject var vm : DataModel
    @State var passwordText = ""
    @State var showAppleError = false
    
    
    var body: some View {
        VStack {
            if let provider = vm.loginProvider {
                switch provider {
                case .apple:
                    Text("Delete account by reauthenticating using the sign in button")
                        .padding()
                    Spacer()
                    
                    if #available(iOS 15.0, *) {
                    SignInWithAppleButton()
                        .frame(width: 280, height: 45)
                        .onTapGesture {
                            vm.reAuthenticate(provider: .apple)
                        }
                        .alert(
                            Text("error"),
                            isPresented: $showAppleError,
                            presenting: vm.errorMessage,
                            actions: { _ in
                                Button("OK") {
                                    vm.errorMessage = nil
                                }
                            },
                            message: { message in
                                Text(message)
                            })
                    }
                    else {
                        // Fallback on earlier versions
                        SignInWithAppleButton()
                            .frame(width: 280, height: 45)
                            .onTapGesture {
                                vm.reAuthenticate(provider: .apple)
                            }
                        .alert(item: $vm.errorMessage) { errorMessage in
                            Alert(
                                title: Text("Error"),
                                message: Text(errorMessage),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                    }
                case .email:
                    Text("Delete account by reauthenticating with the password for the account")
                        .padding()
                    Spacer()
                    HStack {
                        Text("Email")
                        Text(vm.currentUserEmail)
                        Spacer()
                    }
                    .padding()
                    SecureFieldWithLabel(
                        label: {
                            Text("Password")
                        },
                        passwordText: $passwordText
                    )
                    .padding()
                    if #available(iOS 15.0, *) {
                        Button("Delete Account") {
                            vm.reAuthenticate(provider: .email(password: passwordText))
                        }
                        .alert(
                            Text("error"),
                            isPresented: $showAppleError,
                            presenting: vm.errorMessage,
                            actions: { _ in
                                Button("OK") {
                                    vm.errorMessage = nil
                                }
                            },
                            message: { message in
                                Text(message)
                            })

                    }
                    else {
                        Button("Delete Account") {
                            vm.reAuthenticate(provider: .email(password: passwordText))
                        }
                        
                    }
                }
            }
            else {
                Text("No user signed in?")
            }
            Spacer()
            
            Button("Cancel") {
                vm.loginState = .loggedIn
            }
            .frame(width: 280, height: 45)
        }
    }
}

struct DeleteView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DataModel()
        DeleteView(vm:vm)
    }
}

