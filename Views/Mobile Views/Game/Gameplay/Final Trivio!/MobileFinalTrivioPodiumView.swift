//
//  MobileFinalTrivioPodiumView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI

struct MobileFinalTrivioPodiumView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var rating = 0
    
    var body: some View {
        VStack (spacing: 15) {
            MobilePodiumsView()
            // Finished button
            Button(action: {
                guard let customSetID = gamesVM.customSet.id else { return }
                presentationMode.wrappedValue.dismiss()
                formatter.hapticFeedback(style: .soft, intensity: .strong)
                participantsVM.progressGame()
                profileVM.markAsPlayed(gameID: customSetID)
                participantsVM.writeToFirestore(gameID: customSetID, myRating: rating)
                participantsVM.resetScores()
                gamesVM.reset()
            }, label: {
                Text("Finish Game")
                    .foregroundColor(formatter.color(.primaryBG))
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(formatter.color(.highContrastWhite))
                    .clipShape(Capsule())
            })
        }
    }
}

struct MobileRatingView: View {
    // I intend on bringing this back someday but not today. Why? I cannot find a good design for it
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var rating: Int
    
    var range: [Int] {
        var retRange = [Int]()
        for i in (0..<5) {
            retRange.append(i)
        }
        return retRange
    }
    var body: some View {
        HStack (spacing: 3) {
            ForEach(range, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(formatter.iconFont(.small))
                    .foregroundColor(formatter.color(rating >= i + 1 ? .secondaryAccent : .secondaryFG))
                    .onTapGesture {
                        formatter.hapticFeedback(style: .rigid, intensity: .weak)
                        rating = i + 1
                    }
            }
        }
    }
}

struct MobilePodiumsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    var body: some View {
        ScrollView (.vertical, showsIndicators: false) {
            VStack {
                if let firstPlaceIndex = participantsVM.getTeamIndexForPlace(.first) {
                    MobileSinglePodiumView(teamIndex: firstPlaceIndex, placing: .first)
                }
                if let secondPlaceIndex = participantsVM.getTeamIndexForPlace(.second) {
                    MobileSinglePodiumView(teamIndex: secondPlaceIndex, placing: .second)
                }
                if let thirdPlaceIndex = participantsVM.getTeamIndexForPlace(.third) {
                    MobileSinglePodiumView(teamIndex: thirdPlaceIndex, placing: .third)
                }
            }
        }
    }
}

struct MobileSinglePodiumView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    let teamIndex: Int
    let placing: Placing
    
    var placeNumString: String {
        switch placing {
        case .first: return "1"
        case .second: return "2"
        case .third: return "3"
        }
    }
    
    var body: some View {
        VStack {
            HStack (spacing: 15) {
                Text(placeNumString)
                    .font(formatter.font(fontSize: .small))
                    .foregroundColor(formatter.color(.primaryAccent))
                    .frame(width: 30, height: 30)
                    .background(formatter.color(.highContrastWhite))
                    .clipShape(Circle())
                Text(participantsVM.teams[teamIndex].name)
                    .font(formatter.font(fontSize: .semiLarge))
                Spacer()
            }
            
            HStack (spacing: 0) {
                Rectangle()
                    .frame(width: 20)
                    .frame(maxHeight: .infinity)
                    .foregroundColor(ColorMap().getColor(color: participantsVM.teams[teamIndex].color))
                Text("\(participantsVM.teams[teamIndex].score)")
                    .font(formatter.font(fontSize: .semiLarge))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(formatter.color(.primaryFG))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 75)
            .cornerRadius(10)
        }
        .padding(20)
        .background(formatter.color(.primaryAccent))
        .cornerRadius(10)
    }
}

