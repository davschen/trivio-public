//
//  MobileQuickSignInWithApple.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 1/12/23.
//

import Foundation
import SwiftUI
import AuthenticationServices

struct QuickSignInWithApple: UIViewRepresentable {
  typealias UIViewType = ASAuthorizationAppleIDButton
  
  func makeUIView(context: Context) -> UIViewType {
      return ASAuthorizationAppleIDButton(type: .signIn, style: .white)
    // or just use UIViewType() 😊 Not recommanded though.
  }
  
  func updateUIView(_ uiView: UIViewType, context: Context) {
  }
}
