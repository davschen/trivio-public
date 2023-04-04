//
//  MobileMySetsView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI

struct MobileCustomSetsView: View {
    @Binding var customSets: [CustomSetCherry]
    
    var emptyLabelString: String = "No sets yet! When you make a set, it’ll show up here."
    
    var body: some View {
        VStack (alignment: .leading, spacing: 5) {
            if customSets.count > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 15)
                        ForEach(customSets, id: \.self) { customSet in
                            MobileCustomSetCellView(customSet: customSet)
                        }
                        Spacer(minLength: 15)
                    }
                }
            } else {
                MobileEmptyListView(label: emptyLabelString)
                    .padding(.horizontal)
            }
        }
        .keyboardAware()
    }
}

struct MobileCustomSetCellView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var setPreviewActive = false
    @State var userViewActive = false
    
    var isInUserView = false
    var customSet: CustomSetCherry
    var setID: String {
        return customSet.id ?? "NID"
    }
    var played: Bool {
        return profileVM.beenPlayed(gameID: setID)
    }
    var selected: Bool {
        return gamesVM.customSet.id == setID
    }
    
    var body: some View {
        ZStack {
            VStack (alignment: .leading, spacing: 7) {
                HStack (spacing: 2) {
                    if !customSet.isPublic {
                        Image(systemName: "lock.fill")
                            .font(formatter.iconFont(.small))
                            .offset(x: -2, y: -1)
                    }
                    Text(customSet.title)
                        .font(formatter.font(fontSize: .mediumLarge))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                Text("\(customSet.hasTwoRounds ? "2 rounds" : "1 round"), \(customSet.numClues) clues")
                    .font(formatter.font(.regular))
                Text("Tags: \(customSet.tags.map{String($0).lowercased()}.joined(separator: ", "))")
                    .font(formatter.font(.regular))
                    .foregroundColor(formatter.color(.mediumContrastWhite))
                    .lineLimit(1)
                Text("\(customSet.description)")
                    .font(formatter.font(.regular))
                    .foregroundColor(formatter.color(customSet.description.isEmpty ? .secondaryFG : .lowContrastWhite))
                    .lineLimit(1)
                    .frame(height: 20)
                    .padding(.bottom, 5)
                HStack (spacing: 8) {
                    ZStack {
                        Button {
                            exploreVM.pullAllFromUser(withID: customSet.userID)
                            userViewActive.toggle()
                        } label: {
                            Text("\(exploreVM.getInitialsFromUserID(userID: customSet.userID))")
                                .font(formatter.font(.boldItalic, fontSize: .small))
                                .frame(width: 40, height: 40)
                                .background(formatter.color(.primaryAccent))
                                .clipShape(Circle())
                        }

                        NavigationLink(destination: MobileUserView()
                            .navigationBarTitle("Profile", displayMode: .inline),
                                       isActive: $userViewActive,
                                       label: { EmptyView() }).hidden()
                    }
                    VStack (alignment: .leading, spacing: 5) {
                        Text("\(exploreVM.getUsernameFromUserID(userID: customSet.userID))")
                            .font(formatter.font(.regular))
                            .lineLimit(1)
                        HStack {
                            Text("\(customSet.plays) \(customSet.plays == 1 ? "play" : "plays")")
                            Circle()
                                .frame(width: 5, height: 5)
                            Text("\(gamesVM.dateFormatter.string(from: customSet.dateCreated))")
                        }
                        .font(formatter.font(.regular))
                        .foregroundColor(formatter.color(.lowContrastWhite))
                    }
                }
            }
            
            NavigationLink(destination: MobileGamePreviewView(),
                           isActive: $setPreviewActive,
                           label: { EmptyView() }).hidden()
        }
        .padding()
        .frame(width: 280, alignment: .leading)
        .background(formatter.color(.secondaryFG))
        .cornerRadius(10)
        .contentShape(Rectangle())
        .onTapGesture {
            selectSet(customSet: customSet)
            setPreviewActive.toggle()
        }
    }
    
    func selectSet(customSet: CustomSetCherry) {
        formatter.hapticFeedback(style: .light)
        guard let setID = customSet.id else { return }
        gamesVM.reset()
        gamesVM.getCustomData(setID: setID)
        participantsVM.resetScores()
    }
}
