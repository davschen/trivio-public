//
//  BuildHeaderView.swift
//  Trivio!
//
//  Created by David Chen on 7/22/21.
//

import Foundation
import SwiftUI

struct BuildHeaderView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @Binding var showingEdit: Bool
    @Binding var editingName: Bool
    @Binding var showingSaveDraft: Bool
    
    var body: some View {
        HStack (spacing: 15) {
            if buildVM.currentDisplay == .grid {
                Button(action: {
                    setSaveDraftAlert()
                }, label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 30, weight: .bold))
                })
            }
            Text("Build")
                .font(formatter.font(fontSize: .extraLarge))
            
            BuildTickerView()
            
            Spacer()
            
            // Save and Next/Finish buttons
            HStack {
                if buildVM.currentDisplay == .grid {
                    Button(action: {
                        buildVM.writeToFirestore()
                    }) {
                        ZStack {
                            if buildVM.processPending {
                                LoadingView(color: .primaryFG)
                            } else {
                                Text("Save")
                            }
                        }
                        .font(formatter.font(fontSize: .mediumLarge))
                        .foregroundColor(formatter.color(.primaryFG))
                        .padding(10)
                        .background(formatter.color(.highContrastWhite))
                        .cornerRadius(5)
                    }
                }
                Button(action: {
                    if buildVM.nextPermitted() {
                        buildVM.nextButtonHandler()
                    }
                }, label: {
                    ZStack {
                        if buildVM.processPending {
                            LoadingView(color: .primaryFG)
                        } else {
                            Text(buildVM.buildStage == .details ? "Publish" : "Next")
                        }
                    }
                    .font(formatter.font(fontSize: .mediumLarge))
                    .foregroundColor(formatter.color(.primaryFG))
                    .padding(10)
                    .background(formatter.color(buildVM.nextPermitted() ? .highContrastWhite : .lowContrastWhite))
                    .cornerRadius(5)
                })
            }
        }
    }
    
    func setSaveDraftAlert() {
        formatter.setAlertSettings(alertAction: {
            buildVM.showingBuildView.toggle()
        },
        alertTitle: "Save Before Leaving?",
        alertSubtitle: "If you go leave without saving, all of your progress will be lost",
        hasCancel: true,
        actionLabel: "Leave without saving",
        hasSecondaryAction: true,
        secondaryAction: {
            buildVM.writeToFirestore()
        },
        secondaryActionLabel: "Save")
    }
}

struct BuildTickerView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    var body: some View {
        HStack (alignment: .bottom, spacing: 15) {
            ProgressTextDotView(buildStage: .trivioRound)
            ProgressTextDotView(buildStage: .trivioRoundDD)
            ProgressTextDotView(buildStage: .dtRound)
            ProgressTextDotView(buildStage: .dtRoundDD)
            ProgressTextDotView(buildStage: .finalTrivio)
            ProgressTextDotView(buildStage: .details)
        }
        .padding(.horizontal, 20)
    }
}

struct ProgressTextDotView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    let buildStageIndexDict = BuildStageIndexDict()
    let buildStage: BuildStage
    
    var buildStageIndex: Int {
        return buildStageIndexDict.getIndex(from: buildStage)
    }
    
    var buildVMStageIndex: Int {
        return buildStageIndexDict.getIndex(from: buildVM.buildStage)
    }
    
    var body: some View {
        ZStack {
            if buildVM.buildStage == buildStage {
                Text(buildVM.stepStringHandler())
                    .font(formatter.font(fontSize: .large))
                    .offset(y: 2)
            } else {
                Circle()
                    .frame(width: 10, height: 10)
                    .offset(y: -3)
                    .foregroundColor(formatter.color(buildStageIndex > buildVMStageIndex ? .lowContrastWhite : .highContrastWhite))
            }
        }
    }
}

struct BuildStageIndexDict {
    var dict: [BuildStage:Int] = [
        .details: 0,
        .trivioRound: 1,
        .trivioRoundDD: 2,
        .dtRound: 3,
        .dtRoundDD: 4,
        .finalTrivio: 5
    ]
    
    func getIndex(from buildStage: BuildStage) -> Int {
        return dict[buildStage] ?? 0
    }
}
