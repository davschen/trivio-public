//
//  CustomSetsView.swift
//  Trivio!
//
//  Created by David Chen on 12/8/22.
//

import Foundation
import SwiftUI

struct CustomSetsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    
    @Binding var customSets: [CustomSetCherry]
    
    @State var showSortByMenu = false
    
    var emptyLabelString: String = "No sets yet! When you make a set, it’ll show up here."
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            VStack (alignment: .leading, spacing: 5) {
                if exploreVM.homepageIsDisplaying == .publicSets {
                    Button {
                        showSortByMenu.toggle()
                    } label: {
                        HStack (spacing: 5) {
                            Text(exploreVM.getCurrentSort())
                                .font(formatter.font(.regular))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .rotationEffect(Angle(degrees: showSortByMenu ? 180 : 0))
                        }
                    }
                }
                
                if customSets.count > 0 {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(customSets, id: \.self) { customSet in
                                CustomSetCellView(customSet: customSet)
                            }
                        }
                    }
                } else {
                    EmptyListView(label: emptyLabelString)
                        .padding(.horizontal)
                }
            }
            if showSortByMenu {
                ZStack (alignment: .topLeading) {
                    formatter.color(.primaryBG)
                        .edgesIgnoringSafeArea(.all)
                        .opacity(0.8)
                        .transition(.opacity)
                    VStack (alignment: .leading, spacing: 0) {
                        FilterByView(showSortByMenu: $showSortByMenu, sortByOption: "Date created (newest)", isSortingPublicSets: true)
                        FilterByView(showSortByMenu: $showSortByMenu, sortByOption: "Date created (oldest)", isSortingPublicSets: true)
                        FilterByView(showSortByMenu: $showSortByMenu, sortByOption: "Most plays", isSortingPublicSets: true)
                    }
                    .transition(.move(edge: .top))
                    .padding(.vertical, 5)
                    .frame(width: 300)
                    .background(formatter.color(.secondaryFG))
                    .cornerRadius(5)
                    .offset(y: 25)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
                .onTapGesture {
                    showSortByMenu.toggle()
                }
            }
        }
    }
}

struct CustomSetCellView: View {
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
            VStack (alignment: .leading, spacing: 10) {
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
                    .padding(.bottom, 10)
                HStack (spacing: 8) {
                    ZStack {
                        Button {
                            exploreVM.pullAllFromUser(withID: customSet.userID)
                            userViewActive.toggle()
                        } label: {
                            Text("\(exploreVM.getInitialsFromUserID(userID: customSet.userID))")
                                .font(formatter.font(.boldItalic, fontSize: .small))
                                .frame(width: 50, height: 50)
                                .background(formatter.color(.primaryAccent))
                                .clipShape(Circle())
                        }

                        NavigationLink(destination: UserView()
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
                                .lineLimit(1)                            
                        }
                        .font(formatter.font(.regular))
                        .foregroundColor(formatter.color(.lowContrastWhite))
                    }
                }
            }
            
            NavigationLink(destination: GamePreviewView()
                .navigationBarTitle("Set Preview", displayMode: .inline),
                           isActive: $setPreviewActive,
                           label: { EmptyView() }).hidden()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        exploreVM.shortenPublicSetsTo(10, customSet: customSet)
        gamesVM.reset()
        gamesVM.getCustomData(setID: setID)
        participantsVM.resetScores()
    }
}
