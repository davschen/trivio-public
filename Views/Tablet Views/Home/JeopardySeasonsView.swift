//
//  JeopardySeasonsView.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 1/20/23.
//

import Foundation
import SwiftUI

struct JeopardySeasonsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @State var episodesViewActive = false
    @State var selectedSeason: JeopardySeason = JeopardySeason()
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack (spacing: 10) {
                    Spacer(minLength: 20)
                    VStack (alignment: .leading, spacing: 3) {
                        ForEach(gamesVM.jeopardySeasons, id: \.self) { season in
                            HStack {
                                Text("\(season.title)")
                                    .font(formatter.font(fontSize: .mediumLarge))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding(.horizontal)
                            .frame(height: 80)
                            .background(formatter.color(.primaryFG))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard let seasonID = season.id else { return }
                                gamesVM.getEpisodes(seasonID: seasonID, purge: true)
                                self.selectedSeason = season
                                episodesViewActive.toggle()
                            }
                        }
                    }
                }
                .padding(.bottom, 25)
            }
            .withBackButton()
            .withBackground()
            .edgesIgnoringSafeArea(.bottom)
            
            NavigationLink(destination: JeopardySeasonEpisodesView(selectedSeason: selectedSeason),
                           isActive: $episodesViewActive,
                           label: { EmptyView() }).isDetailLink(false).hidden()
        }
    }
}

struct JeopardySeasonEpisodesView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @State var setPreviewActive = false
    
    let selectedSeason: JeopardySeason
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack (spacing: 10) {
                    Spacer(minLength: 20)
                    VStack (alignment: .leading, spacing: 3) {
                        ForEach(gamesVM.gamePreviews, id: \.self) { preview in
                            HStack {
                                VStack (alignment: .leading, spacing: 10) {
                                    Text("\(preview.title)")
                                    Text("\(preview.contestants)")
                                        .font(formatter.font(.regular))
                                        .foregroundColor(formatter.color(.lowContrastWhite))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding(.horizontal)
                            .frame(height: 100)
                            .background(formatter.color(.primaryFG))
                            .contentShape(Rectangle())
                            .transaction { transaction in
                                transaction.animation = nil
                            }
                            .onTapGesture {
                                selectSet(jeopardySetPreview: preview)
                                setPreviewActive.toggle()
                            }
                        }
                        Button {
                            gamesVM.getEpisodes(seasonID: selectedSeason.id)
                        } label: {
                            Text("Load more")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .transaction { transaction in
                                    transaction.animation = nil
                                }
                        }
                        .padding(.bottom, 45)
                        .padding()
                    }
                }
                .padding(.bottom, 25)
            }
            .withBackButton()
            .withBackground()
            .edgesIgnoringSafeArea(.bottom)
            
            NavigationLink(destination: GamePreviewView()
                .navigationBarTitle("Set Preview", displayMode: .inline),
                           isActive: $setPreviewActive,
                           label: { EmptyView() }).hidden()
        }
        .navigationBarTitle("\(selectedSeason.title)", displayMode: .inline)
    }
    
    func selectSet(jeopardySetPreview: JeopardySetPreview) {
        formatter.hapticFeedback(style: .light)
        guard let gameID = jeopardySetPreview.id else { return }
        gamesVM.reset()
        gamesVM.getEpisodeData(gameID: gameID)
        participantsVM.resetScores()
    }
}
