//
//  BuildView.swift
//  Trivio
//
//  Created by David Chen on 3/12/21.
//

import Foundation
import SwiftUI

struct BuildView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var searchVM: SearchViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var editingName = false
    @State var showingSaveDraft = false
    @State var categoryIndex = 0
    
    var isDJ: Bool {
        return buildVM.buildStage == .dtRound || buildVM.buildStage == .dtRoundDD
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 3) {
            if buildVM.currentDisplay != .buildAll {
                HStack (alignment: .top, spacing: 0) {
                    BuildHUDView()
                    // I am NOT going to rename this!! Explanation: this was the name when it belonged in the footer. Hope that helps, David!
                    BuildFooterView()
                }
            }
            Group {
                switch buildVM.currentDisplay {
                case .settings:
                    BuildDetailsView()
                        .padding(.horizontal)
                case .buildAll:
                    BuildAllView(category: isDJ ? $buildVM.djCategories[categoryIndex] : $buildVM.jCategories[categoryIndex], categoryIndex: $categoryIndex)
                case .finalTrivio:
                    BuildFinalTrivioView()
                        .padding(.horizontal)
                default:
                    BuildGridView(categoryIndex: $categoryIndex)
                }
            }
        }
        .withBackButton()
        .withBackground()
        .navigationTitle(buildVM.currCustomSet.title.isEmpty ? "Build set" : buildVM.currCustomSet.title)
        .navigationBarTitleDisplayMode(.inline)
        .font(formatter.font(fontSize: .medium))
        .toolbar {
            ToolbarItem {
                Button(action: {
                    formatter.resignKeyboard()
                    buildVM.writeToFirestore()
                }) {
                    ZStack {
                        Text(buildVM.dirtyBit == 0 ? "Saved" : "Save")
                    }
                    .font(formatter.font(fontSize: .regular))
                    .foregroundColor(formatter.color(.primaryFG))
                    .padding(.horizontal).padding(.vertical, 5)
                    .background(formatter.color(buildVM.dirtyBit == 0 ? .lowContrastWhite : .highContrastWhite))
                    .clipShape(Capsule())
                }
                .opacity(buildVM.currCustomSet.title.isEmpty ? 0 : 1)
                .disabled(buildVM.dirtyBit == 0)
            }
        }
    }
}

