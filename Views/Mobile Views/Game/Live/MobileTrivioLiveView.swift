//
//  MobileTrivioLiveView.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 4/2/23.
//

import Foundation
import SwiftUI

struct MobileTrivioLiveView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    var body: some View {
        ZStack {
            formatter.color(.primaryBG)
                .edgesIgnoringSafeArea(.all)
            HStack (spacing: 20) {
                // Variable game display
                ZStack {
                    if let display = LiveGameDisplay(from: gamesVM.liveGameCustomSet.currentGameDisplay) {
                        switch display {
                        case .preWVC:
                            MobileLiveDuplexWagerView()
                        case .clue, .response:
                            MobileLiveClueView()
                        default:
                            // Display is set to board by default
                            MobileLiveGameBoardView()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                MobileLiveGameSideRailView()
            }
            .padding(.top)
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
    }
}

enum LiveGameDisplay {
    case board, clue, response, preWVC, preFinalClue, finalClue, finalResponse, finalStats
    
    init?(from string: String) {
        switch string {
        case "board":
            self = .board
        case "clue":
            self = .clue
        case "response":
            self = .response
        case "preWVC":
            self = .preWVC
        case "preFinalClue":
            self = .preFinalClue
        case "finalClue":
            self = .finalClue
        case "finalResponse":
            self = .finalResponse
        case "finalStats":
            self = .finalStats
        default:
            return nil
        }
    }
}
