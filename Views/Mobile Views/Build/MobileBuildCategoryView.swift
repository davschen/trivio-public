//
//  MobileBuildCategoryView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI

struct MobileBuildCategoryView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    @Binding var categoryIndex: Int
    @Binding var category: CustomSetCategory
    @Binding var isShowingPreview: Bool
    
    @State var index: Int
    
    var body: some View {
        VStack (spacing: 7) {
            ZStack {
                if isShowingPreview && category.name.isEmpty {
                    Text("")
                } else {
                    Text(category.name.isEmpty ? "ADD NAME" : category.name.uppercased())
                }
            }
            .id(category.name)
            .font(formatter.font(category.name.isEmpty ? .boldItalic : .bold))
            .foregroundColor(formatter.color(category.name.isEmpty ? .lowContrastWhite : .highContrastWhite))
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.1)
            .padding(10)
            .frame(width: 165, height: 90)
            .background(formatter.color(.primaryAccent))
            .cornerRadius(10)
            .onTapGesture {
                formatter.hapticFeedback(style: .rigid, intensity: .weak)
                
                if buildVM.buildStage == .trivioRoundDD || buildVM.buildStage == .dtRoundDD {
                    return
                }
                
                buildVM.currentDisplay = .buildAll
                buildVM.editingCategoryIndex = index
                buildVM.setEditingIndex(index: 0)
                
                if buildVM.buildStage == .dtRound {
                    buildVM.djCategories[index].setIndex(index: index)
                } else {
                    buildVM.jCategories[index].setIndex(index: index)
                }
                
                categoryIndex = index
            }
            VStack (spacing: 5) {
                ForEach(0..<category.clues.count, id: \.self) { i in
                    let amount = buildVM.moneySections[i]
                    let clue = category.clues[i]
                    let response = category.responses[i]
                    MobileBuildCellView(
                        isShowingPreview: $isShowingPreview,
                        categoryIndex: $categoryIndex,
                        category: $category,
                        index: $index,
                        i: i,
                        amount: amount,
                        clue: clue,
                        response: response
                    )
                }
            }
        }
    }
}

