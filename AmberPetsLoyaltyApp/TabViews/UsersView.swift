//
//  UsersView.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 22/08/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import SwiftUI
import MessageUI

struct UsersView: View {
    @ObservedObject var vm : DataModel
    //    @State private var searchText = ""
    let alphabet = String(
        String.UnicodeScalarView((UInt8(ascii: "A")...UInt8(ascii: "Z")).compactMap(UnicodeScalar.init))
    )
        .map{ String($0) }
    @State var selections = [String]()
    @State var values = [UserEntry]()
    @State var showMail = false
    @State var result: Result<MFMailComposeResult, Error>? = nil
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView {
                    ScrollViewReader { value in
                        ZStack{
                            
                            List{
                                
                                ForEach(alphabet, id: \.self) { letter in
                                    Section {
                                        VStack{
                                            ForEach(
                                                values.filter { $0.lastName.hasPrefix(letter) },
                                                id: \.id
                                            ) { user in
                                                MultipleSelectionRow(
                                                    user: user,
                                                    isSelected: self.selections.contains(user.id)) {
                                                        if self.selections.contains(user.id) {
                                                            self.selections.removeAll(where: { $0 == user.id })
                                                        }
                                                        else {
                                                            self.selections.append(user.id)
                                                        }
                                                    }
                                            }
                                        }   // ForEach
                                    } header: {
                                        Text(letter)
                                    }
                                    .id(letter)
                                }   // ForEach
                                
                            }   // List
                            .onAppear() {
                                self.values = vm.allUsers
                            }
                            
                            HStack{
                                Spacer()
                                VStack {
                                    ForEach(0..<alphabet.count, id: \.self) { idx in
                                        Button(action: {
                                            withAnimation {
                                                value.scrollTo(alphabet[idx])
                                            }
                                        }, label: {
                                            Text(idx % 2 == 0 ? alphabet[idx] : "\u{2022}")
                                        })
                                    }
                                }
                            }   // HStack
                            
                        }   // ZStack
                        .frame(minHeight:geometry.size.height)
                    } // ScrollViewReader
                }   // ScrollView
            }
            HStack {
                Button(values.count == selections.count ? "Unselect All" : "Select All") {
                    let allSelected = values.count == selections.count
                    selections.removeAll()
                    if !allSelected {
                        selections.append(contentsOf: values.map { $0.id })
                    }
                }
                .padding()
                Spacer()
                if selections.count > 0 {
                    Button("Email") {
                        showMail = true
                    }
                    .padding()
                    .sheet(isPresented: $showMail) {
                        let recipients : [String] = selections.compactMap {
                            let key = $0
                            let found = values.first{ $0.id == key }
                            return found?.email
                        }
                        MailView(result: $result, recipients: recipients, subjectLine: "Amber Pets")
                    }
                }
            }
        }
    }   // Body
}




struct UsersView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DataModel()
        UsersView(vm: vm)
    }
}

struct MultipleSelectionRow: View {
    var user: UserEntry
    var isSelected: Bool
    var action: () -> Void
    @State var showSheet = false
    
    var body: some View {
        HStack {
            Button(action: self.action) {
                Image(systemName: self.isSelected ? "checkmark.square" : "square")
            }
            .buttonStyle(BorderlessButtonStyle())
            VStack {
                HStack {
                    Text("\(user.fullName)")
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                    Text("Points:\(user.points)")
                }
                HStack {
                    Text("\(user.email)")
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                    Image(systemName: "eye")
                        .foregroundColor(colourForLastVisit)

                }
            }
            Button {
                showSheet = true
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(BorderlessButtonStyle())
            .sheet(isPresented: $showSheet) {
                UserInfoView(user: user)
            }
        }
    }
    
    var colourForLastVisit : Color {
        let fromDate = Calendar.current.startOfDay(for: user.lastPurchase ?? Date.distantPast)
        let toDate = Calendar.current.startOfDay(for: Date())
        guard let numberOfDays = Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day else {
            return Color.black
        }

        switch numberOfDays {
        case 0...6:
            return Color.green
        case 6..<28:
            return Color.yellow
        default:
            return Color.red
        }
        
    }
}


