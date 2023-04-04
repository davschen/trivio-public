//
//  MobileProfileView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI

struct MobileProfileView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @State var isShowingMyCustomSetsView = true
    @State var isShowingDraftsView = true
    
    var body: some View {
        ScrollView (showsIndicators: false) {
            VStack (alignment: .leading, spacing: 15) {
                MobileAccountInfoView()
                Spacer(minLength: 10)
                VStack (spacing: 20) {
                    VStack (alignment: .leading, spacing: 10) {
                        HStack {
                            Text("My sets")
                            Spacer()
                            Button {
                                isShowingMyCustomSetsView.toggle()
                            } label: {
                                Text(isShowingMyCustomSetsView ? "Hide" : "Show")
                                    .foregroundColor(formatter.color(.secondaryAccent))
                            }
                        }
                        .padding(.horizontal)
                        if isShowingMyCustomSetsView {
                            MobileMyCustomSetsView(customSets: $gamesVM.customSets)
                        }
                    }
                    VStack (alignment: .leading, spacing: 10) {
                        HStack {
                            Text("My drafts")
                            Spacer()
                            Button {
                                isShowingDraftsView.toggle()
                            } label: {
                                Text(isShowingDraftsView ? "Hide" : "Show")
                                    .foregroundColor(formatter.color(.secondaryAccent))
                            }
                        }
                        .padding(.horizontal)
                        if isShowingDraftsView {
                            MobileMyDraftsView()
                        }
                    }
                }
            }
            .padding(.vertical)
            .padding(.bottom, 25)
        }
        .withBackground()
        .withBackButton()
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct MobileAccountInfoView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    var body: some View {
        Button {
            formatter.hapticFeedback(style: .heavy, intensity: .weak)
            profileVM.showingSettingsView.toggle()
            profileVM.settingsMenuSelectedItem = "Account"
        } label: {
            ZStack {
                HStack (spacing: 5) {
                    Text("\(exploreVM.getInitialsFromUserID(userID: profileVM.myUID ?? ""))")
                        .font(formatter.font(.boldItalic, fontSize: .regular))
                        .frame(width: 45, height: 45)
                        .background(formatter.color(.primaryAccent))
                        .clipShape(Circle())
                        .overlay(
                                Circle()
                                    .stroke(formatter.color(.highContrastWhite), lineWidth: 3)
                            )
                    VStack (alignment: .leading, spacing: 5) {
                        Text("\(profileVM.name)")
                            .font(formatter.font(.bold, fontSize: .mediumLarge))
                            .foregroundColor(formatter.color(.highContrastWhite))
                        Text("@\(profileVM.username)")
                            .font(formatter.font(.regular, fontSize: .medium))
                            .foregroundColor(formatter.color(.highContrastWhite))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                    
                    Spacer(minLength: 0)
                    
                    Image(systemName: "chevron.right")
                        .font(formatter.iconFont(.small))
                }
                .padding(.horizontal)
                
                NavigationLink(destination: MobileAccountSettingsView(),
                               isActive: $profileVM.showingSettingsView,
                               label: { EmptyView() }).hidden()
            }
        }
    }
}

struct MobileProfileBottomButtonsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    var body: some View {
        VStack (spacing: 10) {
            Button(action: {
                formatter.hapticFeedback(style: .light)
                buildVM.start()
            }, label: {
                HStack {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Build a Set")
                        .font(formatter.font())
                }
                .foregroundColor(formatter.color(.highContrastWhite))
                .padding()
                .frame(maxWidth: .infinity)
                .background(formatter.color(.secondaryAccent))
                .cornerRadius(5)
            })
            
            Button(action: {
                formatter.hapticFeedback(style: .light)
                profileVM.showingSettingsView.toggle()
            }, label: {
                HStack {
                    Image(systemName: "gear")
                        .font(.system(size: 15, weight: .bold))
                    Text("Settings")
                        .font(formatter.font())
                }
                .foregroundColor(formatter.color(.highContrastWhite))
                .padding()
                .frame(maxWidth: .infinity)
                .background(formatter.color(.secondaryFG))
                .cornerRadius(5)
            })
        }
    }
}

struct MobileEmptyListView: View {
    @EnvironmentObject var formatter: MasterHandler
    var label: String
    
    var body: some View {
        VStack {
            Text(label)
                .font(formatter.font(.boldItalic))
                .foregroundColor(formatter.color(.lowContrastWhite))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 145)
        .padding()
        .background(formatter.color(.primaryFG))
        .cornerRadius(10)
    }
}

