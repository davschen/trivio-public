//
//  MobileBuildAllView.swift
//  Trivio!
//
//  Created by David Chen on 10/28/22.
//

import Foundation
import SwiftUI
import Introspect

struct MobileBuildAllView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    @Binding var category: CustomSetCategory
    @Binding var categoryIndex: Int
    
    @State var categoryName = ""
    @State var clueString = ""
    @State var responseString = ""
    
    init(category: Binding<CustomSetCategory>, categoryIndex: Binding<Int>) {
        self._category = category
        self._categoryIndex = categoryIndex
        UIScrollView.appearance().keyboardDismissMode = .interactive
    }
    
    var isDJ: Bool {
        return buildVM.buildStage == .dtRound || buildVM.buildStage == .dtRoundDD
    }
    
    var body: some View {
        VStack (spacing: 10) {
            MobileBuildAllHeaderView(categoryIndex: $categoryIndex, category: $category, categoryName: $categoryName, clueString: $clueString, responseString: $responseString)
                .padding([.top, .horizontal])
            
            // These two are identical, except that iOS 16 devices will not display overlays
            if #available(iOS 16.0, *) {
                TabView (selection: $categoryIndex) {
                    ForEach(0..<(isDJ ? buildVM.currCustomSet.round2Len : buildVM.currCustomSet.round1Len), id: \.self) { categoryIndex in
                        MobileBuildAllCategoryView(categoryIndex: $categoryIndex, category: isDJ ? $buildVM.djCategories[categoryIndex] : $buildVM.jCategories[categoryIndex], categoryName: categoryName, clueString: clueString, responseString: responseString)
                            .tag(category.id)
                            .padding(.horizontal)
                    }
                }
                .tabViewStyle(.page)
                .persistentSystemOverlays(.hidden)
            } else {
                TabView (selection: $categoryIndex) {
                    ForEach(0..<(isDJ ? buildVM.currCustomSet.round2Len : buildVM.currCustomSet.round1Len), id: \.self) { categoryIndex in
                        MobileBuildAllCategoryView(categoryIndex: $categoryIndex, category: isDJ ? $buildVM.djCategories[categoryIndex] : $buildVM.jCategories[categoryIndex], categoryName: categoryName, clueString: clueString, responseString: responseString)
                            .tag(category.id)
                            .padding(.horizontal)
                    }
                }
                .tabViewStyle(.page)
            }
        }
        .transaction { transaction in
            transaction.animation = nil
        }
        .onAppear {
            categoryName = category.name
        }
    }
}

struct MobileBuildAllCategoryView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    @Binding var categoryIndex: Int
    @Binding var category: CustomSetCategory
    
    @State var categoryName: String
    @State var clueString: String
    @State var responseString: String
    
    @State var isShowingCluePreview = false
    @State var swapToIndex = -1

    
    var primaryFG: Color {
        return formatter.color(.primaryFG)
    }
    
    var primaryBG: Color {
        return formatter.color(.primaryBG)
    }
    
    var body: some View {
        ScrollView (.vertical, showsIndicators: false) {
            VStack (alignment: .leading, spacing: 10) {
                VStack (alignment: .leading) {
                    HStack {
                        ZStack (alignment: .leading) {
                            if categoryName.isEmpty {
                                Text("Untitled")
                                    .font(formatter.font(.boldItalic, fontSize: .medium))
                                    .foregroundColor(formatter.color(.lowContrastWhite))
                            }
                            TextField("", text: $categoryName, onEditingChanged: { didEditingChange in
                                if category.name != categoryName { buildVM.incrementDirtyBit() }
                                category.name = categoryName
                            }) {
                                formatter.resignKeyboard()
                                category.name = categoryName
                            }
                            .padding(.vertical, 20)
                        }
                        Button {
                            formatter.resignKeyboard()
                            category.name.isEmpty ? buildVM.setEditingIndex(index: 0) : ()
                            category.name = categoryName
                            buildVM.incrementDirtyBit()
                        } label: {
                            Text("Done")
                                .font(formatter.font())
                                .foregroundColor(formatter.color(.secondaryAccent))
                        }
                        .opacity(categoryName != category.name ? 1 : 0)
                        .disabled(categoryName == category.name)
                    }
                    .padding(.horizontal)
                    .background(formatter.color(category.name.isEmpty ? .secondaryFG : .primaryAccent))
                    .cornerRadius(5)
                }
                
                HStack (alignment: .top, spacing: 10) {
                    MobileBuildAllCluePickerView(category: $category, clueString: $clueString, responseString: $responseString, isShowingCluePreview: $isShowingCluePreview)
                    if isShowingCluePreview {
                        MobileBuildAllCluePreviewView(category: $category, clueString: $clueString, responseString: $responseString, isShowingCluePreview: $isShowingCluePreview)
                            .padding(.bottom, 45)
                    } else {
                        MobileBuildAllClueEntryView(category: $category, clueString: $clueString, responseString: $responseString, isShowingCluePreview: $isShowingCluePreview)
                            .padding(.bottom, 15)
                    }
                }
                .contentShape(Rectangle())
                .disabled(category.name.isEmpty)
                .opacity(category.name.isEmpty ? 0.4 : 1)
                .padding(.bottom)
            }
            .background(formatter.color(.primaryBG))
            .cornerRadius(5)
        }
        .onChange(of: categoryIndex) { newCategoryIndex in
            buildVM.editingCategoryIndex = newCategoryIndex
            formatter.resignKeyboard()
        }
        .onAppear {
            categoryName = category.name
        }
    }
}

struct MobileBuildAllHeaderView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    @Binding var categoryIndex: Int
    @Binding var category: CustomSetCategory
    @Binding var categoryName: String
    @Binding var clueString: String
    @Binding var responseString: String
    
    var isDJ: Bool {
        return buildVM.buildStage == .dtRound || buildVM.buildStage == .dtRoundDD
    }
    
    var roundLen: Int {
        return isDJ ? buildVM.currCustomSet.round2Len : buildVM.currCustomSet.round1Len
    }
    
    var body: some View {
        HStack (spacing: 8) {
            Button {
                buildVM.currentDisplay = .grid
                buildVM.determineMostAdvancedStage()
            } label: {
                HStack {
                    Image(systemName: "arrow.left")
                        .font(formatter.iconFont(.small))
                    Text("Back to board")
                }
                .foregroundColor(formatter.color(.secondaryAccent))
            }
            Spacer()
            HStack {
                Button {
                    categoryIndex -= (categoryIndex == 0) ? 0 : 1
                } label: {
                    Image(systemName: "chevron.left")
                        .font(formatter.iconFont(.small))
                        .opacity(categoryIndex == 0 ? 0.4 : 1)
                }
                Text("Category \(categoryIndex + 1)")
                    .frame(width: 100)
                Button {
                    categoryIndex += ((categoryIndex + 1) == roundLen) ? 0 : 1
                } label: {
                    Image(systemName: "chevron.right")
                        .font(formatter.iconFont(.small))
                        .opacity((categoryIndex + 1) == roundLen ? 0.4 : 1)
                }
            }
        }
    }
}

struct MobileBuildAllCluePickerView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    @Binding var category: CustomSetCategory
    @Binding var clueString: String
    @Binding var responseString: String
    @Binding var isShowingCluePreview: Bool
    
    func shouldShowPreview(index: Int) -> Bool {
        return !(isShowingCluePreview && category.clues[index].isEmpty && category.responses[index].isEmpty)
    }
    
    var body: some View {
        VStack (spacing: 5) {
            ForEach(0..<category.clues.count, id: \.self) { i in
                Text("\(buildVM.moneySections[i])")
                    .font(formatter.font(fontSize: .mediumLarge))
                    .foregroundColor(formatter.color(.secondaryAccent))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(formatter.color((!category.clues[i].isEmpty && !category.responses[i].isEmpty) ? .primaryAccent : .primaryFG))
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(formatter.color(.highContrastWhite), lineWidth: buildVM.editingClueIndex == i ? 2 : 0)
                    )
                    .onTapGesture {
                        if !shouldShowPreview(index: i) {
                            isShowingCluePreview.toggle()
                        }
                        formatter.dismissKeyboard()
                        category.clues[buildVM.editingClueIndex] = clueString
                        category.responses[buildVM.editingClueIndex] = responseString
                        clueString = category.clues[i]
                        responseString = category.responses[i]
                        buildVM.setEditingIndex(index: i)
                    }
            }
        }
        .frame(width: 70)
        .onChange(of: category.clues) { _ in
            buildVM.incrementDirtyBit()
        }
        .onChange(of: category.responses) { _ in
            buildVM.incrementDirtyBit()
        }
    }
}

struct MobileBuildAllClueEntryView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    @Binding var category: CustomSetCategory
    @Binding var clueString: String
    @Binding var responseString: String
    @Binding var isShowingCluePreview: Bool
    
    var canShowPreview: Bool {
        return !clueString.isEmpty && !responseString.isEmpty
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(formatter.color(.primaryFG))
                .frame(maxWidth: .infinity)
                .frame(height: 270)
                .cornerRadius(5)
            VStack (spacing: 0) {
                HStack {
                    Text("\(buildVM.moneySections[buildVM.editingClueIndex])")
                        .font(formatter.font(.bold, fontSize: .large))
                        .foregroundColor(formatter.color(.secondaryAccent))
                    Spacer()
                }
                .padding([.top, .horizontal])
                
                VStack (spacing: 20) {
                    VStack (spacing: 2) {
                        ZStack (alignment: .leading) {
                            if clueString.isEmpty {
                                Text("Clue")
                                    .font(formatter.font(.boldItalic))
                                    .foregroundColor(formatter.color(.lowContrastWhite))
                            }
                            MobileMultilineTextField("", text: $clueString) {
                                category.clues[buildVM.editingClueIndex] = clueString
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
                    VStack (spacing: 4) {
                        ZStack (alignment: .leading) {
                            if responseString.isEmpty {
                                Text("Response")
                                    .font(formatter.font(.boldItalic))
                                    .foregroundColor(formatter.color(.lowContrastWhite))
                            }
                            TextField("", text: $responseString, onEditingChanged: { editingChanged in
                                category.clues[buildVM.editingClueIndex] = clueString
                                category.responses[buildVM.editingClueIndex] = responseString
                            })
                            .accentColor(formatter.color(.secondaryAccent))
                            .font(formatter.font(.bold))
                            .foregroundColor(formatter.color(.secondaryAccent))
                        }
                        Rectangle()
                            .fill(formatter.color(.secondaryAccent))
                            .frame(maxWidth: .infinity)
                            .frame(height: 2)
                    }
                    HStack {
                        Spacer()
                        Button {
                            category.clues[buildVM.editingClueIndex] = clueString
                            category.responses[buildVM.editingClueIndex] = responseString
                            canShowPreview ? isShowingCluePreview.toggle() : ()
                        } label: {
                            Text("Preview")
                                .foregroundColor(formatter.color(.secondaryAccent))
                                .opacity(canShowPreview ? 1 : 0.4)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding([.bottom, .horizontal])
            }
            .background(formatter.color(.primaryFG))
            .cornerRadius(5)
        }
        .transaction { transaction in
            transaction.animation = nil
        }
        .onAppear {
            clueString = category.clues[buildVM.editingClueIndex]
            responseString = category.responses[buildVM.editingClueIndex]
        }
    }
}

struct MobileBuildAllCluePreviewView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    @Binding var category: CustomSetCategory
    @Binding var clueString: String
    @Binding var responseString: String
    @Binding var isShowingCluePreview: Bool
    
    @State var isShowingResponse = false
    
    var body: some View {
        VStack (spacing: 10) {
            if buildVM.isPreviewDisplayModern {
                VStack (alignment: .leading, spacing: 20) {
                    Text("\(category.name.uppercased()) for \(buildVM.moneySections[buildVM.editingClueIndex])")
                        .font(formatter.font(.bold, fontSize: .regular))
                        .id(category.name)
                    Text(clueString)
                        .font(formatter.font(.regular, fontSize: .mediumLarge))
                        .lineSpacing(3)
                        .id(clueString)
                    Text(responseString)
                        .font(formatter.font(.regular, fontSize: .mediumLarge))
                        .foregroundColor(formatter.color(.secondaryAccent))
                        .opacity(isShowingResponse ? 1 : 0)
                        .id(responseString)
                    Spacer()
                    Button {
                        isShowingResponse.toggle()
                    } label: {
                        Text(isShowingResponse ? "Hide Response" : "Show Response")
                            .font(formatter.font(fontSize: .regular))
                            .foregroundColor(formatter.color(isShowingResponse ? .primaryAccent : .highContrastWhite))
                            .padding(.vertical)
                            .frame(maxWidth: .infinity)
                            .background(formatter.color(isShowingResponse ? .highContrastWhite : .primaryAccent))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(formatter.color(.highContrastWhite), lineWidth: isShowingResponse ? 0 : 2)
                            )
                    }
                }
                .padding()
                .frame(minHeight: 270)
                .background(formatter.color(.primaryAccent))
                .cornerRadius(5)
            } else {
                VStack (alignment: .leading, spacing: 0) {
                    Text("\(category.name.uppercased()) for \(buildVM.moneySections[buildVM.editingClueIndex])")
                        .font(formatter.font(.regular, fontSize: .regular))
                        .id(category.name)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(formatter.color(.lowContrastWhite))
                    Spacer(minLength: 15)
                    VStack {
                        Text(clueString.uppercased())
                            .font(formatter.font(.bold, fontSize: .regular))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                            .id(clueString)
                            .lineSpacing(3)
                            .padding(.horizontal)
                            .padding(.bottom, isShowingResponse ? 5 : 0)
                        if isShowingResponse {
                            Text(responseString.uppercased())
                                .font(formatter.font(.bold, fontSize: .regular))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .foregroundColor(formatter.color(.secondaryAccent))
                                .id(responseString)
                                .padding([.horizontal, .bottom])
                        }
                    }
                    Spacer(minLength: 0)
                    Button {
                        isShowingResponse.toggle()
                    } label: {
                        Text(isShowingResponse ? "Hide Response" : "Show Response")
                            .font(formatter.font(fontSize: .regular))
                            .foregroundColor(formatter.color(isShowingResponse ? .primaryAccent : .highContrastWhite))
                            .padding(.vertical)
                            .frame(maxWidth: .infinity)
                            .background(formatter.color(isShowingResponse ? .highContrastWhite : .primaryAccent))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(formatter.color(.highContrastWhite), lineWidth: isShowingResponse ? 0 : 2)
                            )
                    }
                    .padding([.horizontal, .bottom])
                }
                .frame(minHeight: 270)
                .background(formatter.color(.primaryAccent))
                .cornerRadius(5)
            }
            
            HStack {
                HStack (spacing: 5) {
                    ZStack(alignment: (buildVM.isPreviewDisplayModern ? .trailing : .leading)) {
                        Capsule()
                            .frame(width: 30, height: 15)
                            .foregroundColor(formatter.color(buildVM.isPreviewDisplayModern ? .secondaryAccent : .primaryFG))
                        Circle()
                            .frame(width: 15, height: 15)
                    }
                    .animation(.easeInOut(duration: 0.1), value: UUID().uuidString)
                    .onTapGesture {
                        buildVM.isPreviewDisplayModern.toggle()
                    }
                    
                    Text("\(buildVM.isPreviewDisplayModern ? "Modern" : "Classic")")
                        .font(formatter.font(.regular))
                        .id(buildVM.isPreviewDisplayModern)
                }
                Spacer()
                Button {
                    isShowingCluePreview.toggle()
                    category.clues[buildVM.editingClueIndex] = clueString
                    category.responses[buildVM.editingClueIndex] = responseString
                } label: {
                    Text("Edit")
                        .foregroundColor(formatter.color(.secondaryAccent))
                }
            }
        }
    }
}
