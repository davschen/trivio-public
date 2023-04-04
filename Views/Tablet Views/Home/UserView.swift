//
//  UserView.swift
//  Trivio!
//
//  Created by David Chen on 12/7/22.
//

import Foundation
import SwiftUI

struct UserView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack (spacing: 10) {
                VStack (alignment: .leading, spacing: 5) {
                    Text("\(exploreVM.selectedUserName)")
                        .font(formatter.font(.bold, fontSize: .large))
                        .foregroundColor(formatter.color(.highContrastWhite))
                    Text("@\(exploreVM.selectedUserUsername)")
                        .font(formatter.font(.regular, fontSize: .medium))
                        .foregroundColor(formatter.color(.highContrastWhite))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 25)
                
                VStack (alignment: .leading, spacing: 3) {
                    ForEach(exploreVM.userResults, id: \.self) { customSet in
                        if profileVM.myUserRecords.isAdmin || customSet.isPublic {
                            UserCustomSetCellView(customSet: customSet)
                        }
                    }
                    if profileVM.myUserRecords.isAdmin {
                        Text("\(exploreVM.selectedUserName)'s Drafts")
                            .padding([.top, .horizontal])
                            .opacity(exploreVM.userDrafts.count > 0 ? 1 : 0)
                        ForEach(exploreVM.userDrafts, id: \.self) { draft in
                            UserCustomSetCellView(customSet: draft)
                                .disabled(true)
                        }
                    }
                }
            }
            .padding(.bottom, 25)
        }
        .withBackButton()
        .withBackground()
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct UserCustomSetCellView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel

    @State var setPreviewActive = false
    
    var customSet: CustomSetCherry
    var setID: String {
        return customSet.id ?? "NID"
    }
    
    var body: some View {
        ZStack {
            VStack (alignment: .leading, spacing: 10) {
                HStack (spacing: 2) {
                    if !customSet.isPublic {
                        Image(systemName: "lock.fill")
                            .font(formatter.iconFont(.small))
                            .offset(x: -2, y: -1)
                    }
                    Text(customSet.title)
                        .font(formatter.font(fontSize: .mediumLarge))
                    Spacer(minLength: 0)
                }
                if !customSet.description.isEmpty {
                    Text(customSet.description)
                        .font(formatter.font(.regular))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                        .lineSpacing(3)
                }
                Text("Tags: \(customSet.tags.map{String($0).lowercased()}.joined(separator: ", "))")
                    .font(formatter.font(.regular))
                    .foregroundColor(formatter.color(.lowContrastWhite))
                HStack {
                    Text("\(customSet.hasTwoRounds ? "2 rounds" : "1 round"), \(customSet.numClues) clues")
                    Circle()
                        .frame(width: 5, height: 5)
                    Text("\(customSet.plays) play" + "\(customSet.plays == 1 ? "" : "s")")
                    Circle()
                        .frame(width: 5, height: 5)
                    Text("\(gamesVM.dateFormatter.string(from: customSet.dateCreated))")
                }
                .font(formatter.font(.regular))
                .foregroundColor(formatter.color(.lowContrastWhite))
            }
            .padding(.horizontal, 15).padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(formatter.color(exploreVM.recentlyPlayedSets.contains(customSet) ? .primaryFG : .secondaryFG))
            
            NavigationLink(destination: GamePreviewView()
                .navigationBarTitle("Set Preview", displayMode: .inline),
                           isActive: $setPreviewActive,
                           label: { EmptyView() }).hidden()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectSet(customSet: customSet)
            setPreviewActive.toggle()
        }
    }
    
    func selectSet(customSet: CustomSetCherry) {
        formatter.hapticFeedback(style: .light)
        exploreVM.shortenPublicSetsTo(10, customSet: customSet)
        gamesVM.reset()
        gamesVM.getCustomData(setID: setID)
        participantsVM.resetScores()
    }
}

struct UserDraftCellView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel

    @State var setPreviewActive = false
    
    var customSet: CustomSetCherry
    var setID: String {
        return customSet.id ?? "NID"
    }
    
    var body: some View {
        ZStack {
            VStack (alignment: .leading, spacing: 10) {
                HStack (spacing: 2) {
                    if !customSet.isPublic {
                        Image(systemName: "lock.fill")
                            .font(formatter.iconFont(.small))
                            .offset(x: -2, y: -1)
                    }
                    Text(customSet.title)
                        .font(formatter.font(fontSize: .mediumLarge))
                    Spacer(minLength: 0)
                }
                if !customSet.description.isEmpty {
                    Text(customSet.description)
                        .font(formatter.font(.regular))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                }
                HStack {
                    Text("\(customSet.hasTwoRounds ? "2 rounds" : "1 round"), \(customSet.numClues) clues")
                    Circle()
                        .frame(width: 5, height: 5)
                    Text("\(customSet.plays) play" + "\(customSet.plays == 1 ? "" : "s")")
                    Circle()
                        .frame(width: 5, height: 5)
                    Text("\(gamesVM.dateFormatter.string(from: customSet.dateCreated))")
                }
                .font(formatter.font(.regular))
                .foregroundColor(formatter.color(.lowContrastWhite))
            }
            .padding(.horizontal, 15).padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(formatter.color(.primaryFG))
            
            NavigationLink(destination: GamePreviewView()
                .navigationBarTitle("Set Preview", displayMode: .inline),
                           isActive: $setPreviewActive,
                           label: { EmptyView() }).hidden()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectSet(customSet: customSet)
            setPreviewActive.toggle()
        }
    }
    
    func selectSet(customSet: CustomSetCherry) {
        formatter.hapticFeedback(style: .light)
        gamesVM.reset()
        gamesVM.getCustomData(setID: setID)
        participantsVM.resetScores()
    }
}

