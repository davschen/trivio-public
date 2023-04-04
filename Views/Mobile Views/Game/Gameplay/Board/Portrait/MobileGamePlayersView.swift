//
//  MobileGamePlayersView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI
import MovingNumbersView

struct MobileGamePlayersView: View {
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    var body: some View {
        // Contestants HStack
        if participantsVM.teams.count > 0 {
            HStack (spacing: 5) {
                ForEach(participantsVM.teams) { team in
                    MobileIndividualPlayerView(team: team)
                }
            }
        } else {
            MobileSetupContestantsView()
        }
    }
}

struct MobileIndividualPlayerView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    let team: Team
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            HStack (spacing: 5) {
                VStack (alignment: .leading) {
                    Text("\(team.name)")
                        .font(formatter.font(fontSize: participantsVM.teams.count > 3 ? .regular : .medium))
                        .foregroundColor(formatter.color(.highContrastWhite))
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                    if team.members.count > 0 {
                        HStack (spacing: 3) {
                            Image(systemName: "mic.fill")
                                .foregroundColor(formatter.color(.highContrastWhite))
                                .font(formatter.iconFont(.small))
                            Text(participantsVM.spokespeople[team.index])
                                .font(formatter.font(.regularItalic, fontSize: .small))
                                .foregroundColor(formatter.color(.highContrastWhite))
                        }
                    }
                }
            }
            .padding(.horizontal, 7)
            Spacer(minLength: 0)
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 2)
                .foregroundColor(ColorMap().getColor(color: team.color))
            ZStack {
                HStack (spacing: 0) {
                    if participantsVM.teams[team.index].score < 0 {
                        Text("-")
                    }
                    MovingNumbersView(
                        number: Double(abs(participantsVM.teams[team.index].score)),
                        numberOfDecimalPlaces: 0) { str in
                            Text(str)
                                .frame(height: 30)
                        }
                }
            }
            .font(formatter.font(fontSize: .mediumLarge))
            .foregroundColor(formatter.color(participantsVM.teams[team.index].score < 0 ? .red : .highContrastWhite))
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(formatter.color(.primaryFG))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(formatter.color(.primaryAccent))
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5).stroke(formatter.color(.highContrastWhite), lineWidth: participantsVM.selectedTeam == team ? 2 : 0)
        )
        .onTapGesture {
            if !(participantsVM.selectedTeam == team) {
                participantsVM.setSelectedTeam(index: team.index)
            }
        }
        .onAppear {
            if !participantsVM.teams.contains(participantsVM.selectedTeam) {
                participantsVM.setSelectedTeam(index: 0)
            }
        }
    }
}

struct MobileSetupContestantsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    var body: some View {
        Button(action: {
            gamesVM.gameSetupMode = .participants
        }, label: {
            HStack {
                Text("Looks like you haven't set up any contestants - Tap to set up contestants")
                    .font(formatter.font(.regularItalic, fontSize: .mediumLarge))
                    .foregroundColor(formatter.color(.highContrastWhite))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, formatter.padding(size: 25))
            .background(formatter.color(.secondaryFG))
            .cornerRadius(formatter.cornerRadius(iPadSize: 5))
            .padding(.bottom, 10)
        })
    }
}

