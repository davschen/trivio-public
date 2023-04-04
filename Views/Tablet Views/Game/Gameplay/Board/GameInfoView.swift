//
//  GameInfoView.swift
//  Trivio!
//
//  Created by David Chen on 12/7/22.
//

import Foundation
import SwiftUI

struct GameInfoView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @Binding var showInfoView: Bool
    
    var customSet: CustomSetCherry {
        return gamesVM.customSet
    }
    
    var isCustom: Bool {
        return !gamesVM.queriedUserName.isEmpty
    }
    
    var body: some View {
        ZStack (alignment: .bottom) {
            formatter.color(.primaryBG)
                .edgesIgnoringSafeArea(.all)
                .opacity(showInfoView ? 0.9 : 0)
                .onTapGesture {
                    formatter.hapticFeedback(style: .soft)
                    showInfoView.toggle()
                }
            VStack (alignment: .leading, spacing: 0) {
                ZStack {
                    Button {
                        formatter.hapticFeedback(style: .soft, intensity: .strong)
                        showInfoView.toggle()
                    } label: {
                        Text("Cancel")
                            .font(formatter.font(fontSize: .small))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("Game Info")
                        .font(formatter.font(fontSize: .mediumLarge))
                }
                .padding(.vertical, 20)
                .padding(.horizontal)
                .background(formatter.color(.secondaryFG))
                ScrollView (.vertical, showsIndicators: false) {
                    VStack (alignment: .leading, spacing: 7) {
                        Text("\(gamesVM.customSet.title)")
                            .font(formatter.font(fontSize: .semiLarge))
                        Text("Created by \(exploreVM.getUsernameFromUserID(userID: gamesVM.customSet.userID)) on \(gamesVM.dateFormatter.string(from: isCustom ? customSet.dateCreated : Date()))")
                            .font(formatter.font(.regular))
                        if !gamesVM.customSet.description.isEmpty {
                            Text(gamesVM.customSet.description)
                                .foregroundColor(formatter.color(.lowContrastWhite))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(formatter.font(.regular))
                        }
                        GameSettingsCardView()
                            .padding(.top)
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxHeight: 400)
            .background(formatter.color(.primaryFG))
            .cornerRadius(10)
            .offset(y: showInfoView ? 0 : UIScreen.main.bounds.height)
            .padding(.horizontal)
        }
    }
}
