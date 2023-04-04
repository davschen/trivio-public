//
//  BuildGridView.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 1/20/23.
//

import Foundation
import SwiftUI

struct BuildGridView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel

    @Binding var categoryIndex: Int
    
    @State var isShowingPreview = false
    @State var showsDuplexExplanation = false
    
    var isDJ: Bool {
        return buildVM.buildStage == .dtRound || buildVM.buildStage == .dtRoundDD
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 5) {
            if buildVM.buildStage == .trivioRound || buildVM.buildStage == .dtRound {
                BuildGridEntryView(isShowingPreview: $isShowingPreview)
                    .frame(height: 40)
            } else if buildVM.buildStage == .trivioRoundDD || buildVM.buildStage == .dtRoundDD {
                VStack (alignment: .leading) {
                    HStack {
                        Text("Wager-Value Clues")
                            .font(formatter.font(fontSize: .mediumLarge))
                        Button {
                            showsDuplexExplanation.toggle()
                        } label: {
                            Image(systemName: showsDuplexExplanation ? "questionmark.circle.fill" : "questionmark.circle")
                                .font(formatter.iconFont(.mediumLarge))
                        }
                        Spacer()
                        Button {
                            buildVM.randomDDs()
                        } label: {
                            Text("Random")
                                .font(formatter.fontFloat(sizeFloat: 20))
                                .frame(width: 120, height: 40)
                                .background(formatter.color(.green))
                                .clipShape(Capsule())
                        }
                    }
                    .frame(height: 40)
                    if showsDuplexExplanation {
                        Text("Pick \(buildVM.buildStage == .trivioRoundDD ? "a" : "two") particularly difficult clue\(buildVM.buildStage == .trivioRoundDD ? "" : "s") to serve as your clues whose points are determined by the contestant's wager.")
                            .font(formatter.font(.regularItalic, fontSize: .small))
                    }
                }
                .padding(.horizontal, 25)
            }
            HStack (spacing: 5) {
                ForEach(0..<(isDJ ? self.buildVM.djCategories.count : self.buildVM.jCategories.count), id: \.self) { i in
                    let toShow = isDJ ? buildVM.round2CatsShowing : buildVM.round1CatsShowing
                    if i <= (toShow.count - 1) && toShow[i] {
                        BuildGridCategoryView(
                            categoryIndex: $categoryIndex,
                            category: (isDJ ? $buildVM.djCategories[i] : $buildVM.jCategories[i]),
                            isShowingPreview: $isShowingPreview,
                            index: i
                        ).id(i)
                    }
                }
            }
            .padding([.horizontal, .bottom], 25)
        }
    }
}

struct BuildGridEntryView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    @Binding var isShowingPreview: Bool
    
    var isDJ: Bool {
        return buildVM.buildStage == .dtRound || buildVM.buildStage == .dtRoundDD
    }
    
    var body: some View {
        HStack (spacing: 2) {
            Text("Categories (\(isDJ ? buildVM.currCustomSet.round2Len : buildVM.currCustomSet.round1Len))")
                .font(formatter.font(fontSize: .mediumLarge))
                .padding(.trailing, 10)
            Button {
                buildVM.subtractCategory()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(formatter.iconFont(.mediumLarge))
                    .opacity(isDJ ? (buildVM.currCustomSet.round2Len == 3 ? 0.4 : 1) : (buildVM.currCustomSet.round1Len == 3 ? 0.4 : 1))
            }
            Button {
                buildVM.addCategory()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(formatter.iconFont(.mediumLarge))
                    .opacity(isDJ ? (buildVM.currCustomSet.round2Len == 6 ? 0.4 : 1) : (buildVM.currCustomSet.round1Len == 6 ? 0.4 : 1))
            }
            Spacer()
            Text("Preview")
                .font(formatter.font(fontSize: .mediumLarge))
                .padding(.trailing, 10)
            ZStack(alignment: (isShowingPreview ? .trailing : .leading)) {
                Capsule()
                    .frame(width: 50, height: 25)
                    .foregroundColor(formatter.color(isShowingPreview ? .secondaryAccent : .secondaryFG))
                Circle()
                    .frame(width: 25, height: 25)
            }
            .onTapGesture {
                isShowingPreview.toggle()
            }
            .animation(Animation.easeIn(duration: 0.05))
        }
        .padding(.horizontal, 25)
    }
}
