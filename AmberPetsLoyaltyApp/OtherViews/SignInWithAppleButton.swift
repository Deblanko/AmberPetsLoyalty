//
//  SignInWithAppleButton.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 25/08/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import SwiftUI
import AuthenticationServices

struct SignInWithAppleButton: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
        Group {
            SignInWithAppleButtonInternal(colorScheme: colorScheme)
        }
    }
}

fileprivate struct SignInWithAppleButtonInternal: UIViewRepresentable { // (3)
  var colorScheme: ColorScheme
  
  func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
      let style : ASAuthorizationAppleIDButton.Style = (colorScheme == .dark) ? .white : .black
      return ASAuthorizationAppleIDButton(type: .signIn, style: style)
  }
  
  func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
  }
}

struct SignInWithAppleButton_Previews: PreviewProvider {
  static var previews: some View {
    SignInWithAppleButton()
  }
}
