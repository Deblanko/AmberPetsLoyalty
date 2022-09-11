//
//  SecureFieldWithLabel.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 26/08/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import SwiftUI


struct SecureFieldWithLabel<Prefix: View>: View {
    @ViewBuilder var label: Prefix
    @Binding var passwordText : String
    @State var showPassword = false
    
    
    var body: some View {
        HStack {
            label
            Group {
                if self.showPassword {
                    TextField("Password", text: $passwordText)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .keyboardType(.default)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: 60, alignment: .center)
                } else {
                    SecureField("Password", text: $passwordText)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .keyboardType(.default)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: 60, alignment: .center)
                }
            }
            .overlay(Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.gray)
                .padding()
                .onTapGesture { showPassword.toggle() } , alignment: .trailing )
        }
    }
}


struct SecureFieldWithLabel_Previews: PreviewProvider {
    @State static var passwordText : String = ""

    static var previews: some View {
        SecureFieldWithLabel(
            label: {
                Text("Password")
            },
            passwordText: $passwordText
        )
    }
}
