//
//  MobileTrivioLivePreviewView.swift
//  Trivio!
//
//  Created by David Chen on 10/27/22.
//

import Foundation
import SwiftUI
import StoreKit

struct MobileTrivioLivePreviewView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var appStoreManager: AppStoreManager
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @State var isPresentingTrivioLiveView: Bool = false
    
    var hasSubscribed: Bool {
        return UserDefaults.standard.bool(forKey: "iOS.Trivio.3.0.Cherry.OTLHT")
    }
    
    var numMonthlyGamesLeft = 1
    
    init() {
        Theme.navigationBarColors(
            background: UIColor(MasterHandler().color(.primaryFG)),
            titleColor: UIColor(MasterHandler().color(.highContrastWhite))
        )
    }
    
    var body: some View {
        ZStack {
            formatter.color(.primaryBG)
                .edgesIgnoringSafeArea(.all)
            HStack (spacing: 15) {
                VStack (alignment: .leading, spacing: 15) {
                    // Banner
                    HStack {
                        VStack (alignment: .leading, spacing: 5) {
                            Text("\(numMonthlyGamesLeft) free live game left this month")
                                .font(formatter.font(fontSize: .regular))
                            Text("Effective once game starts. Tap to find out more.")
                                .font(formatter.font(.regularItalic, fontSize: .small))
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "xmark")
                    }
                    .padding()
                    .background(formatter.color(.red))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(formatter.color(.highContrastWhite), lineWidth: 2)
                    )
                    
                    MobileTrivioLivePreviewHeaderView()
                    
                    VStack (spacing: 10) {
                        Image(systemName: "iphone")
                            .font(.system(size: 25))
                        Text("\(gamesVM.liveGameCustomSet.playerCode)")
                            .font(formatter.font(fontSize: .extraLarge))
                        Text("Enter Code at www.trivio.live in a mobile browser to join the game.")
                            .multilineTextAlignment(.center)
                            .font(formatter.font(.regular, fontSize: .small))
                            .frame(maxWidth: 170)
                            .padding(.top, -5)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(formatter.color(.primaryFG))
                    .cornerRadius(10)
                }
                .frame(width: 350)
                VStack (spacing: 15) {
                    Text("\(gamesVM.liveGamePlayers.count) Contestants")
                        .font(formatter.font(fontSize: .mediumLarge))
                    if gamesVM.liveGamePlayers.isEmpty {
                        VStack (spacing: 20) {
                            LoadingView()
                            Text("Waiting for people to join")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(formatter.color(.secondaryFG))
                    } else {
                        ScrollView (showsIndicators: false) {
                            VStack {
                                Rectangle()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 1)
                                    .foregroundColor(formatter.color(.lowContrastWhite))
                                ForEach(gamesVM.liveGamePlayers) { player in
                                    VStack (spacing: 15) {
                                        HStack {
                                            Text("\(player.nickname)")
                                            Spacer()
                                            Text("Rename")
                                                .font(formatter.font(.regular))
                                            Button {
                                                
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 14, weight: .regular))
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.top, 7)
                                        Rectangle()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 1)
                                            .foregroundColor(formatter.color(.lowContrastWhite))
                                    }
                                }
                            }
                        }
                    }
                    
                    Button {
                        isPresentingTrivioLiveView.toggle()
                    } label: {
                        Text("Start Game")
                            .font(formatter.font(.boldItalic, fontSize: .regular))
                            .foregroundColor(formatter.color(.primaryFG))
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(formatter.color(.highContrastWhite))
                            .clipShape(Capsule())
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .frame(maxHeight: .infinity)
                .background(formatter.color(.primaryFG))
                .cornerRadius(10)
            }
            .padding()
            
            NavigationLink(isActive: $isPresentingTrivioLiveView, destination: {
                MobileTrivioLiveView()
            }, label: { EmptyView() })
            .isDetailLink(false)
            .hidden()
        }
        .navigationTitle("Waiting Room")
        .withBackButton()
    }
}

struct MobileTrivioLiveCodeCardView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var appStoreManager: AppStoreManager
    
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    let product: SKProduct
    
    @State var isLoading = false
    
    var body: some View {
        VStack (spacing: 0) {
            VStack (spacing: 5) {
                Text("\(gamesVM.liveGameCustomSet.playerCode)")
                    .font(formatter.fontFloat(.bold, sizeFloat: 45.0))
                Text("Enter Code at www.trivio.live into a computer’s browser to host your game")
                    .font(formatter.font(.regular, fontSize: .regular))
                    .frame(width: 200)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 25)
            .background(formatter.color(.secondaryFG))
            
            VStack (spacing: 15) {
                VStack {
                    ZStack {
                        Circle()
                            .fill(formatter.color(.secondaryAccent))
                            .frame(width: 90, height: 90)
                            .opacity(0.4)
                        Circle()
                            .fill(formatter.color(.secondaryAccent))
                            .frame(width: 65, height: 65)
                        Text("\(profileVM.myUserRecords.numLiveTokens)")
                            .font(formatter.fontFloat(.bold, sizeFloat: 24.0))
                            .foregroundColor(formatter.color(.primaryBG))
                    }
                    VStack (spacing: 5) {
                        Text("Live games left this month")
                        Text("(Tokens replenish each month)")
                    }
                    .font(formatter.font(.regular, fontSize: .medium))
                }
                Button {
                    isLoading = true
                    appStoreManager.purchaseProduct(product: product)
                } label: {
                    ZStack {
                        if isLoading {
                            LoadingView()
                                .padding(.vertical, 19.5)
                        } else {
                            Text("Buy one more for $\(product.price)")
                                .padding(.vertical, 15)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(formatter.color(.primaryAccent))
                    .cornerRadius(5)
                }
                Text("""
                     Note: game tokens will not be spent until you enter the code in a desktop browser
                     """)
                .font(formatter.font(.regularItalic, fontSize: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2.0)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(formatter.color(.primaryFG))
        }
        .cornerRadius(10)
        .onChange(of: appStoreManager.transactionState) { newState in
            if appStoreManager.currentTransactionProductID != product.productIdentifier {
                return
            }
            if newState == .failed {
                isLoading = false
            } else if newState == .purchased {
                profileVM.incrementNumTokens()
                isLoading = false
            }
        }
    }
}

struct MobileTrivioLiveSubscriptionView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var appStoreManager: AppStoreManager
    
    @State var isLoading = false
    
    let product: SKProduct
    
    var body: some View {
        VStack (spacing: 10) {
            VStack (spacing: 10) {
                Text("Trivio! Pro")
                HStack (alignment: .top) {
                    Text("$1")
                        .font(formatter.fontFloat(.bold, sizeFloat: 24.0))
                    Text("/month")
                        .font(formatter.font(.regular, fontSize: .regular))
                        .offset(y: 2)
                }
                Text("$\(product.price) billed annually")
                    .font(formatter.font(.regular, fontSize: .regular))
                    .foregroundColor(formatter.color(.lowContrastWhite))
            }
            
            Text("""
                 Unlimited live games, unlimited participants. Perfect for teachers, managers, or anyone who wants to host multiple live games in a month. 1/3 the price of other comparable offerings.
                 """)
            .font(formatter.font(.regular, fontSize: .regular))
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineSpacing(2.0)
            
            Button {
                if profileVM.myUserRecords.isSubscribed {
                    return
                }
                appStoreManager.purchaseProduct(product: product)
            } label: {
                ZStack {
                    if isLoading {
                        LoadingView()
                    } else {
                        Text(profileVM.myUserRecords.isSubscribed ? "Subscribed!" : "Buy Now")
                    }
                }
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(formatter.color(profileVM.myUserRecords.isSubscribed ? .secondaryAccent : .primaryAccent))
                .cornerRadius(5)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 10).stroke(formatter.color(.highContrastWhite), lineWidth: 1))
        .padding(1)
        .onChange(of: appStoreManager.transactionState) { newState in
            if newState == .purchased {
                profileVM.updateMyUserRecords(fieldName: "isSubscribed", newValue: true)
            }
            isLoading = false
        }
    }
}

struct MobileTrivioLivePreviewHeaderView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var exploreVM: ExploreViewModel
    
    @State var userViewActive = false
    
    var isShowingDescription: Bool = true
    
    var body: some View {
        ZStack {
            VStack (alignment: .leading, spacing: 5) {
                Text("\(gamesVM.customSet.title)")
                    .font(formatter.font(fontSize: .semiLarge))
                HStack (spacing: 0) {
                    Text("Created by ")
                    Text(exploreVM.getUsernameFromUserID(userID: gamesVM.customSet.userID))
                    Text(" on \(gamesVM.dateFormatter.string(from: gamesVM.customSet.dateCreated))")
                }
                if !gamesVM.customSet.description.isEmpty && isShowingDescription {
                    Text(gamesVM.customSet.description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(formatter.color(.mediumContrastWhite))
                        .lineSpacing(3)
                        .padding(.top, 2)
                }
            }
            .font(formatter.font(.regular, fontSize: .regular))
        }
    }
}
