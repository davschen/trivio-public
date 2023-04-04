//
//  ContentView.swift
//  Shared
//
//  Created by David Chen on 5/23/21.
//

import SwiftUI
import CoreData
import FirebaseFirestoreSwift
import FirebaseFirestore

struct ContentView: View {
    @State var isLoggedIn = UserDefaults.standard.value(forKey: "isLoggedIn") as? Bool ?? false
    @ObservedObject var formatter = MasterHandler()
    @ObservedObject var authVM = AuthViewModel()
    
    init() {
        // NavigationBar UI
        UINavigationBar.appearance().tintColor = UIColor(formatter.color(.highContrastWhite))
        UINavigationBar.appearance().barTintColor = UIColor(formatter.color(.primaryFG))
        UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor(formatter.color(.highContrastWhite)), NSAttributedString.Key.font: UIFont(name: "Metropolis-Bold", size: 24)!]
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor(formatter.color(.highContrastWhite)), NSAttributedString.Key.font: UIFont(name: "Metropolis-Bold", size: formatter.shrink(iPadSize: 30))!]
        UINavigationBar.appearance().backgroundColor = UIColor(formatter.color(.primaryFG))
        
        // TabBar UI
        UITabBar.appearance().backgroundColor = UIColor(formatter.color(.primaryFG))
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Metropolis-Bold", size: 10)!], for: .normal)
        
        UIScrollView.appearance().keyboardDismissMode = .interactive
    }
    
    var body: some View {
        ZStack {
            if formatter.deviceType == .iPad {
                if !isLoggedIn {
                    SignInView(isLoggedIn: $isLoggedIn)
                        .foregroundColor(formatter.color(.highContrastWhite))
                        .environmentObject(formatter)
                        .environmentObject(authVM)
                } else {
                    TabletContentView()
                        .transition(.identity)
                }
            } else if formatter.deviceType == .iPhone {
                ZStack {
                    if !isLoggedIn {
                        MobileSignInView(isLoggedIn: $isLoggedIn)
                            .foregroundColor(formatter.color(.highContrastWhite))
                            .environmentObject(formatter)
                            .environmentObject(authVM)
                    } else {
                        MobileContentView()
                            .transition(.identity)
                    }
                }
            }
        }
        .foregroundColor(formatter.color(.highContrastWhite))
        .font(formatter.font())
        .animation(.easeInOut(duration: 0.1))
        .onAppear {
            NotificationCenter.default.addObserver(forName: NSNotification.Name("LogInStatusChange"), object: nil, queue: .main) { (_) in
                let isLoggedIn = UserDefaults.standard.value(forKey: "isLoggedIn") as? Bool ?? false
                self.isLoggedIn = isLoggedIn
            }
        }
    }
}
