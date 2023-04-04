//
//  CategoryPreviewView.swift
//  Trivio!
//
//  Created by David Chen on 12/8/22.
//

import Foundation
import SwiftUI

struct CategoryPreviewView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    let categories: [String]
    
    var body: some View {
        HStack (spacing: exploreVM.homepageIsDisplaying == .setPreview ? 7 : 10) {
            ForEach(categories, id: \.self) { category in
                CategoryPreviewCellView(categoryName: category)
                    .id(UUID().uuidString)
            }
        }
        .frame(height: exploreVM.homepageIsDisplaying == .setPreview ? 100 : 120)
    }
}

struct CategoryPreviewCellView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    let categoryName: String
    
    var body: some View {
        ZStack {
            Text(categoryName.uppercased())
                .font(formatter.font(fontSize: (exploreVM.homepageIsDisplaying == .setPreview) ? .small : .regular))
                .foregroundColor(formatter.color(.highContrastWhite))
                .multilineTextAlignment(.center)
                .padding(14)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: 280, maxHeight: .infinity)
        .background(formatter.color(.secondaryFG))
        .cornerRadius(exploreVM.homepageIsDisplaying == .setPreview ? 7 : 10)
    }
}

