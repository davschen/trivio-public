//
//  AuthNameUsernameView.swift
//  Trivio!
//
//  Created by David Chen on 12/7/22.
//

import Foundation
import SwiftUI

import Firebase
import FirebaseAuth
import FirebaseFirestoreSwift

struct AuthNameUsernameView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var authVM: AuthViewModel
    
    @Binding var isLoggedIn: Bool
    @Binding var signInStage: SignInStage
    @Binding var name: String
    @Binding var username: String
    @Binding var isLogin: Bool
    
    @State var usernameValid = false
    @State var isLoading = false
    
    var db = FirebaseConfigurator.shared.getFirestore()
    
    var nameValid: Bool {
        return !name.isEmpty
    }
    
    var allValid: Bool {
        return nameValid && usernameValid && checkForbiddenChars().isEmpty
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack (spacing: 15) {
            Spacer(minLength: 20)
            VStack (spacing: 7) {
                HStack (spacing: 0) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 25))
                        .foregroundColor(formatter.color(.lowContrastWhite))
                        .frame(height: 30, alignment: .bottom)
                        .offset(y: -3)
                    Spacer(minLength: 15)
                    TextField("Name", text: $name)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(formatter.fontFloat(name.isEmpty ? .boldItalic : .bold, sizeFloat: 26))
                }
                .foregroundColor(formatter.color(.highContrastWhite))
                .accentColor(formatter.color(.secondaryAccent))
                .cornerRadius(5)
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                    .foregroundColor(formatter.color(.secondaryAccent))
            }
            .padding(.bottom, 20)
            
            VStack (alignment: .leading, spacing: 7) {
                VStack (spacing: 7) {
                    HStack (spacing: 0) {
                        Image(systemName: "at")
                            .font(.system(size: 25))
                            .foregroundColor(formatter.color(.lowContrastWhite))
                            .frame(height: 35, alignment: .bottom)
                            .offset(y: -3)
                        Spacer(minLength: 15)
                        TextField("Username", text: $username)
                            .font(formatter.fontFloat(username.isEmpty ? .boldItalic : .bold, sizeFloat: 26))
                            .fixedSize(horizontal: false, vertical: true)
                            .onChange(of: username) { change in
                                checkUsernameValid()
                            }
                    }
                    .foregroundColor(formatter.color(.highContrastWhite))
                    .accentColor(formatter.color(.secondaryAccent))
                    .cornerRadius(5)
                    Rectangle()
                        .frame(maxWidth: .infinity)
                        .frame(height: 4)
                        .foregroundColor(formatter.color(.secondaryAccent))
                }
                
                if !username.isEmpty && !usernameValid {
                    Text("That username already exists")
                        .font(formatter.font(.regularItalic))
                } else if !checkForbiddenChars().isEmpty {
                    Text("Your username cannot contain a \(checkForbiddenChars()).")
                        .font(formatter.font(.regularItalic))
                }
            }
            .onReceive(timer) { time in
                if !username.isEmpty {
                    checkUsernameValid()
                }
            }
            
            Button {
                if allValid {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    isLoading = true
                    usernameFinishedUploading { success in
                        UserDefaults.standard.setValue(true, forKey: "isLoggedIn")
                        NotificationCenter.default.post(name: NSNotification.Name("LogInStatusChange"), object: nil)
                    }
                }
            } label: {
                HStack {
                    if isLoading {
                        LoadingView(color: .primaryBG)
                            .padding(.vertical, 10)
                    } else {
                        HStack {
                            Text("Enter Trivio!")
                            Image(systemName: "sparkles")
                        }
                    }
                }
                .font(formatter.font(fontSize: .mediumLarge))
                .foregroundColor(formatter.color(.primaryBG))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 60)
                .background(formatter.color(.secondaryAccent))
                .clipShape(Capsule())
                .opacity(allValid ? 1 : 0.5)
            }
            .padding(.top, 20)
        }
        .padding(30)
        .onAppear {
            name = authVM.givenNameFromApple
        }
        .onChange(of: authVM.givenNameFromApple, perform: { newValue in
            name = authVM.givenNameFromApple
        })
    }
    
    // This is crazy levels of raw-dogging it. All so that I
    // didn't have to make a VM, huh? I guess it could pay off
    // Definitely the wild west out here though. Am very tempted to
    // write an AuthVM file
    func checkUsernameExists(completion: @escaping (Bool) -> Void) {
        let docRef = db.collection("users")
            .whereField("username", isEqualTo: username.lowercased())
        docRef.addSnapshotListener { (snap, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let data = snap?.documents else { return }
            if let _ = data.first {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func checkUsernameValid() {
        checkUsernameExists { (success) -> Void in
            if success && !username.isEmpty {
                self.usernameValid = true
            } else {
                self.usernameValid = false
            }
        }
    }
    
    func checkForbiddenChars() -> String {
        var forbiddenReport = ""
        let forbiddenChars: [Character] = [" ", "/", "-", "&", "$", "#", "@", "!", "%", "^", "*", "(", ")", "+"]
        for char in forbiddenChars {
            if username.contains(String(char)) {
                forbiddenReport = String(char)
            }
        }
        if forbiddenReport.isEmpty {
            return ""
        } else {
            return forbiddenReport == " " ? "space" : "'" + forbiddenReport + "'"
        }
    }
    
    func usernameFinishedUploading(completion: @escaping (Bool) -> Void) {
        let userRef = db.collection("users").document(FirebaseConfigurator.shared.auth.currentUser?.uid ?? "")
        userRef.setData([
            "name" : name,
            "username" : username.lowercased()
        ], merge: true)
        userRef.addSnapshotListener { docSnap, error in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let doc = docSnap else { return }
            let myUID = FirebaseConfigurator.shared.auth.currentUser?.uid
            if myUID == doc.documentID {
                completion(true)
            }
        }
    }
}
