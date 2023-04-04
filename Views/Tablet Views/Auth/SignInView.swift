//
//  SignInView.swift
//  Trivio
//
//  Created by David Chen on 3/2/21.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestoreSwift
import FirebaseCore
import GoogleSignIn

struct SignInView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var isLoggedIn: Bool
    
    @State var signInMethod: SignInMethod = .phone
    @State var signInStage: SignInStage = .choosingMethod
    @State var isLogin = false
    @State var isShowingVerify = false
    @State var countryCode = CountryCode(countryFullName: "United States", countryAbbreviation: "US", code: "1")
    @State var number = ""
    @State var code = ""
    @State var alertMessage = ""
    @State var ID = ""
    @State var alert = false
    @State var name = ""
    @State var username = ""
    @State var showGame = false
    
    var db = FirebaseConfigurator.shared.getFirestore()
    
    var body: some View {
        ZStack {
            formatter.color(.primaryBG)
                .edgesIgnoringSafeArea(.all)
            HStack {
                AuthWelcomeView()
                SignInAuthFlowView(isLoggedIn: $isLoggedIn, signInMethod: $signInMethod, signInStage: $signInStage)
            }
            .transition(.identity)
            AlertView(alertStyle: .standard, titleText: formatter.alertTitle, subtitleText: formatter.alertSubtitle, hasCancel: formatter.hasCancel, actionLabel: formatter.actionLabel, action: {
                formatter.alertAction()
            })
        }
    }
    
    func hasValidEntry() -> Bool {
        return self.countryCode.code.count >= 1 && self.number.count >= 10
    }
    
    func hasValidCode() -> Bool {
        return self.code.count == 6
    }
}

struct AuthWelcomeView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    var body: some View {
        VStack (alignment: .leading, spacing: 20) {
            Spacer()
            HStack {
                Text("Welcome to")
                    .foregroundColor(formatter.color(.highContrastWhite))
                Text("Trivio!")
                    .foregroundColor(formatter.color(.secondaryAccent))
                Spacer()
            }
            .font(formatter.font(fontSize: .extraLarge))
            Button {
                let url = URL.init(string: "https://www.privacypolicies.com/live/3779e433-e05a-43db-8ca5-9d6df7e7a136")
                guard let privURL = url, UIApplication.shared.canOpenURL(privURL) else { return }
                UIApplication.shared.open(privURL)
            } label: {
                Text("Terms of Agreement")
                    .font(formatter.font(.regular, fontSize: .regular))
                    .padding(.vertical, 20)
                    .padding(.horizontal, 40)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(formatter.color(.highContrastWhite), lineWidth: 2))
            }
        }
        .padding(80)
    }
}

struct SignInAuthFlowView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var isLoggedIn: Bool
    @Binding var signInMethod: SignInMethod
    @Binding var signInStage: SignInStage
    
    @State var isLogin = false
    @State var isShowingVerify = false
    @State var countryCode = CountryCode(countryFullName: "United States", countryAbbreviation: "US", code: "1")
    @State var number = ""
    @State var code = ""
    @State var alertMessage = ""
    @State var ID = ""
    @State var alert = false
    @State var name = ""
    @State var username = ""
    @State var showGame = false
    
    var db = FirebaseConfigurator.shared.getFirestore()
    
    var body: some View {
        VStack (alignment: .leading, spacing: formatter.padding()) {
            if signInStage != .choosingMethod {
                AuthHeaderView(signInMethod: $signInMethod, signInStage: $signInStage, isLogin: $isLogin)
            }
            ScrollView(.vertical, showsIndicators: false) {
                switch signInStage {
                case .choosingMethod:
                    ChooseSignInMethodView(signInMethod: $signInMethod, signInStage: $signInStage)
                        .edgesIgnoringSafeArea(.top)
                        .transition(.identity)
                case .enterNumber:
                    AuthEnterNumberView(signInStage: $signInStage, number: $number, ID: $ID, alert: $alert, alertMessage: $alertMessage, isLogin: $isLogin)
                case .verifyNumber:
                    AuthVerifyNumberView(isLoggedIn: $isLoggedIn, signInStage: $signInStage, number: $number, code: $code, ID: $ID, alert: $alert, alertMessage: $alertMessage, isLogin: $isLogin)
                default:
                    AuthNameUsernameView(isLoggedIn: $isLoggedIn, signInStage: $signInStage, name: $name, username: $username, isLogin: $isLogin)
                }
            }
            .resignKeyboardOnDragGesture()
        }
        .frame(maxWidth: 500)
        .background(formatter.color(.primaryFG))
        .edgesIgnoringSafeArea(.all)
    }
    
    func hasValidEntry() -> Bool {
        return self.countryCode.code.count >= 1 && self.number.count >= 10
    }
    
    func hasValidCode() -> Bool {
        return self.code.count == 6
    }
}

struct ChooseSignInMethodView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var authVM: AuthViewModel
    
    @Binding var signInMethod: SignInMethod
    @Binding var signInStage: SignInStage
    
    @State var isGoogleLoading = false
    @State var isAppleLoading = false
    
    var db = FirebaseConfigurator.shared.getFirestore()
    
    var body: some View {
        VStack (spacing: 20) {
            ZStack (alignment: .bottom) {
                formatter.color(.primaryAccent)
                    .cornerRadius(50, corners: [.bottomRight])
                    .edgesIgnoringSafeArea(.top)
                    .frame(maxHeight: 500)
                    .padding(.trailing, 100)
                HStack (alignment: .bottom) {
                    VStack (alignment: .leading, spacing: 10) {
                        Text("Register")
                            .font(formatter.font(fontSize: .large))
                        Text("Choose a way to sign in")
                            .font(formatter.font(.regular, fontSize: .regular))
                    }
                    Spacer()
                    Image("CircleGrid")
                        .aspectRatio(contentMode: .fill)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 45)
            }
            Spacer(minLength: 45)
            VStack (spacing: 20) {
                Button {
                    signInMethod = .phone
                    signInStage = .enterNumber
                } label: {
                    HStack {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 20))
                            .frame(height: 30, alignment: .bottom)
                            .foregroundColor(formatter.color(.highContrastWhite))
                            .offset(y: -6)
                        Text("Sign in with SMS")
                            .font(formatter.font(fontSize: .mediumLarge))
                    }
                    .foregroundColor(formatter.color(.highContrastWhite))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 80)
                    .background(formatter.color(.secondaryFG))
                    .clipShape(Capsule())
                }
                // Sign in with Google button
                Button {
                    googleSignIn()
                } label: {
                    HStack (spacing: 8) {
                        if isGoogleLoading {
                            LoadingView(color: .primaryBG)
                        } else {
                            Image("google")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .aspectRatio(contentMode: .fit)
                                .offset(y: -1)
                            Text("Sign in with Google")
                        }
                    }
                    .font(formatter.font(fontSize: .mediumLarge))
                    .foregroundColor(formatter.color(.primaryBG))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 80)
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                // Sign in with Apple button
                HStack (spacing: 8) {
                    if isAppleLoading {
                        LoadingView(color: .primaryBG)
                    } else {
                        QuickSignInWithApple()
                            .onTapGesture {
                                authVM.startSignInWithAppleFlow()
                                isGoogleLoading = false
                                isAppleLoading = true
                            }
                    }
                }
                .font(formatter.font(fontSize: .mediumLarge))
                .foregroundColor(formatter.color(.primaryBG))
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(Color.white)
                .clipShape(Capsule())
                .onChange(of: authVM.appleSignInResult) { newValue in
                    if newValue == .success {
                        handleUserSignIn()
                    }
                    isAppleLoading = false
                }
            }
            .padding(.horizontal, 30)
            Spacer(minLength: 45)
            Text("Terms of Agreement")
                .underline()
                .padding(.bottom, 45)
                .onTapGesture {
                    let url = URL.init(string: "https://www.privacypolicies.com/live/3779e433-e05a-43db-8ca5-9d6df7e7a136")
                    guard let privURL = url, UIApplication.shared.canOpenURL(privURL) else { return }
                    UIApplication.shared.open(privURL)
                }
        }
    }
    
    func googleSignIn() {
        isGoogleLoading = true
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(with: config, presenting: (UIApplication.shared.windows.first?.rootViewController)!) { user, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard
                let authentication = user?.authentication,
                let idToken = authentication.idToken
            else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: authentication.accessToken)
            
            // Authenticate with Firebase using the credential object
            FirebaseConfigurator.shared.auth.signIn(with: credential) { (authResult, error) in
                if error != nil {
                    formatter.setAlertSettings(alertAction: {
                        formatter.resignKeyboard()
                        isGoogleLoading = false
                    }, alertTitle: "Oops!", alertSubtitle: (error?.localizedDescription)!, hasCancel: false, actionLabel: "Got it")
                    return
                }
                handleUserSignIn()
                isGoogleLoading = false
            }
        }
    }
    
    private func handleUserSignIn() {
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

struct AuthHeaderView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var signInMethod: SignInMethod
    @Binding var signInStage: SignInStage
    @Binding var isLogin: Bool
    
    var body: some View {
        ZStack (alignment: .bottom) {
            formatter.color(.primaryAccent)
                .edgesIgnoringSafeArea(.top)
                .frame(maxHeight: 150)
                .cornerRadius(30, corners: [.bottomLeft, .bottomRight])
            ZStack (alignment: .bottom) {
                Button {
                    formatter.setAlertSettings(alertAction: {
                        switch signInStage {
                        case .enterNumber:
                            signInStage = .choosingMethod
                        case .verifyNumber:
                            signInStage = .enterNumber
                        default:
                            // name username entry
                            signInStage = signInMethod == .phone ? .verifyNumber : .choosingMethod
                        }
                    }, alertTitle: "Go Back?", alertSubtitle: "If you go back, you'll lose whatever sign in progress you made on this page.", hasCancel: true, actionLabel: "Yes, go back")
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 25))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(maxHeight: 100, alignment: .bottom)
                        .padding(.bottom, 5)
                }
                Text("Sign In")
                    .font(formatter.font(fontSize: .large))
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 100, alignment: .bottom)
            }
            .padding()
            .foregroundColor(formatter.color(.highContrastWhite))
            .background(formatter.color(.primaryAccent))
            .frame(maxHeight: 150)
            .cornerRadius(30, corners: [.bottomLeft, .bottomRight])
        }
    }
}

struct LoadingView: View {
    @EnvironmentObject var formatter: MasterHandler
    @State var timeElapsed = 0
    
    let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    var color: ColorType = .highContrastWhite
    
    var ticker: Int {
        return timeElapsed % 3
    }
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: 7, height: 7)
                .foregroundColor(formatter.color(color))
                .offset(y: ticker == 0 ? -10 : 0)
            Circle()
                .frame(width: 7, height: 7)
                .foregroundColor(formatter.color(color))
                .offset(y: ticker == 1 ? -10 : 0)
            Circle()
                .frame(width: 7, height: 7)
                .foregroundColor(formatter.color(color))
                .offset(y: ticker == 2 ? -10 : 0)
        }
        .animation(Animation.easeInOut(duration: 0.25))
        .onReceive(timer) { time in
            timeElapsed += 1
        }
    }
}

struct SpinningLoaderView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.2, to: 1)
                .stroke(formatter.color(.highContrastWhite), lineWidth: 5)
                .frame(width: 30, height: 30)
                .rotationEffect(Angle(degrees: isAnimating ? 0 : 360))
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

enum SignInStage {
    case choosingMethod, enterNumber, verifyNumber, nameUsername
}
