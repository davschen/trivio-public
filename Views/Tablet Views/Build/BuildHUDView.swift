//
//  BuildHUDView.swift
//  Trivio!
//
//  Created by David Chen on 7/22/21.
//

import Foundation
import SwiftUI

struct BuildHUDView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    let buildStageIndexDict = BuildStageIndexDict()
    
    var mostAdvancedStageIndex: Int {
        return buildStageIndexDict.getIndex(from: buildVM.mostAdvancedStage)
    }
    
    func getBuildStageIndex(_ buildStage: BuildStage) -> Int {
        return buildStageIndexDict.getIndex(from: buildStage)
    }
    
    var body: some View {
        HStack (spacing: 0) {
            Image(systemName: "gear")
                .foregroundColor(formatter.color(.highContrastWhite))
                .font(formatter.iconFont(.mediumLarge))
                .frame(width: 110, height: 60)
                .background(formatter.color(.primaryFG))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(formatter.color(.highContrastWhite), lineWidth: buildVM.buildStage == .details ? 2 : 0)
                )
                .onTapGesture {
                    formatter.hapticFeedback(style: .rigid)
                    buildVM.buildStage = .details
                    buildVM.currentDisplay = .settings
                }
            Text("Round 1")
                .font(formatter.font(fontSize: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(formatter.color(.secondaryFG))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(formatter.color(.highContrastWhite), lineWidth: buildVM.buildStage == .trivioRound ? 2 : 0)
                )
                .opacity(getBuildStageIndex(.trivioRound) <= mostAdvancedStageIndex ? 1 : 0.4)
                .onTapGesture {
                    // In case a user is confused and wants to move on
                    formatter.resignKeyboard()
                    if getBuildStageIndex(.trivioRound) <= mostAdvancedStageIndex {
                        formatter.hapticFeedback(style: .rigid)
                        buildVM.changePointValues(isAdvancing: false)
                        buildVM.buildStage = .trivioRound
                        buildVM.currentDisplay = .grid
                    }
                }
            Text("SELECT 1 \n WAGER-VALUE \n CLUE")
                .font(formatter.font(fontSize: .small))
                .padding(.horizontal, 10)
                .frame(height: 60)
                .multilineTextAlignment(.center)
                .background(formatter.color(.primaryAccent))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(formatter.color(.highContrastWhite), lineWidth: buildVM.buildStage == .trivioRoundDD ? 2 : 0)
                )
                .opacity(getBuildStageIndex(.trivioRoundDD) <= mostAdvancedStageIndex ? 1 : 0.4)
                .onTapGesture {
                    if getBuildStageIndex(.trivioRoundDD) <= mostAdvancedStageIndex {
                        formatter.hapticFeedback(style: .rigid)
                        buildVM.changePointValues(isAdvancing: false)
                        buildVM.buildStage = .trivioRoundDD
                        buildVM.currentDisplay = .grid
                    }
                }
            if buildVM.currCustomSet.hasTwoRounds {
                Text("Round 2")
                    .font(formatter.font(fontSize: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(formatter.color(.secondaryFG))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(formatter.color(.highContrastWhite), lineWidth: buildVM.buildStage == .dtRound ? 2 : 0)
                    )
                    .opacity(getBuildStageIndex(.dtRound) <= mostAdvancedStageIndex ? 1 : 0.4)
                    .onTapGesture {
                        if getBuildStageIndex(.dtRound) <= mostAdvancedStageIndex {
                            formatter.hapticFeedback(style: .rigid)
                            buildVM.changePointValues(isAdvancing: true)
                            buildVM.buildStage = .dtRound
                            buildVM.currentDisplay = .grid
                        }
                    }
                Text("SELECT 2 \n WAGER-VALUE \n CLUES")
                    .font(formatter.font(fontSize: .small))
                    .padding(.horizontal, 10)
                    .multilineTextAlignment(.center)
                    .frame(height: 60)
                    .background(formatter.color(.primaryAccent))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(formatter.color(.highContrastWhite), lineWidth: buildVM.buildStage == .dtRoundDD ? 2 : 0)
                    )
                    .opacity(getBuildStageIndex(.dtRoundDD) <= mostAdvancedStageIndex ? 1 : 0.4)
                    .onTapGesture {
                        if getBuildStageIndex(.dtRoundDD) <= mostAdvancedStageIndex {
                            formatter.hapticFeedback(style: .rigid)
                            buildVM.changePointValues(isAdvancing: true)
                            buildVM.buildStage = .dtRoundDD
                            buildVM.currentDisplay = .grid
                        }
                    }
            }
            Text("Final Clue")
                .font(formatter.font(fontSize: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(formatter.color(.secondaryFG))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(formatter.color(.highContrastWhite), lineWidth: buildVM.buildStage == .finalTrivio ? 2 : 0)
                )
                .opacity(getBuildStageIndex(.finalTrivio) <= mostAdvancedStageIndex ? 1 : 0.4)
                .onTapGesture {
                    if getBuildStageIndex(.finalTrivio) <= mostAdvancedStageIndex {
                        formatter.hapticFeedback(style: .rigid)
                        buildVM.buildStage = .finalTrivio
                        buildVM.currentDisplay = .finalTrivio
                    }
                }
        }
        .padding(.bottom, buildVM.currentDisplay == .grid ? 10 : 0)
    }
}

struct DuplexSelectionMethodView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    var body: some View {
        HStack (spacing: 5) {
            Text("Random")
                .padding(5)
                .padding(.horizontal, 5)
                .background(formatter.color(buildVM.isRandomDD ? .primaryAccent : .primaryFG))
                .cornerRadius(3)
                .onTapGesture {
                    formatter.hapticFeedback(style: .rigid, intensity: .weak)
                    if !buildVM.isRandomDD {
                        buildVM.randomDDs()
                    }
                    buildVM.isRandomDD = true
                }
            Text("Manual")
                .padding(5)
                .padding(.horizontal, 5)
                .background(formatter.color(buildVM.isRandomDD ? .primaryFG : .primaryAccent))
                .cornerRadius(3)
                .onTapGesture {
                    formatter.hapticFeedback(style: .rigid, intensity: .weak)
                    if buildVM.isRandomDD {
                        buildVM.clearDailyDoubles()
                    }
                    buildVM.isRandomDD = false
                }
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(formatter.color(buildVM.ddsFilled() ? .highContrastWhite : .lowContrastWhite))
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
