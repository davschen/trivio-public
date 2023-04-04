//
//  MobileCategoryPreviewView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI

struct MobileCategoryPreviewView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    let categories: [String]
    
    var body: some View {
        ScrollView (.horizontal, showsIndicators: false) {
            HStack (spacing: 7) {
                ForEach(categories.indices, id: \.self) { categoryIndex in
                    MobileCategoryPreviewCellView(categoryName: categories[categoryIndex])
                        .id(UUID().uuidString)
                }
            }
            .frame(height: 80)
            .padding([.leading, .trailing])
        }
    }
}

struct MobileCategoryPreviewCellView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    let categoryName: String
    
    var body: some View {
        ZStack {
            Text(categoryName.uppercased())
                .font(formatter.font(fontSize: .regular))
                .foregroundColor(formatter.color(.highContrastWhite))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
                .minimumScaleFactor(0.1)
                .padding(2)
        }
        .frame(maxHeight: .infinity)
        .frame(width: 130)
        .background(formatter.color(.secondaryFG))
        .cornerRadius(5)
    }
}

