//
//  JeopardySetsView.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 1/20/23.
//

import Foundation
import SwiftUI

struct JeopardySetsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @Binding var jeopardySeasonsViewActive: Bool
    
    var body: some View {
        VStack (alignment: .leading, spacing: 5) {
            HStack {
                Text("Jeopardy! Sets")
                Spacer()
                Button {
                    jeopardySeasonsViewActive.toggle()
                } label: {
                    Text("All Seasons")
                        .foregroundColor(formatter.color(.secondaryAccent))
                }
            }
            .padding(.horizontal, 15)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Spacer(minLength: 15)
                    ForEach(gamesVM.gamePreviews, id: \.self) { jeopardySetPreview in
                        JeopardySetCellView(jeopardySetPreview: jeopardySetPreview)
                    }
                    Spacer(minLength: 15)
                }
            }
        }
        .keyboardAware()
    }
}

struct JeopardySetCellView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var setPreviewActive = false
    @State var userViewActive = false
    
    var isInUserView = false
    var jeopardySetPreview: JeopardySetPreview
    var setID: String {
        return jeopardySetPreview.id ?? "NID"
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
                    Text(jeopardySetPreview.title)
                        .font(formatter.font(fontSize: .mediumLarge))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 20)
                Text(jeopardySetPreview.contestants)
                    .font(formatter.font(.regular))
                    .foregroundColor(formatter.color(.lowContrastWhite))
                    .lineLimit(2)
            }
            
            NavigationLink(destination: GamePreviewView()
                .navigationBarTitle("Set Preview", displayMode: .inline),
                           isActive: $setPreviewActive,
                           label: { EmptyView() }).hidden()
        }
        .padding(.horizontal, 15).padding(.vertical, 20)
        .frame(width: 280, alignment: .leading)
        .background(formatter.color(.secondaryFG))
        .cornerRadius(10)
        .contentShape(Rectangle())
        .onTapGesture {
            selectSet(jeopardySetPreview: jeopardySetPreview)
            setPreviewActive.toggle()
        }
    }
    
    func selectSet(jeopardySetPreview: JeopardySetPreview) {
        formatter.hapticFeedback(style: .light)
        guard let gameID = jeopardySetPreview.id else { return }
        gamesVM.reset()
        gamesVM.getEpisodeData(gameID: gameID)
        participantsVM.resetScores()
    }
}
