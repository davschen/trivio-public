//
//  DuplexWagerView.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 7/20/21.
//

import Foundation
import SwiftUI

struct DuplexWagerView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @Binding var ddWagerMade: Bool
    @Binding var wager: Double
    
    @State var questionIsSelected = false
    
    var maxScore: Int {
        return gamesVM.gamePhase == .round1 ? 1000 : 2000
    }
    
    var body: some View {
        VStack (spacing: 0) {
            ZStack (alignment: .trailing) {
                Text(gamesVM.currentSelectedClue.categoryString.uppercased())
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity, alignment: .center)
                Button {
                    questionIsSelected.toggle()
                } label: {
                    Image(systemName: questionIsSelected ? "questionmark.circle.fill" : "questionmark.circle")
                        .font(formatter.iconFont(.medium))
                }
            }
            .font(formatter.font(.regular, fontSize: .mediumLarge))
            .id(gamesVM.currentSelectedClue.categoryString)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(20)
            .background(formatter.color(.mediumContrastWhite).opacity(0.7))
            
            Spacer()
            
            ZStack (alignment: .bottomTrailing) {
                VStack (spacing: 30) {
                    Spacer()
                    Text("WAGER-VALUE CLUE")
                        .font(formatter.fontFloat(sizeFloat: 57))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(7)
                        .padding(.top, 10)
                    
                    VStack (spacing: 10) {
                        HStack {
                            Text("\(participantsVM.teams[participantsVM.selectedTeam.index].name), make a wager:")
                            Spacer()
                            Text("\(Int(self.wager))")
                        }
                        .font(formatter.font(.regular, fontSize: .medium))
                        .frame(maxWidth: 600, alignment: .center)
                        if #available(iOS 16.0, *) {
                            Slider(value: $wager, in: 0...Double(max(maxScore, participantsVM.teams.indices.contains(participantsVM.selectedTeam.index) ? participantsVM.teams[participantsVM.selectedTeam.index].score : 0)), step: 100)
                                .accentColor(formatter.color(.secondaryAccent))
                                .tint(formatter.color(.secondaryAccent))
                                .foregroundColor(formatter.color(.mediumContrastWhite).opacity(0.8))
                        } else {
                            Slider(value: $wager, in: 0...Double(max(maxScore, participantsVM.teams.indices.contains(participantsVM.selectedTeam.index) ? participantsVM.teams[participantsVM.selectedTeam.index].score : 0)), step: 100)
                                .accentColor(formatter.color(.secondaryAccent))
                                .foregroundColor(formatter.color(.mediumContrastWhite).opacity(0.8))
                        }
                    }
                    .frame(maxWidth: 600, alignment: .center)
                    .padding(.bottom, 50)
                    if questionIsSelected {
                        Text("""
                        Select a wager using the slider above. Game show rules apply to wager amounts. The number you choose will either be added or subtracted from your score, depending on if you get it right.

                        When you tap the button at the bottom of the screen, a question will appear. Only the contestant highlighted (\(participantsVM.teams[participantsVM.selectedTeam.index].name) may answer. If the answer given is correct, reward David the points. If the answer given is incorrect, subtract the points. When finished, tap anywhere to proceed.
                        """)
                            .font(formatter.font(.regularItalic, fontSize: .regular))
                            .frame(maxWidth: 600, alignment: .center)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 40)
                Button {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    self.ddWagerMade.toggle()
                    self.formatter.speaker.speak(gamesVM.currentSelectedClue.clueString)
                } label: {
                    Text("Show the clue")
                        .font(formatter.font(fontSize: .regular))
                        .foregroundColor(formatter.color(.highContrastWhite))
                        .padding(25)
                        .frame(maxWidth: 200)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(formatter.color(.highContrastWhite), lineWidth: 2)
                        )
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .background(formatter.color(.primaryAccent))
        .cornerRadius(10)
    }
}

