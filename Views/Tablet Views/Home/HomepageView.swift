//
//  HomepageView.swift
//  Trivio!
//
//  Created by David Chen on 12/7/22.
//

import Foundation
import SwiftUI
import StoreKit

struct HomepageView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var appStoreManager: AppStoreManager
    
    @EnvironmentObject var buildVM: BuildViewModel
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @State var profileViewActive = false
    @State var allPublicSetsViewActive = false
    @State var allPrivateSetsViewActive = false
    @State var allRecentSetsViewActive = false
    @State var jeopardySeasonsViewActive = false
    
    var body: some View {
        NavigationView() {
            ZStack (alignment: .top) {
                // VStack for Trivio! Header
                VStack {
                    HomepageHeaderView()
                    HStack (spacing: 25) {
                        VStack (alignment: .leading, spacing: 0) {
                            VStack (alignment: .leading, spacing: 30) {
                                Text("Public sets")
                                    .foregroundColor(formatter.color(exploreVM.homepageIsDisplaying == .publicSets ? .highContrastWhite : .lowContrastWhite))
                                    .onTapGesture {
                                        exploreVM.homepageIsDisplaying = .publicSets
                                    }
                                Text("Jeopardy sets")
                                    .foregroundColor(formatter.color(.lowContrastWhite))
                                    .onTapGesture {
                                        jeopardySeasonsViewActive.toggle()
                                    }
                                Rectangle()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 1)
                                    .foregroundColor(formatter.color(.lowContrastWhite))
                            }
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack (alignment: .leading, spacing: 30) {
                                    if gamesVM.customSets.count > 0 {
                                        ForEach(gamesVM.customSets) { customSet in
                                            HomepageMySetSelectorView(customSet: customSet)
                                        }
                                    } else {
                                        Text("You haven't created any sets yet. Once you do, they'll show up here. Build a set by tapping the button below.")
                                            .font(formatter.font(.regularItalic, fontSize: .medium))
                                    }
                                }
                                .padding(.vertical, 30)
                            }
                            ExploreBuildPromptButtonView()
                        }
                        .font(formatter.font(.regular, fontSize: .medium))
                        .foregroundColor(formatter.color(.lowContrastWhite))
                        .padding([.vertical, .leading], 25)
                        .frame(maxWidth: 350, alignment: .leading)
                        ScrollView(.vertical, showsIndicators: false) {
                            switch exploreVM.homepageIsDisplaying {
                            case .recentlyPlayed:
                                VStack (alignment: .leading, spacing: 25) {
                                    Text("Recently played")
                                        .font(formatter.font(fontSize: .large))
                                    CustomSetsView(customSets: $exploreVM.recentlyPlayedSets)
                                        .id(exploreVM.homepageIsDisplaying)
                                }
                                .padding(.trailing)
                                .padding(.bottom, 100)
                                .frame(maxWidth: .infinity)
                            case .setPreview:
                                GamePreviewView()
                            default:
                                VStack (alignment: .leading, spacing: 25) {
                                    Text("Public sets")
                                        .font(formatter.font(fontSize: .large))
                                    CustomSetsView(customSets: $exploreVM.allPublicSets)
                                    Button {
                                        exploreVM.pullAllPublicSets()
                                    } label: {
                                        Text("Load more")
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(.trailing, 25)
                                .padding(.bottom, 100)
                                .frame(maxWidth: .infinity)
                            }
                            
                        }
                    }
                }
                if buildVM.dirtyBit > 0 && !buildVM.currCustomSet.title.isEmpty {
                    GeometryReader { reader in
                        formatter.color(.primaryFG)
                            .frame(height: reader.safeAreaInsets.top, alignment: .top)
                            .ignoresSafeArea()
                    }
                }
                NavigationLink(destination: ProfileView()
                    .navigationBarTitle("Profile", displayMode: .inline),
                               isActive: $profileViewActive,
                               label: { EmptyView() }).isDetailLink(false).hidden()
                NavigationLink(destination: ViewAllPublicSetsView()
                    .navigationBarTitle("All Public Sets", displayMode: .inline),
                               isActive: $allPublicSetsViewActive,
                               label: { EmptyView() }).isDetailLink(false).hidden()
                NavigationLink(destination: JeopardySeasonsView()
                    .navigationBarTitle("All Seasons", displayMode: .inline),
                               isActive: $jeopardySeasonsViewActive,
                               label: { EmptyView() }).isDetailLink(false).hidden()
            }
            .navigationBarHidden(true)
            .withBackground()
            .edgesIgnoringSafeArea(.bottom)
            .animation(.easeInOut(duration: 0.2))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct HomepageMySetSelectorView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    var customSet: CustomSetCherry
    
    var imageSystemName: String {
        if !customSet.isPublic {
            return "lock"
        } else {
            return ""
        }
    }
    
    var shouldBeHighlighted: Bool {
        return gamesVM.customSet.id == customSet.id && exploreVM.homepageIsDisplaying == .setPreview
    }
    
    var body: some View {
        HStack (spacing: 6) {
            if !imageSystemName.isEmpty {
                Image(systemName: imageSystemName)
                    .font(.system(size: 20))
                    .offset(y: -2)
            }
            Text(customSet.title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundColor(formatter.color(shouldBeHighlighted ? .highContrastWhite : .lowContrastWhite))
        .contentShape(Rectangle())
        .onTapGesture {
            guard let setID = customSet.id else { return }
            formatter.hapticFeedback(style: .light)
            exploreVM.homepageIsDisplaying = .setPreview
            exploreVM.shortenPublicSetsTo(10, customSet: customSet)
            gamesVM.reset()
            gamesVM.getCustomData(setID: setID)
            participantsVM.resetScores()
        }
    }
}

struct SetHorizontalScrollView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var customSets: [CustomSetCherry]
    
    var emptyLabelString: String = "Nothing yet! When you make a set, it’ll show up here."
    
    let labelText: String
    let promptText: String
    let buttonAction: () -> ()
    
    var body: some View {
        VStack (spacing: 5) {
            HStack {
                Text("\(labelText)")
                Spacer()
                Button {
                    buttonAction()
                } label: {
                    Text("\(promptText)")
                        .foregroundColor(formatter.color(.secondaryAccent))
                }
            }
            .padding(.horizontal, 25)
            CustomSetsView(customSets: $customSets, emptyLabelString: emptyLabelString)
        }
    }
}

struct HomepageHeaderView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM : BuildViewModel
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var buildViewActive = false
    @State var profileViewActive = false
    
    var body: some View {
        ZStack {
            VStack (spacing: 0) {
                if buildVM.dirtyBit > 0 && !buildVM.currCustomSet.title.isEmpty {
                    HStack (alignment: .center) {
                        VStack (alignment: .leading, spacing: 5) {
                            Text("Set in progress")
                                .font(formatter.font(fontSize: .small))
                            Text("Tap to continue editing “\(buildVM.currCustomSet.title)”")
                                .font(formatter.font(.regular, fontSize: .small))
                        }
                        Spacer()
                        Button {
                            buildVM.writeToFirestore()
                            // This is so sketchy and I should switch to either a completion handler or async await but I'm LAZY right now!
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                buildVM.clearAll()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 20))
                                .padding()
                        }
                    }
                    .padding(.leading)
                    .padding(.bottom, 7)
                    .background(formatter.color(.primaryFG))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        buildViewActive.toggle()
                    }
                }
                HStack {
                    Text("Trivio!")
                        .font(formatter.font(fontSize: .extraLarge))
                    Spacer()
                    Button {
                        formatter.hapticFeedback(style: .heavy, intensity: .weak)
                        profileViewActive.toggle()
                    } label: {
                        Text("\(exploreVM.getInitialsFromUserID(userID: profileVM.myUID ?? ""))")
                            .font(formatter.font(.boldItalic, fontSize: .micro))
                            .frame(width: 45, height: 45)
                            .background(formatter.color(.primaryAccent))
                            .clipShape(Circle())
                            .overlay(
                                    Circle()
                                        .stroke(formatter.color(.highContrastWhite), lineWidth: 2)
                                )
                    }
                }
                .padding([.horizontal, .top], 25)
                .padding(.bottom, 10)
            }
            
            NavigationLink(destination: ProfileView()
                .navigationBarTitle("Profile", displayMode: .inline),
                           isActive: $profileViewActive,
                           label: { EmptyView() }).isDetailLink(false).hidden()
            NavigationLink (isActive: $buildViewActive) {
                BuildView()
            } label: { EmptyView() }.hidden()
        }
    }
}

struct ExploreBuildPromptButtonView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var isPresentingBuildView = false
    
    var body: some View {
        ZStack {
            VStack {
                Button {
                    isPresentingBuildView.toggle()
                    buildVM.start()
                    // Request app store review if the conditions are right
                    let shouldRequestAndCurrentVersion = profileVM.shouldRequestAppStoreReview()
                    if shouldRequestAndCurrentVersion.0 {
                        if let windowScene = UIApplication.shared.windows.first?.windowScene { SKStoreReviewController.requestReview(in: windowScene) }
                        profileVM.updateMyUserRecords(fieldName: "lastVersionReviewPrompt", newValue: shouldRequestAndCurrentVersion.1)
                        profileVM.myUserRecords.lastVersionReviewPrompt = shouldRequestAndCurrentVersion.1
                    }
                } label: {
                    HStack {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Build a Set!")
                    }
                    .font(formatter.font())
                    .foregroundColor(formatter.color(.highContrastWhite))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(formatter.color(.primaryAccent))
                    .cornerRadius(10)
                }
            }
            NavigationLink (isActive: $isPresentingBuildView) {
                BuildView()
            } label: { EmptyView() }
                .hidden()
        }
    }
}

struct ExploreSectionHeaderView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    let labelText: String
    let promptText: String
    var buttonAction: () -> ()
    
    var body: some View {
        HStack {
            Text("\(labelText)")
            Spacer()
            Button {
                buttonAction()
            } label: {
                Text("\(promptText)")
                    .foregroundColor(formatter.color(.secondaryAccent))
            }
        }
        .padding(.horizontal, 15)
    }
}
