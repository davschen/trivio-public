//
//  MobileHomePageView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI

struct MobileContentView: View {
    @ObservedObject var formatter = MasterHandler()
    @ObservedObject var buildVM = BuildViewModel()
    @ObservedObject var exploreVM = ExploreViewModel()
    @ObservedObject var gamesVM = GamesViewModel()
    @ObservedObject var participantsVM = ParticipantsViewModel()
    @ObservedObject var profileVM = ProfileViewModel()
    @ObservedObject var reportVM = ReportViewModel()
    @ObservedObject var searchVM = SearchViewModel()
    @ObservedObject var appStoreManager = AppStoreManager()
    
    var body: some View {
        VStack (spacing: 0) {
            ZStack (alignment: .bottomLeading) {
                formatter.color(.primaryBG)
                    .edgesIgnoringSafeArea(.all)
                MobileHomepageView()
                    .environmentObject(formatter)
                    .environmentObject(buildVM)
                    .environmentObject(exploreVM)
                    .environmentObject(gamesVM)
                    .environmentObject(participantsVM)
                    .environmentObject(profileVM)
                    .environmentObject(reportVM)
                    .environmentObject(searchVM)
                    .environmentObject(appStoreManager)
                MobileAlertView(alertType: formatter.alertType, alertStyle: .standard, titleText: formatter.alertTitle, subtitleText: formatter.alertSubtitle, hasCancel: formatter.hasCancel, actionLabel: formatter.actionLabel, action: {
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
