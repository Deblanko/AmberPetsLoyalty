//
//  UserInfoView.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 06/09/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import SwiftUI

struct UserInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    var user: UserEntry

    var body: some View {
        VStack {
            Text("\(user.fullName)")
            TitleAndValue(title: "Email:", value: user.email)
            TitleAndValue(title: "Id:", value: user.id)
            TitleAndValue(title: "Current Points", value: "\(user.points)")
            TitleAndValue(title: "Total Points", value: "\(user.totalPoints)")
            TitleAndValue(title: "Last Checkin", value: user.lastCheckin.prettyOutput)
            TitleAndValue(title: "Last Purchase", value: user.lastPurchase.prettyOutput)
        }
        Spacer()
        Button("OK") {
            presentationMode.wrappedValue.dismiss()
        }
    }
}


struct UserInfoView_Previews: PreviewProvider {
    static var previews: some View {
        let user = UserEntry(
            id: UUID().uuidString,
            lastName: "Smith",
            fullName: "John Smith",
            email: "js@test.com",
            lastCheckin: Date(),
            lastPurchase: Date.distantPast,
            points: 2,
            totalPoints: 42)
        UserInfoView(user: user)
    }
}

struct TitleAndValue : View {
    var title : String
    var value : String
    
    var body: some View {
        HStack {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer()
            Text(value)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding()
    }
}
