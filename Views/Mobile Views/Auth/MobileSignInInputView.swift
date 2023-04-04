//
//  MobileSignInInputView.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 11/30/22.
//

import Foundation
import SwiftUI

import Firebase
import FirebaseAuth
import FirebaseFirestoreSwift

struct MobileAuthEnterNumberView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var signInStage: SignInStage
    @Binding var number: String
    @Binding var ID: String
    @Binding var alert: Bool
    @Binding var alertMessage: String
    @Binding var isLogin: Bool
    
    @State var countryCode = "1"
    @State var showingPicker = false
    
    var body: some View {
        VStack (spacing: 15) {
            Spacer(minLength: 50)
            VStack (spacing: 7) {
                HStack (spacing: 0) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 25))
                        .frame(height: 30, alignment: .bottom)
                        .foregroundColor(formatter.color(.lowContrastWhite))
                        .offset(y: -3)
                    Spacer(minLength: 10)
                    HStack (spacing: 0) {
                        Text("+")
                            .foregroundColor(formatter.color(.lowContrastWhite))
                        TextField("1", text: $countryCode)
                            .keyboardType(.numberPad)
                            .frame(width: 40)
                    }
                    .font(formatter.fontFloat(.bold, sizeFloat: 26))
                    TextField("Phone number", text: $number)
                        .font(formatter.fontFloat(number.isEmpty ? .boldItalic : .bold, sizeFloat: 26))
                        .fixedSize(horizontal: false, vertical: true)
                        .keyboardType(.numberPad)
                }
                .font(formatter.font(fontSize: .semiLarge))
                .foregroundColor(formatter.color(.highContrastWhite))
                .accentColor(formatter.color(.secondaryAccent))
                .cornerRadius(5)
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                    .foregroundColor(formatter.color(.secondaryAccent))
            }
            
            Text("Your personal information will never be used to contact you. It’s simply used for user verification, then we never touch it again.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(formatter.font(.regularItalic, fontSize: .regular))
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 50)
                .padding(.bottom)
                .lineSpacing(3)
            
            Button {
                if hasValidEntry() {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    formatter.resignKeyboard()
                    signInStage = .verifyNumber
                    PhoneAuthProvider.provider().verifyPhoneNumber("+" + countryCode + number, uiDelegate: nil) { (ID, err) in
                        if err != nil {
                            formatter.setAlertSettings(alertTitle: "Oops!", alertSubtitle: (err?.localizedDescription)!, hasCancel: false, actionLabel: "Got it")
                            return
                        }
                        self.ID = ID!
                    }
                }
            } label: {
                Text("Continue")
                    .font(formatter.font(fontSize: .mediumLarge))
                    .foregroundColor(formatter.color(.primaryBG))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 60)
                    .background(formatter.color(.highContrastWhite))
                    .clipShape(Capsule())
            }
            .opacity(hasValidEntry() ? 1 : 0.5)
            Spacer(minLength: 20)
            VStack (spacing: 10) {
                HStack (spacing: 5) {
                    Text(isLogin ? "New to Trivio?" : "Already have an account?")
                        .font(formatter.font(.regular, fontSize: .regular))
                    Button {
                        isLogin.toggle()
                    } label: {
                        Text(isLogin ? "Sign Up" : "Log In")
                    }
                }
                Text("Terms of Agreement")
                    .underline()
                    .onTapGesture {
                        let url = URL.init(string: "https://www.privacypolicies.com/live/3779e433-e05a-43db-8ca5-9d6df7e7a136")
                        guard let privURL = url, UIApplication.shared.canOpenURL(privURL) else { return }
                        UIApplication.shared.open(privURL)
                    }
            }
            .font(formatter.font(fontSize: .regular))
            .padding(.bottom)
        }
        .padding()
    }
    
    func hasValidEntry() -> Bool {
        return countryCode.count >= 1 && number.count >= 10
    }
}

struct MobileAuthVerifyNumberView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var authVM: AuthViewModel
    
    @Binding var isLoggedIn: Bool
    @Binding var signInStage: SignInStage
    @Binding var number: String
    @Binding var code: String
    @Binding var ID: String
    @Binding var alert: Bool
    @Binding var alertMessage: String
    @Binding var isLogin: Bool
    
    @State var isLoading = false
    
    var db = FirebaseConfigurator.shared.getFirestore()
    
    var body: some View {
        VStack (spacing: 15) {
            Spacer(minLength: 50)
            VStack (spacing: 7) {
                HStack (spacing: 0) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 25))
                        .foregroundColor(formatter.color(.lowContrastWhite))
                        .frame(height: 30, alignment: .bottom)
                        .offset(y: -3)
                    Spacer(minLength: 10)
                    TextField("6-digit Code", text: $code)
                        .font(formatter.fontFloat(code.isEmpty ? .boldItalic : .bold, sizeFloat: 26))
                        .fixedSize(horizontal: false, vertical: true)
                        .keyboardType(.numberPad)
                }
                .foregroundColor(formatter.color(.highContrastWhite))
                .accentColor(formatter.color(.secondaryAccent))
                .cornerRadius(5)
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                    .foregroundColor(formatter.color(.secondaryAccent))
            }
            
            Text("Enter the valid code that was sent to the number you just inputted. You may have to wait a few moments.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(formatter.font(.regularItalic, fontSize: .regular))
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 50)
                .padding(.bottom)
                .lineSpacing(3)
            
            Button {
                formatter.hapticFeedback(style: .soft, intensity: .strong)
                isLoading = true
                if hasValidCode() {
                    formatter.resignKeyboard()
                    let credential = PhoneAuthProvider.provider().credential(withVerificationID: self.ID, verificationCode: self.code)
                    FirebaseConfigurator.shared.auth.signIn(with: credential) { (result, error) in
                        if error != nil {
                            formatter.setAlertSettings(alertAction: {
                                formatter.resignKeyboard()
                                isLoading = false
                            }, alertTitle: "Oops!", alertSubtitle: (error?.localizedDescription)!, hasCancel: false, actionLabel: "Got it")
                            return
                        }
                        guard let myUID = FirebaseConfigurator.shared.auth.currentUser?.uid else { return }
                        let docref = self.db.collection("users").document(myUID)
                        docref.getDocument { (doc, error) in
                            if error != nil {
                                print(error!)
                                return
                            }
                            if let doc = doc {
                                NotificationCenter.default.post(name: NSNotification.Name("LogInStatusChange"), object: nil)
                                if !doc.exists {
                                    signInStage = .nameUsername
                                } else {
                                    FirebaseConfigurator.shared.auth.addStateDidChangeListener { (auth, user) in
                                        if user?.uid == myUID {
                                            self.authVM.checkUsernameExists(uid: myUID, completion: { complete in
                                                UserDefaults.standard.setValue(true, forKey: "isLoggedIn")
                                                NotificationCenter.default.post(name: NSNotification.Name("LogInStatusChange"), object: nil)
                                            })
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack (spacing: 15) {
                    if isLoading {
                        LoadingView(color: .primaryBG)
                            .padding(.vertical, 10)
                    } else {
                        Text("Continue")
                    }
                }
                .font(formatter.font(fontSize: .mediumLarge))
                .foregroundColor(formatter.color(.primaryBG))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 60)
                .background(formatter.color(.highContrastWhite))
                .clipShape(Capsule())
            }
            .opacity(hasValidCode() ? 1 : 0.5)
            Spacer()
                .frame(height: 40)
        }
        .padding()
    }
    
    func hasValidCode() -> Bool {
        return self.code.count == 6
    }
}
