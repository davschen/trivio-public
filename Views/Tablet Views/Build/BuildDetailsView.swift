//
//  BuildDetailsView.swift
//  Trivio!
//
//  Created by David Chen on 7/22/21.
//

import Foundation
import SwiftUI

struct BuildDetailsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @State var selectedTag = ""
    @State var showingInstructions = false
    @State var setTitle = ""
    @State var setDescription = ""
    @State var tagString = ""
    
    var body: some View {
        ScrollView (.vertical, showsIndicators: false) {
            VStack (alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(formatter.font(fontSize: .semiLarge))
                    .padding(.top, 30)
                VStack (alignment: .leading, spacing: 5) {
                    HStack (alignment: .top, spacing: 4) {
                        Text("Let's give your set a title")
                            .font(formatter.font(.regularItalic, fontSize: .regular))
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(formatter.color(.red))
                    }
                    ZStack (alignment: .leading) {
                        if setTitle.isEmpty {
                            Text("Untitled")
                                .foregroundColor(formatter.color(.lowContrastWhite))
                                .font(formatter.font(.boldItalic, fontSize: .large))
                        }
                        TextField("", text: $setTitle, onEditingChanged: { newTitle in
                            if buildVM.currCustomSet.title != setTitle {
                                buildVM.currCustomSet.title = setTitle
                                buildVM.incrementDirtyBit()
                            }
                        })
                        .accentColor(formatter.color(.secondaryAccent))
                        .font(formatter.font(fontSize: .large))
                        .frame(height: 80)
                    }
                    .padding(.horizontal)
                    .background(formatter.color(.primaryFG))
                    .cornerRadius(5)
                }
                VStack (alignment: .leading, spacing: 5) {
                    Text("(Recommended) Add a description")
                        .font(formatter.font(.regularItalic, fontSize: .regular))
                    VStack (spacing: 2) {
                        ZStack (alignment: .leading) {
                            if setDescription.isEmpty {
                                Text("Description")
                                    .font(formatter.font(.regularItalic, fontSize: .mediumLarge))
                                    .foregroundColor(formatter.color(.lowContrastWhite))
                            }
                            MultilineTextField("", text: $setDescription) {
                                if buildVM.currCustomSet.description != setDescription {
                                    buildVM.incrementDirtyBit()
                                    buildVM.currCustomSet.description = setDescription
                                }
                            }
                            .accentColor(formatter.color(.highContrastWhite))
                            .offset(x: -5)
                        }
                        
                        Rectangle()
                            .fill(formatter.color(.highContrastWhite))
                            .frame(maxWidth: .infinity)
                            .frame(height: 2)
                            .offset(y: -5)
                    }
                }
                VStack (alignment: .leading, spacing: 3) {
                    HStack (alignment: .bottom) {
                        HStack (alignment: .top, spacing: 4) {
                            Text("Add one or more tags")
                                .font(formatter.font(.regularItalic, fontSize: .regular))
                            Circle()
                                .frame(width: 8, height: 8)
                                .foregroundColor(formatter.color(.red))
                        }
                        Spacer()
                        Button {
                            showingInstructions.toggle()
                        } label: {
                            Image(systemName: showingInstructions ? "questionmark.circle.fill" : "questionmark.circle")
                                .font(formatter.iconFont(.small))
                        }
                    }
                    
                    // Tags view
                    FlexibleView(data: buildVM.currCustomSet.tags, spacing: 3, alignment: .leading) { item in
                        HStack (spacing: 0) {
                            Text("#")
                            Text(verbatim: item.uppercased())
                            if selectedTag == item {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .onTapGesture {
                                        buildVM.removeTag(tag: item)
                                    }
                                    .padding(.leading, 5)
                            }
                        }
                        .foregroundColor(formatter.color(selectedTag == item ? .primaryFG : .highContrastWhite))
                        .font(formatter.font(.boldItalic, fontSize: .small))
                        .padding(selectedTag == item ? 9 : 10)
                        .background(formatter.color(selectedTag == item ? .highContrastWhite : .secondaryFG))
                        .clipShape(Capsule())
                        .padding(.vertical, 2)
                        .animation(.easeInOut(duration: 0.1))
                        .onTapGesture {
                            selectedTag = selectedTag == item ? "" : item
                        }
                    }
                    .frame(minWidth: 300)
                    
                    HStack {
                        TextField("Tag", text: $tagString, onEditingChanged: { editingChanged in
                            buildVM.tag = tagString
                            formatter.hapticFeedback(style: .rigid, intensity: .weak)
                            buildVM.addTag()
                            tagString = ""
                            // insurance
                            buildVM.currCustomSet.description = setDescription
                        })
                        .accentColor(formatter.color(.secondaryAccent))
                        .font(formatter.font(.boldItalic, fontSize: .mediumLarge))
                        Spacer()
                        Text("Add")
                            .font(formatter.font(fontSize: .medium))
                            .foregroundColor(formatter.color(.secondaryAccent))
                            .opacity(tagString.isEmpty ? 0.4 : 1)
                            .onTapGesture {
                                addTags()
                            }
                    }
                    .padding(15)
                    .background(formatter.color(.primaryFG))
                    .cornerRadius(5)
                    
                    if showingInstructions {
                        Text("Tags are single words that describe your set. If your set is public, tags will help people discover your set. You must have at least one tag.")
                            .font(formatter.font(.regularItalic, fontSize: .regular))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 5)
                    }
                }
                VStack (alignment: .leading) {
                    Text("How many rounds in this game?")
                        .font(formatter.font(.regularItalic, fontSize: .regular))
                    HStack {
                        Text("1")
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(formatter.color(!buildVM.currCustomSet.hasTwoRounds ? .primaryAccent : .primaryFG))
                            .cornerRadius(5)
                            .onTapGesture {
                                addTags()
                                if buildVM.currCustomSet.hasTwoRounds {
                                    buildVM.currCustomSet.hasTwoRounds = false
                                    buildVM.incrementDirtyBit()
                                }
                            }
                        Text("2")
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(formatter.color(buildVM.currCustomSet.hasTwoRounds ? .primaryAccent : .primaryFG))
                            .cornerRadius(5)
                            .onTapGesture {
                                addTags()
                                if !buildVM.currCustomSet.hasTwoRounds {
                                    buildVM.currCustomSet.hasTwoRounds = true
                                    buildVM.incrementDirtyBit()
                                }
                            }
                    }
                    .font(formatter.font(fontSize: .large))
                    .foregroundColor(formatter.color(.secondaryAccent))
                }
                HStack {
                    VStack (alignment: .leading) {
                        Text("Round 1 Categories")
                            .font(formatter.font(.regularItalic, fontSize: .regular))
                        HStack (spacing: 2) {
                            Text("\(buildVM.currCustomSet.round1Len)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Button {
                                buildVM.subtractCategoryRound1()
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(formatter.iconFont(.medium))
                                    .opacity(buildVM.currCustomSet.round1Len == 3 ? 0.4 : 1)
                            }
                            Button {
                                buildVM.addCategoryRound1()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(formatter.iconFont(.medium))
                                    .opacity(buildVM.currCustomSet.round1Len == 6 ? 0.4 : 1)
                            }
                        }
                        .font(formatter.font(fontSize: .mediumLarge))
                        .padding()
                        .frame(height: 70)
                        .background(formatter.color(.primaryFG))
                        .cornerRadius(5)
                    }
                    if buildVM.currCustomSet.hasTwoRounds {
                        VStack (alignment: .leading) {
                            Text("Round 2 Categories")
                                .font(formatter.font(.regularItalic, fontSize: .regular))
                            HStack (spacing: 2) {
                                Text("\(buildVM.currCustomSet.round2Len)")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                                Button {
                                    buildVM.subtractCategoryRound2()
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(formatter.iconFont(.medium))
                                        .opacity(buildVM.currCustomSet.round2Len == 3 ? 0.4 : 1)
                                }
                                Button {
                                    buildVM.addCategoryRound2()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(formatter.iconFont(.medium))
                                        .opacity(buildVM.currCustomSet.round2Len == 6 ? 0.4 : 1)
                                }
                            }
                            .font(formatter.font(fontSize: .mediumLarge))
                            .padding()
                            .frame(height: 70)
                            .background(formatter.color(.primaryFG))
                            .cornerRadius(5)
                        }
                    }
                }
                HStack (spacing: 10) {
                    ZStack(alignment: (buildVM.currCustomSet.isPublic ? .trailing : .leading)) {
                        Capsule()
                            .frame(width: 30, height: 15)
                            .foregroundColor(formatter.color(buildVM.currCustomSet.isPublic ? .secondaryAccent : .primaryFG))
                        Circle()
                            .frame(width: 15, height: 15)
                    }
                    .animation(.easeInOut(duration: 0.1), value: UUID().uuidString)
                    .onTapGesture {
                        buildVM.incrementDirtyBit()
                        buildVM.currCustomSet.isPublic.toggle()
                    }
                    
                    Text("\(buildVM.currCustomSet.isPublic ? "Public: anyone can play this set" : "Private: only I can see this set")")
                        .font(formatter.font(.regular))
                }
                Text("Tip: Each category is considered complete when it has one or more clues. So, if you’re stuck on a category, just finish one clue and move on. You can always come back to it later!")
                    .font(formatter.font(.regularItalic, fontSize: .regular))
                    .lineSpacing(3)
                    .padding(.bottom, 45)
            }
            .padding(.bottom, 45)
            .padding(.horizontal)
            .frame(maxWidth: 800, alignment: .leading)
        }
        .resignKeyboardOnDragGesture()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                setTitle = buildVM.currCustomSet.title
                setDescription = buildVM.currCustomSet.description
                buildVM.determineMostAdvancedStage()
            }
        }
    }
    
    func addTags() {
        if tagString.isEmpty { return }
        buildVM.tag = tagString
        formatter.hapticFeedback(style: .rigid, intensity: .weak)
        formatter.resignKeyboard()
        buildVM.addTag()
        tagString = ""
    }
}
