//
//  MobileBuildCellView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI

struct MobileBuildCellView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    @Binding var isShowingPreview: Bool
    @Binding var categoryIndex: Int
    @Binding var category: CustomSetCategory
    @Binding var index: Int
    
    var i: Int
    var amount: String
    var clue: String
    var response: String
    
    var isDJ: Bool {
        return buildVM.buildStage == .dtRound || buildVM.buildStage == .dtRoundDD
    }
    
    var body: some View {
        ZStack {
            if isShowingPreview {
                VStack (spacing: 5) {
                    Text(clue.uppercased())
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Text(response.uppercased())
                        .foregroundColor(formatter.color(.secondaryAccent))
                        .lineLimit(1)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .font(formatter.fontFloat(.bold, sizeFloat: 10.0))
            } else {
                ZStack {
                    Text("\(amount)")
                        .font(formatter.fontFloat(.bold, sizeFloat: 45.0))
                        .minimumScaleFactor(0.5)
                        .foregroundColor(formatter.color(.secondaryAccent).opacity((clue.isEmpty || response.isEmpty) ? 0.5 : 1))
                        .multilineTextAlignment(.center)
                    if (buildVM.buildStage == .trivioRound) || (buildVM.buildStage == .dtRound) {
                        Image(systemName: (clue.isEmpty || response.isEmpty) ? "plus.circle.fill" : "pencil.circle.fill")
                            .font(formatter.iconFont(.small))
                            .opacity(category.name.isEmpty ? 0 : 0.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(5)
                    }
                }
                .id(amount)
            }
        }
        .frame(width: 165)
        .frame(maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).stroke(
            (buildVM.buildStage == .trivioRound || buildVM.buildStage == .dtRound) ? formatter.color(.primaryAccent) : formatter.color(.highContrastWhite),
            lineWidth: buildVM.isDailyDouble(i: category.index, j: i) ? 5 : 0
        ))
        .background(formatter.color((clue.isEmpty || response.isEmpty) ? .secondaryFG : .primaryAccent).opacity((clue.isEmpty || response.isEmpty) ? 0.4 : 1))
        .cornerRadius(10)
        .onTapGesture {
            if (buildVM.buildStage == .trivioRoundDD
                || buildVM.buildStage == .dtRoundDD) {
                if (!category.clues[i].isEmpty && !category.responses[i].isEmpty) {
                    formatter.hapticFeedback(style: .heavy)
                    buildVM.addDailyDouble(i: category.index, j: i)
                }
            } else if !category.name.isEmpty {
                formatter.hapticFeedback(style: .rigid)
                buildVM.currentDisplay = .buildAll
                buildVM.setEditingIndex(index: i)
                buildVM.editingCategoryIndex = index
                categoryIndex = index
            }
        }
    }
}

struct MobileBuildCellHeldView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    var body: some View {
        VStack (spacing: 10) {
            Text(buildVM.cluePreview)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Text(buildVM.responsePreview)
                .foregroundColor(formatter.color(.secondaryAccent))
                .lineLimit(1)
        }
        .padding()
        .font(formatter.font(fontSize: .small))
    }
}

