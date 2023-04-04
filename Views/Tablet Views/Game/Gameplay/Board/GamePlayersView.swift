//
//  GamePlayersView.swift
//  Trivio!
//
//  Created by David Chen on 12/7/22.
//

import Foundation
import SwiftUI
import MovingNumbersView

struct GamePlayersView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    var body: some View {
        // Contestants HStack
        if participantsVM.teams.count > 0 {
            HStack (spacing: 10) {
                ForEach(participantsVM.teams) { team in
                    IndividualPlayerView(team: team)
                }
            }
        } else {
            SetupContestantsView()
        }
    }
}

struct IndividualPlayerView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    let team: Team
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            HStack (spacing: 5) {
                VStack (alignment: .leading) {
                    Text("\(team.name)")
                        .font(formatter.font(fontSize: .mediumLarge))
                        .foregroundColor(formatter.color(.highContrastWhite))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
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
            .padding(.horizontal, 15)
            Spacer(minLength: 0)
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 2)
                .foregroundColor(ColorMap().getColor(color: team.color))
            HStack (spacing: 0) {
                if participantsVM.teams[team.index].score < 0 {
                    Text("-")
                }
                ZStack {
                    Text("0")
                        .opacity(participantsVM.teams[team.index].score == 0 ? 1 : 0)
                        .animation(.easeInOut(duration: 0.1))
                    MovingNumbersView(
                        number: Double(abs(participantsVM.teams[team.index].score)),
                        numberOfDecimalPlaces: 0) { str in
                            Text(str)
                        }
                }
            }
            .font(formatter.font(fontSize: .large))
            .foregroundColor(formatter.color(participantsVM.teams[team.index].score < 0 ? .red : .highContrastWhite))
            .frame(minWidth: 30, maxWidth: .infinity)
            .frame(height: 40)
            .background(formatter.color(.primaryFG))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(formatter.color(.primaryAccent))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(formatter.color(.highContrastWhite), lineWidth: participantsVM.selectedTeam == team ? 2 : 0)
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

struct SetupContestantsView: View {
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

