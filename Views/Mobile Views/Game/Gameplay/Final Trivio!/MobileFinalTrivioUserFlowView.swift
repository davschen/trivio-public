//
//  MobileFinalTrivioMakeWagerView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI

struct MobileFinalTrivioUserFlowView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @State var isShowingInstructions = false
    
    var submissionsAllValid: Bool {
        switch gamesVM.finalTrivioStage {
        case .makeWager:
            return participantsVM.wagersValid()
        case .revealResponse:
            return true
        default:
            return participantsVM.answersValid()
        }
    }
    
    var headingLabelText: String {
        switch gamesVM.finalTrivioStage {
        case .makeWager:
            return "WAGERS"
        case .submitAnswer:
            return "ANSWERS"
        case .revealResponse:
            return "RESULTS"
        default:
            return ""
        }
    }
    
    var guidanceLabelText: String {
        switch gamesVM.finalTrivioStage {
        case .makeWager:
            return """
            In the next screen, you will receive a clue under this category. Each player must wager some amount less than or equal to their own score. If your answer is correct, you will receive that amount. If not, your wager will be deducted from your total score.
            """
        case .submitAnswer:
            return """
            Submit your answer to the question above in under 30 seconds!
            """
        case .revealResponse:
            return """
            Reveal everyone’s answer one by one, and score accordingly.
            """
        default:
            return ""
        }
    }
    
    var body: some View {
        VStack {
            ScrollView (.vertical, showsIndicators: false) {
                VStack {
                    VStack (spacing: 10) {
                        if gamesVM.finalTrivioStage == .makeWager {
                            Text(gamesVM.customSet.finalCat.uppercased())
                                .font(formatter.font(.bold, fontSize: .mediumLarge))
                                .multilineTextAlignment(.center)
                        } else {
                            Text(gamesVM.customSet.finalCat.uppercased())
                                .font(formatter.font(.bold, fontSize: .medium))
                                .multilineTextAlignment(.center)
                            Text(gamesVM.customSet.finalClue)
                                .font(formatter.font(.regular, fontSize: .regular))
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                            Text(gamesVM.customSet.finalResponse)
                                .font(formatter.font(.regular, fontSize: .regular))
                                .foregroundColor(formatter.color(gamesVM.finalTrivioStage == .revealResponse ? .secondaryAccent : .primaryAccent))
                        }
                    }
                    .padding()
                    .frame(height: 150)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(formatter.color(.primaryAccent))
                    .cornerRadius(10)
                    .padding([.horizontal, .top], 10)
                    
                    VStack (spacing: 5) {
                        HStack {
                            Text(headingLabelText)
                                .font(formatter.font(.bold, fontSize: .medium))
                            Spacer()
                            Button(action: {
                                formatter.hapticFeedback(style: .soft, intensity: .strong)
                                isShowingInstructions.toggle()
                            }, label: {
                                Image(systemName: isShowingInstructions ? "questionmark.circle.fill" : "questionmark.circle")
                                    .font(formatter.iconFont(.small))
                            })
                        }
                        // Instructions (only shown if isShowingInstructions is true)
                        if isShowingInstructions {
                            Text(guidanceLabelText)
                                .font(formatter.font(.regularItalic, fontSize: .small))
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Spacer(minLength: 5)
                        VStack (spacing: 15) {
                            // Each player's textbox for entering wagers
                            ForEach(participantsVM.teams, id: \.self) { team in
                                if team.score > 0 {
                                    switch gamesVM.finalTrivioStage {
                                    case .makeWager:
                                        MobileMakeWagerView(teamIndex: team.index)
                                    case .submitAnswer:
                                        MobileSubmitAnswerView(teamIndex: team.index)
                                    default:
                                        MobileRevealGradeView(teamIndex: team.index)
                                    }
                                }
                            }
                        }
                    }
                    .padding(10)
                }
            }
            .background(formatter.color(.primaryFG))
            .cornerRadius(10)
            
            // Continue button
            Button(action: {
                if submissionsAllValid {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    gamesVM.finalTrivioFinishedAction()
                    if gamesVM.finalTrivioStage == .submitAnswer {
                        formatter.speaker.speak(gamesVM.customSet.finalClue)
                    }
                }
            }, label: {
                Text("Continue")
                    .foregroundColor(formatter.color(.primaryFG))
                    .font(formatter.font(fontSize: .regular))
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(formatter.color(.highContrastWhite))
                    .clipShape(Capsule())
                    .contentShape(Capsule())
                    .opacity(submissionsAllValid ? 1 : 0.4)
            })
        }
    }
}
