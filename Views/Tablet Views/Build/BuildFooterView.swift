//
//  BuildFooterView.swift
//  Trivio!
//
//  Created by David Chen on 12/8/22.
//

import Foundation
import SwiftUI

struct BuildFooterView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    var bgColor: Color {
        return formatter.color(.primaryBG)
    }
    
    var body: some View {
        HStack (spacing: 5) {
            Button {
                formatter.hapticFeedback(style: .soft, intensity: .weak)
                buildVM.back()
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 60, height: 60)
                    .background(formatter.color(.highContrastWhite))
                    .cornerRadius(5)
            }
            .disabled(buildVM.buildStage == .details)
            .opacity(buildVM.buildStage == .details ? 0.4 : 1)
            Button {
                formatter.resignKeyboard()
                if buildVM.nextPermitted() {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    if buildVM.buildStage == .finalTrivio {
                        presentationMode.wrappedValue.dismiss()
                        gamesVM.readCustomData()
                    }
                    buildVM.nextButtonHandler()
                }
            } label: {
                if buildVM.buildStage != .finalTrivio {
                    Image(systemName: "chevron.right")
                        .frame(width: 60, height: 60)
                        .background(formatter.color(.highContrastWhite))
                        .cornerRadius(5)
                } else {
                    VStack {
                        Image(systemName: "wand.and.stars")
                        Text("Publish")
                            .font(formatter.font(fontSize: .small))
                    }
                    .frame(width: 80, height: 60)
                    .background(formatter.color(.secondaryAccent))
                    .cornerRadius(5)
                }
            }
            .opacity(buildVM.nextPermitted() ? 1 : 0.4)
        }
        .font(formatter.font(fontSize: .medium))
        .foregroundColor(formatter.color(.primaryBG))
        .padding(.horizontal, 5)
        .animation(Animation.easeIn(duration: 0.2))
    }
}
