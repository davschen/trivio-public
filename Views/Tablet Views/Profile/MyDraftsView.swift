//
//  MyDraftsView.swift
//  Trivio!
//
//  Created by David Chen on 12/8/22.
//

import Foundation
import SwiftUI

struct MyDraftsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var expandedSetID = ""
    
    var body: some View {
        if profileVM.drafts.count > 0 {
            VStack (spacing: 3) {
                ForEach(profileVM.drafts, id: \.self) { draft in
                    DraftCellView(expandedSetID: $expandedSetID, draft: draft)
                        .animation(.easeInOut(duration: 0.2))
                        .onAppear {
                            guard let firstSetID = profileVM.drafts.first?.id else { return }
                            expandedSetID = expandedSetID.isEmpty ? firstSetID : expandedSetID
                        }
                }
            }
        } else {
            EmptyListView(label: "No drafts! Come back here when you save a draft.")
                .padding(.horizontal)
        }
    }
}

struct DraftCellView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @Binding var expandedSetID: String
    
    @State var draft: CustomSetCherry
    
    var setID: String {
        return draft.id ?? "NID"
    }
    
    @State var isPresentingBuildView = false
    
    var body: some View {
        VStack (alignment: .leading, spacing: 10) {
            HStack (spacing: 2) {
                if !draft.isPublic {
                    Image(systemName: "lock.fill")
                        .font(formatter.iconFont(.small))
                        .offset(x: -2, y: -1)
                }
                Text("\(draft.title)")
                    .font(formatter.font(fontSize: .mediumLarge))
                    .lineLimit(1)
                Spacer()
            }
            Text("\(draft.hasTwoRounds ? "2 rounds" : "1 round"), \(draft.numClues) clues")
                .font(formatter.font(.regular))
            Text("Draft created on \(gamesVM.dateFormatter.string(from: draft.dateCreated)), last modified on \(gamesVM.dateFormatter.string(from: draft.dateLastModified))")
                .foregroundColor(formatter.color(.lowContrastWhite))
                .font(formatter.font(.regular))
            
            if expandedSetID == setID {
                HStack (spacing: 5) {
                    Button(action: {
                        formatter.hapticFeedback(style: .soft, intensity: .strong)
                        isPresentingBuildView.toggle()
                        draft.isDraft = true
                        buildVM.edit(customSet: draft)
                    }, label: {
                        ZStack {
                            Text("Edit")
                                .font(formatter.font(fontSize: .medium))
                                .foregroundColor(formatter.color(.highContrastWhite))
                                .padding(10)
                                .frame(maxWidth: 150)
                                .frame(height: 55)
                                .background(formatter.color(.primaryAccent))
                                .clipShape(Capsule())
                            NavigationLink (isActive: $isPresentingBuildView) {
                                BuildView()
                            } label: { EmptyView() }
                                .hidden()
                        }
                    })
                    Button(action: {
                        formatter.setAlertSettings(alertAction: {
                            buildVM.deleteSet(customSet: draft)
                        }, alertTitle: "Are You Sure?", alertSubtitle: "You're about to delete your draft named \"\(draft.title)\" — deleting a draft is irreversible.", hasCancel: true, actionLabel: "Yes, delete my draft")
                    }, label: {
                        Text("Delete")
                            .foregroundColor(formatter.color(.red))
                            .font(formatter.font(fontSize: .medium))
                            .padding(10)
                            .frame(maxWidth: 150)
                            .frame(height: 55)
                            .background(formatter.color(.primaryFG))
                            .clipShape(Capsule())
                    })
                }
            }
        }
        .padding(.horizontal, 25).padding(.vertical, 20)
        .background(formatter.color(expandedSetID == setID ? .secondaryFG : .primaryFG))
        .contentShape(Rectangle())
        .onTapGesture {
            formatter.hapticFeedback(style: .rigid, intensity: .weak)
            expandedSetID = setID
        }
    }
}
