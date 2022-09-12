//
//  RedeemedView.swift
//  AmberPetsLoyaltyApp
//
//  Created by Paul Branton on 22/08/2022.
//  Copyright © 2022 Deblanko. All rights reserved.
//

import SwiftUI

struct RedeemedView: View {
    @ObservedObject var vm : DataModel
    @State var allUsers = [UserEntry]()
    @State var showSheet = false
    @State var selectedUser : UserEntry? = nil
    
    var body: some View {
        List {
            ForEach(Array(vm.redeemedTableSections.enumerated()), id: \.element) { index, element in
                Section {
                    ForEach(vm.redeemedTableData[index], id:\.id) { entry in
                        HStack {
                            VStack(alignment:.leading) {
                                Text(entry.displayName)
                                Text(entry.date)    // already made pretty
                            }
                            Spacer()
                            if let user = self.allUsers.first(where: { $0.id == entry.userId }) {
                                Button {
                                    showSheet = true
                                    selectedUser = user
                                } label: {
                                    Image(systemName: "info.circle")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .sheet(isPresented: $showSheet) {
                                    if let user = selectedUser {
                                        UserInfoView(user: user)
                                    }
                                }   // sheet
                            }   // if
                        }   // HStack
                    }   // ForEach
                }   // Section
            header: {
                Text(element)
            }   // Header
            }   // ForEach
        }   // List
        .onAppear() {
            self.allUsers = vm.allUsers
        }
    }
}

struct RedeemedView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DataModel()
        RedeemedView(vm:vm)
    }
}
