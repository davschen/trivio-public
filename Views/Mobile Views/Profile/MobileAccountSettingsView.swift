//
//  MobileAccountSettingsView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI

struct MobileAccountSettingsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var isEditingAccountSettings = false
    @State var usernameTaken = false
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            if isEditingAccountSettings {
                MobileAccountSettingsEditView(usernameTaken: $usernameTaken)
            } else {
                MobileAccountSettingsDisplayView()
            }
            
            if !isEditingAccountSettings {
                VStack (spacing: 10) {
                    Button {
                        formatter.setAlertSettings(alertAction: {
                            profileVM.logOut()
                        }, alertTitle: "Log out?", alertSubtitle: "You're about to log out of your account.", hasCancel: true, actionLabel: "Confirm Log Out")
                    } label: {
                        Text("Log Out")
                            .font(formatter.font(fontSize: .mediumLarge))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                            .background(formatter.color(.secondaryFG))
                            .cornerRadius(10)
                    }
                    Button {
                        formatter.setAlertSettings(alertAction: {
                            profileVM.deleteCurrentUserFromDB()
                        }, alertTitle: "Are you sure?", alertSubtitle: "Deleting your account will permanently delete all of your user data associated with this app.", hasCancel: true, actionLabel: "Yes, delete my account")
                    } label: {
                        Text("Delete my account")
                            .font(formatter.font(fontSize: .mediumLarge))
                            .foregroundColor(formatter.color(.red))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                            .background(formatter.color(.primaryFG))
                            .cornerRadius(10)
                            .padding(.bottom, 15)
                    }
                }
                .padding([.horizontal, .bottom])
            }
        }
        .withBackground()
        .edgesIgnoringSafeArea(.bottom)
        .withBackButton()
        .navigationTitle("Account Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button(action: {
                    if profileVM.accountInformationError(usernameTaken: usernameTaken) { return }
                    if isEditingAccountSettings {
                        profileVM.checkUsernameValidWithHandler { (success) in
                            if success {
                                formatter.hapticFeedback(style: .soft, intensity: .strong)
                                profileVM.editAccountInfo()
                                isEditingAccountSettings.toggle()
                                usernameTaken = false
                            } else {
                                formatter.hapticFeedback(style: .rigid, intensity: .strong)
                                usernameTaken = true
                            }
                        }
                    } else {
                        formatter.hapticFeedback(style: .soft, intensity: .strong)
                        isEditingAccountSettings.toggle()
                    }
                }) {
                    Text(isEditingAccountSettings ? "Save" : "Edit")
                        .font(formatter.font(fontSize: .regular))
                        .foregroundColor(formatter.color(profileVM.accountInformationError(usernameTaken: usernameTaken) ? .lowContrastWhite : .highContrastWhite))
                }
            }
        }
    }
}

struct MobileAccountSettingsEditView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @Binding var usernameTaken: Bool
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView (.vertical, showsIndicators: false) {
            VStack (alignment: .leading, spacing: 20) {
                Spacer(minLength: 15)
                VStack (alignment: .leading, spacing: 7) {
                    VStack (spacing: 7) {
                        HStack (spacing: 0) {
                            Image(systemName: "at")
                                .font(.system(size: 25))
                                .foregroundColor(formatter.color(.lowContrastWhite))
                                .frame(height: 35, alignment: .bottom)
                                .offset(y: -3)
                            Spacer(minLength: 15)
                            TextField("Username", text: $profileVM.username)
                                .font(formatter.fontFloat(profileVM.username.isEmpty ? .boldItalic : .bold, sizeFloat: 26))
                                .fixedSize(horizontal: false, vertical: true)
                                .onChange(of: profileVM.username) { change in
                                    profileVM.checkUsernameExists { (success) in
                                        if success {
                                            self.usernameTaken = false
                                        } else {
                                            self.usernameTaken = true
                                        }
                                    }
                                }
                        }
                        .foregroundColor(formatter.color(.highContrastWhite))
                        .accentColor(formatter.color(.secondaryAccent))
                        .cornerRadius(5)
                        Rectangle()
                            .frame(maxWidth: .infinity)
                            .frame(height: 2)
                            .foregroundColor(formatter.color(.highContrastWhite))
                    }
                    
                    if !profileVM.usernameError(usernameTaken: usernameTaken).isEmpty {
                        Text(profileVM.usernameError(usernameTaken: usernameTaken))
                            .font(formatter.font(.regularItalic))
                    }
                }
                .onReceive(timer) { time in
                    if !profileVM.username.isEmpty {
                        profileVM.checkUsernameExists { (success) in
                            if success {
                                self.usernameTaken = false
                            } else {
                                self.usernameTaken = true
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
                
                VStack (spacing: 7) {
                    HStack (spacing: 0) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 25))
                            .foregroundColor(formatter.color(.lowContrastWhite))
                            .frame(height: 30, alignment: .bottom)
                            .offset(y: -3)
                        Spacer(minLength: 15)
                        TextField("Name", text: $profileVM.name)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(formatter.fontFloat(profileVM.name.isEmpty ? .boldItalic : .bold, sizeFloat: 26))
                    }
                    .foregroundColor(formatter.color(.highContrastWhite))
                    .accentColor(formatter.color(.secondaryAccent))
                    .cornerRadius(5)
                    Rectangle()
                        .frame(maxWidth: .infinity)
                        .frame(height: 2)
                        .foregroundColor(formatter.color(.highContrastWhite))
                    if !profileVM.nameError().isEmpty {
                        Text(profileVM.nameError())
                            .font(formatter.font(.boldItalic))
                            .foregroundColor(formatter.color(.secondaryAccent))
                            .padding(.top, 3)
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MobileAccountSettingsDisplayView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var profileVM: ProfileViewModel
    
    var body: some View {
        ScrollView (.vertical, showsIndicators: false) {
            VStack (alignment: .leading, spacing: 25) {
                VStack (alignment: .leading, spacing: 5) {
                    Text("Username")
                        .font(formatter.font())
                    Text(profileVM.username)
                        .font(formatter.font(fontSize: .semiLarge))
                }
                .padding(.top, 25)
                
                VStack (alignment: .leading, spacing: 5) {
                    Text("Name")
                        .font(formatter.font())
                    Text(profileVM.name)
                        .font(formatter.font(fontSize: .semiLarge))
                }
                
                if profileVM.getAuthProvider() == "Phone" {
                    VStack (alignment: .leading, spacing: 5) {
                        Text("Phone number")
                            .font(formatter.font())
                        Text(profileVM.getPhoneNumber())
                            .font(formatter.font(fontSize: .semiLarge))
                        Text("We want to remind you that Trivio! never looks at, sells, or distributes your personal data in any way. It is simply used for user verification.")
                            .font(formatter.font(.regular, fontSize: .regular))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                if profileVM.myUserRecords.isAdmin {
                    VStack (alignment: .leading, spacing: 5) {
                        Text("Admin UI features")
                            .font(formatter.font())
                        Button {
                            formatter.hapticFeedback(style: .soft)
                            profileVM.myUserRecords.isAdmin = false
                        } label: {
                            Text("Vanish")
                                .font(formatter.font(fontSize: .mediumLarge))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(formatter.color(profileVM.myUserRecords.isAdmin ? .primaryFG : .secondaryFG))
                                .cornerRadius(5)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
