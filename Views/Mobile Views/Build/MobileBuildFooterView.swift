//
//  MobileBuildFooterView.swift
//  Trivio!
//
//  Created by David Chen on 10/28/22.
//

import Foundation
import SwiftUI

struct MobileBuildFooterView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    var bgColor: Color {
        return formatter.color(.primaryBG)
    }
    
    var body: some View {
        HStack {
            if buildVM.buildStage != .details {
                Button {
                    formatter.hapticFeedback(style: .soft, intensity: .weak)
                    buildVM.back()
                } label: {
                    Text("Back")
                        .padding(.horizontal, 30)
                        .padding(.vertical, 20)
                        .background(formatter.color(.highContrastWhite))
                        .clipShape(Capsule())
                }
            }
            
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
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(formatter.color(buildVM.buildStage == .finalTrivio ? .secondaryAccent : .highContrastWhite))
                } else {
                    HStack {
                        Text("Publish")
                        Image(systemName: "wand.and.stars")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(formatter.color(buildVM.buildStage == .finalTrivio ? .secondaryAccent : .highContrastWhite))
                }
            }
            .clipShape(Capsule())
            .opacity(buildVM.nextPermitted() ? 1 : 0.4)
        }
        .padding(.top, buildVM.currentDisplay == .grid ? 0 : 15)
        .padding([.horizontal, .bottom])
        .foregroundColor(formatter.color(.primaryBG))
        .background(maskedBackgroundView())
        .animation(Animation.easeIn(duration: 0.2))
    }
    
    func maskedBackgroundView() -> some View {
        return Group {
            if buildVM.currentDisplay == .grid {
                formatter.color(.primaryBG)
            } else {
                formatter.color(.primaryBG)
                    .mask(LinearGradient(gradient: Gradient(colors: [bgColor, bgColor, bgColor, bgColor, .clear]), startPoint: .bottom, endPoint: .top))
            }
        }
    }
}
