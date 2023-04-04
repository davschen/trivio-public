//
//  FinalTrivioSubmitFieldView.swift
//  Trivio!
//
//  Created by David Chen on 12/8/22.
//

import Foundation
import SwiftUI

struct MakeWagerView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @State var hidden = false
    @State var wagerString = ""
    
    let teamIndex: Int
    
    var team: Team {
        return participantsVM.teams[teamIndex]
    }
    
    var wagerMade: Bool {
        let wager = participantsVM.wagers[teamIndex]
        return !wager.isEmpty && (Int(wager) != nil) && (Int(wager)! >= 0)
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 5) {
            HStack (spacing: 5) {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(ColorMap().getColor(color: team.color))
                Text(team.name)
                    .font(formatter.font(fontSize: .medium))
            }
            HStack {
                if hidden {
                    Text(wagerMade ? "Wager made" : "Make your wager")
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                        .font(formatter.font(.boldItalic, fontSize: .medium))
                } else {
                    TextField("Enter your wager", text: $wagerString) { didBeginEditing in
                        participantsVM.wagers[teamIndex] = wagerString
                        if !didBeginEditing {
                            hidden.toggle()
                        }
                    }
                    .keyboardType(.numberPad)
                }
                Spacer()
                Button(action: {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    participantsVM.wagers[teamIndex] = wagerString
                    hidden.toggle()
                }, label: {
                    Text("\(hidden ? "Edit" : "Done")")
                        .foregroundColor(formatter.color(.secondaryAccent))
                })
            }
            .font(formatter.font(fontSize: .medium))
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(formatter.color(hidden ? .primaryAccent : .secondaryFG))
            .cornerRadius(5)
            .contentShape(Rectangle())
            
            if !invalidWagerString(teamIndex: teamIndex).isEmpty {
                Text(invalidWagerString(teamIndex: teamIndex))
                    .font(formatter.font(.regularItalic))
                    .foregroundColor(formatter.color(.secondaryAccent))
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    func invalidWagerString(teamIndex: Int) -> String {
        if participantsVM.wagers[teamIndex].isEmpty {
            return ""
        }
        if Int(participantsVM.wagers[teamIndex]) == nil {
            return "You must enter a number"
        } else if Int(participantsVM.wagers[teamIndex])! > participantsVM.teams[teamIndex].score {
            return "Your wager cannot be higher than your score"
        } else if Int(participantsVM.wagers[teamIndex])! < 0 {
            return "Your wager cannot be negative. Nice try though."
        }
        return ""
    }
}

struct SubmitAnswerView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @State var hidden = false
    @State var responseString = ""
    
    let teamIndex: Int
    
    var team: Team {
        return participantsVM.teams[teamIndex]
    }
    
    var answerSubmitted: Bool {
        let answer = participantsVM.finalJeopardyAnswers[teamIndex]
        return !answer.isEmpty
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 5) {
            HStack (spacing: 5) {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(ColorMap().getColor(color: team.color))
                Text(team.name)
                    .font(formatter.font(fontSize: .medium))
                Spacer()
            }
            
            // Submit your answer textfield
            HStack {
                if hidden {
                    Text(answerSubmitted ? "Answer submitted!" : "Submit your answer")
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                        .font(formatter.font(.boldItalic, fontSize: .medium))
                } else {
                    TextField("Enter your response", text: $responseString) { didBeginEditing in
                        participantsVM.finalJeopardyAnswers[teamIndex] = responseString
                        if !didBeginEditing {
                            hidden.toggle()
                        }
                    }
                }
                Spacer()
                Button(action: {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    participantsVM.finalJeopardyAnswers[teamIndex] = responseString
                    hidden.toggle()
                }, label: {
                    Text("\(hidden ? "Edit" : "Done")")
                        .foregroundColor(formatter.color(.secondaryAccent))
                })
            }
            .font(formatter.font(fontSize: .medium))
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(formatter.color(hidden ? .primaryAccent : .secondaryFG))
            .cornerRadius(5)
            .contentShape(Rectangle())
        }
    }
}

struct RevealGradeView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    let teamIndex: Int
    
    var correct: Bool {
        return participantsVM.fjCorrects[teamIndex]
    }
    
    var incorrect: Bool {
        return participantsVM.toSubtracts[teamIndex]
    }
    
    var body: some View {
        VStack {
            HStack (spacing: 10) {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(ColorMap().getColor(color: participantsVM.teams[teamIndex].color))
                Text(participantsVM.teams[teamIndex].name)
                    .font(formatter.font(fontSize: .medium))
                    .minimumScaleFactor(0.3)
                Spacer()
            }
            
            // Reveals answer
            HStack (spacing: 0) {
                if !participantsVM.fjReveals[teamIndex] {
                    Text("REVEAL")
                        .font(formatter.font(.boldItalic, fontSize: .mediumLarge))
                } else {
                    Button {
                        formatter.hapticFeedback(style: .soft, intensity: .strong)
                        if participantsVM.fjCorrects[teamIndex] {
                            participantsVM.addFJCorrect(index: teamIndex)
                        }
                        participantsVM.addFJIncorrect(index: teamIndex)
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: 75)
                            .frame(maxHeight: .infinity)
                            .background(formatter.color(incorrect ? .red : .lowContrastWhite))
                    }
                    VStack (spacing: 5) {
                        Text(participantsVM.finalJeopardyAnswers[teamIndex])
                            .multilineTextAlignment(.center)
                        Text(!participantsVM.fjReveals[teamIndex] ? "" : ("Wager: " + participantsVM.wagers[teamIndex]))
                            .foregroundColor(formatter.color(incorrect ? .red : .green))
                            .font(formatter.font(.boldItalic, fontSize: .small))
                    }
                    .frame(maxWidth: .infinity)
                    Button {
                        formatter.hapticFeedback(style: .heavy, intensity: .strong)
                        if participantsVM.toSubtracts[teamIndex] {
                            participantsVM.addFJIncorrect(index: teamIndex)
                        }
                        participantsVM.addFJCorrect(index: teamIndex)
                    } label: {
                        Image(systemName: "checkmark")
                            .frame(width: 75)
                            .frame(maxHeight: .infinity)
                            .background(formatter.color(correct ? .green : .lowContrastWhite))
                    }
                }
            }
            .font(formatter.font(fontSize: .medium))
            .frame(maxWidth: .infinity)
            .frame(height: 75)
            .background(formatter.color(.secondaryFG))
            .contentShape(Rectangle())
            .cornerRadius(5)
            .onTapGesture {
                formatter.hapticFeedback(style: .rigid, intensity: .weak)
                participantsVM.fjReveals[teamIndex].toggle()
                participantsVM.setSelectedTeam(index: teamIndex)
            }
//
//            // View and grade answer
//            VStack (spacing: 10) {
//
//                // Grade answer
//                HStack {
//                    Button(action: {
//                        formatter.hapticFeedback(style: .soft, intensity: .strong)
//                        if self.participantsVM.fjCorrects[teamIndex] {
//                            self.participantsVM.addFJCorrect(index: teamIndex)
//                        }
//                        self.participantsVM.addFJIncorrect(index: teamIndex)
//                    }, label: {
//                        Image(systemName: "xmark")
//                            .font(.system(size: 20, weight: .bold))
//                            .foregroundColor(formatter.color(incorrect ? .highContrastWhite : .lowContrastWhite))
//                            .frame(maxWidth: .infinity)
//                    })
//                    Text(participantsVM.teams[teamIndex].name)
//                        .font(formatter.font(fontSize: .mediumLarge))
//                    Button(action: {
//                        formatter.hapticFeedback(style: .heavy, intensity: .strong)
//                        if self.participantsVM.toSubtracts[teamIndex] {
//                            self.participantsVM.addFJIncorrect(index: teamIndex)
//                        }
//                        self.participantsVM.addFJCorrect(index: teamIndex)
//                    }, label: {
//                        Image(systemName: "checkmark")
//                            .font(.system(size: 20, weight: .bold))
//                            .foregroundColor(formatter.color(correct ? .highContrastWhite : .lowContrastWhite))
//                            .frame(maxWidth: .infinity)
//                    })
//                }
//
//                // View wager if not hidden
//                Text(!participantsVM.fjReveals[teamIndex] ? "" : ("Wager: $" + participantsVM.wagers[teamIndex]))
//                    .font(formatter.font())
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(formatter.color(!participantsVM.fjReveals[teamIndex] ? .secondaryFG : (correct ? .green : (incorrect ? .red : .secondaryFG))))
//                    .cornerRadius(5)
//            }
//            .padding()
//            .background(formatter.color(.primaryFG))
//            .cornerRadius(5)
        }
        .frame(maxWidth: .infinity)
    }
}

