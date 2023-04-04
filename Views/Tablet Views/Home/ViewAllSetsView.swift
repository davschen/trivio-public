//
//  ViewAllSetsView.swift
//  Trivio!
//
//  Created by David Chen on 12/7/22.
//

import Foundation
import SwiftUI

struct ViewAllPublicSetsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    
    @State var showSortByMenu = false
    
    var body: some View {
        ZStack {
            VStack (alignment: .leading) {
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
                    .padding(.horizontal)
                }
                ScrollView(.vertical, showsIndicators: true) {
                    VStack (alignment: .leading, spacing: 3) {
                        ForEach(exploreVM.allPublicSets, id: \.self) { customSet in
                            UserCustomSetCellView(customSet: customSet)
                        }
                    }
                    Button {
                        exploreVM.pullAllPublicSets()
                    } label: {
                        Text("Load more")
                    }
                    .padding(.bottom, 45)
                    .padding()
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
                    .frame(width: 210)
                    .background(formatter.color(.secondaryFG))
                    .cornerRadius(5)
                    .offset(x: 15, y: 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
                .onTapGesture {
                    showSortByMenu.toggle()
                }
            }
        }
        .padding(.top, 25)
        .withBackButton()
        .withBackground()
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct FilterByView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    
    @Binding var showSortByMenu: Bool
    
    var sortByOption: String
    var isSortingPublicSets: Bool
    
    var body: some View {
        HStack {
            Text(sortByOption)
        }
        .font(formatter.font(.regular))
        .foregroundColor(formatter.color(.highContrastWhite))
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading)
        .background(formatter.color(exploreVM.getCurrentSort() == sortByOption ? .primaryBG : .secondaryFG))
        .onTapGesture {
            exploreVM.applyCurrentSort(sortByOption: sortByOption, isSortingPublicSets: isSortingPublicSets)
            showSortByMenu.toggle()
        }
    }
}

struct ViewAllRecentSetsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack (alignment: .leading, spacing: 3) {
                ForEach(exploreVM.recentlyPlayedSets, id: \.self) { customSet in
                    UserCustomSetCellView(customSet: customSet)
                }
            }
            .padding(.vertical, 25)
        }
        .withBackButton()
        .withBackground()
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct ViewAllPrivateSetsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    
    @State var showSortByMenu = false
    
    var body: some View {
        ZStack {
            VStack (alignment: .leading) {
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
                    .padding(.horizontal)
                }
                ScrollView(.vertical, showsIndicators: true) {
                    VStack (alignment: .leading, spacing: 3) {
                        ForEach(exploreVM.allPrivateSets, id: \.self) { customSet in
                            UserCustomSetCellView(customSet: customSet)
                        }
                    }
                    Button {
                        exploreVM.pullAllPrivateSets()
                    } label: {
                        Text("Load more")
                    }
                    .padding(.bottom, 45)
                    .padding()
                }
            }
            if showSortByMenu {
                ZStack (alignment: .topLeading) {
                    formatter.color(.primaryBG)
                        .edgesIgnoringSafeArea(.all)
                        .opacity(0.8)
                        .transition(.opacity)
                    VStack (alignment: .leading, spacing: 0) {
                        MobileFilterByView(showSortByMenu: $showSortByMenu, sortByOption: "Date created (newest)", isSortingPublicSets: false)
                        MobileFilterByView(showSortByMenu: $showSortByMenu, sortByOption: "Date created (oldest)", isSortingPublicSets: false)
                        MobileFilterByView(showSortByMenu: $showSortByMenu, sortByOption: "Most plays", isSortingPublicSets: false)
                    }
                    .transition(.move(edge: .top))
                    .padding(.vertical, 5)
                    .frame(width: 210)
                    .background(formatter.color(.secondaryFG))
                    .cornerRadius(5)
                    .offset(x: 15, y: 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
                .onTapGesture {
                    showSortByMenu.toggle()
                }
            }
        }
        .padding(.top, 25)
        .withBackButton()
        .withBackground()
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarTitle("\(exploreVM.allPrivateSets.count) Private Sets", displayMode: .inline)
    }
}
