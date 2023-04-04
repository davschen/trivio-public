//
//  FinalTrivioUserFlowView.swift
//  Trivio!
//
//  Created by David Chen on 12/8/22.
//

import Foundation
import SwiftUI

struct FinalTrivioView: View {
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
            return "PODIUM"
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
        HStack (spacing: 10) {
            // Clue view side rail (left)
            VStack (spacing: 10) {
                if gamesVM.finalTrivioStage == .makeWager {
                    Text("FINAL CLUE CATEGORY")
                        .font(formatter.font(.bold, fontSize: .mediumLarge))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding([.horizontal, .top], 45)
                    Spacer()
                    Text(gamesVM.customSet.finalCat.uppercased())
                        .font(formatter.font(.bold, fontSize: .extraLarge))
                        .multilineTextAlignment(.center)
                        .lineSpacing(7)
                        .padding()
                        .padding(.bottom, 30)
                    Spacer()
                } else {
                    Text(gamesVM.customSet.finalCat.uppercased())
                        .font(formatter.font(.bold, fontSize: .mediumLarge))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding([.horizontal, .top], 45)
                    Spacer()
                    Text(gamesVM.customSet.finalClue.uppercased())
                        .font(formatter.font(.bold, fontSize: .large))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(25)
                    if (gamesVM.finalTrivioStage == .revealResponse || gamesVM.finalTrivioStage == .podium) {
                        Text(gamesVM.customSet.finalResponse.uppercased())
                            .font(formatter.font(.bold, fontSize: .large))
                            .multilineTextAlignment(.center)
                            .foregroundColor(formatter.color(.secondaryAccent))
                            .padding()
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(formatter.color(.primaryAccent))
            .cornerRadius(10)
            
            // Flow side rail (right)
            VStack {
                ScrollView (.vertical, showsIndicators: false) {
                    VStack (spacing: 5) {
                        if gamesVM.finalTrivioStage != .podium {
                            HStack {
                                Text(headingLabelText)
                                    .font(formatter.font(.bold, fontSize: .medium))
                                Spacer()
                                Button(action: {
                                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                                    isShowingInstructions.toggle()
                                }, label: {
                                    Image(systemName: isShowingInstructions ? "questionmark.circle.fill" : "questionmark.circle")
                                        .font(formatter.iconFont(.medium))
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
                        }
                        if gamesVM.finalTrivioStage == .podium {
                            FinalTrivioPodiumView()
                        } else {
                            VStack (spacing: 15) {
                                // Each player's textbox for entering wagers
                                ForEach(participantsVM.teams, id: \.self) { team in
                                    if team.score > 0 {
                                        switch gamesVM.finalTrivioStage {
                                        case .makeWager:
                                            MakeWagerView(teamIndex: team.index)
                                        case .submitAnswer:
                                            SubmitAnswerView(teamIndex: team.index)
                                        default:
                                            RevealGradeView(teamIndex: team.index)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .resignKeyboardOnDragGesture()
                
                if gamesVM.finalTrivioStage != .podium {
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
                            .padding(.leading, 25)
                            .frame(maxWidth: .infinity)
                            .background(formatter.color(.highContrastWhite))
                            .clipShape(Capsule())
                            .contentShape(Capsule())
                            .opacity(submissionsAllValid ? 1 : 0.4)
                    })
                }
            }
            .frame(maxWidth: 450)
            .onAppear {
                var hasPositiveScores = false
                participantsVM.teams.forEach { team in
                    team.score > 0 ? (hasPositiveScores = true) : ()
                }
                hasPositiveScores ? () : (gamesVM.finalTrivioStage = .podium)
            }
        }
    }
}

struct FinalTrivioCountdownTimerView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @State var timeRemaining: Double = 30
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            Capsule()
                .frame(width: geometry.size.width)
                .foregroundColor(formatter.color(.primaryFG))
            Rectangle()
                .frame(width: timeRemaining > 0 ? geometry.size.width * CGFloat(Double(timeRemaining) / 30) : 0)
                .foregroundColor(formatter.color(.secondaryAccent))
                .animation(.linear(duration: 1))
        }
        .frame(height: 8)
        .clipShape(Capsule())
        .onReceive(timer) { time in
            if !formatter.speaker.isSpeaking {
                self.timeRemaining -= 1
            }
        }
    }
}
