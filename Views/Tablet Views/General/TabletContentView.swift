//
//  HomePageView.swift
//  Trivio!
//
//  Created by David Chen on 5/24/21.
//

import Foundation
import SwiftUI

struct TabletContentView: View {
    @ObservedObject var formatter = MasterHandler()
    @ObservedObject var buildVM = BuildViewModel()
    @ObservedObject var exploreVM = ExploreViewModel()
    @ObservedObject var gamesVM = GamesViewModel()
    @ObservedObject var participantsVM = ParticipantsViewModel()
    @ObservedObject var profileVM = ProfileViewModel()
    @ObservedObject var reportVM = ReportViewModel()
    @ObservedObject var searchVM = SearchViewModel()
    
    var body: some View {
        VStack (spacing: 0) {
            ZStack (alignment: .bottomLeading) {
                formatter.color(.primaryBG)
                    .edgesIgnoringSafeArea(.all)
                HomepageView()
                    .environmentObject(formatter)
                    .environmentObject(buildVM)
                    .environmentObject(exploreVM)
                    .environmentObject(gamesVM)
                    .environmentObject(participantsVM)
                    .environmentObject(profileVM)
                    .environmentObject(reportVM)
                    .environmentObject(searchVM)
                AlertView(alertStyle: .standard, titleText: formatter.alertTitle, subtitleText: formatter.alertSubtitle, hasCancel: formatter.hasCancel, actionLabel: formatter.actionLabel, action: {
                    formatter.alertAction()
                }, hasSecondaryAction: formatter.hasSecondaryAction, secondaryAction: {
                    formatter.secondaryAction()
                }, secondaryActionLabel: formatter.secondaryActionLabel)
                .environmentObject(formatter)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}
