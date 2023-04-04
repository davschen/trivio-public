//
//  BuildAllView.swift
//  Trivio!
//
//  Created by David Chen on 12/8/22.
//

import Foundation
import SwiftUI
import Introspect

struct BuildAllView: View {
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
        VStack (spacing: 15) {
            BuildAllHeaderView(categoryIndex: $categoryIndex, category: $category, categoryName: $categoryName, clueString: $clueString, responseString: $responseString)
                .padding([.top, .horizontal], 25)
                .padding(.top, 15)
            TabView (selection: $categoryIndex) {
                ForEach(0..<(isDJ ? buildVM.currCustomSet.round2Len : buildVM.currCustomSet.round1Len), id: \.self) { categoryIndex in
                    BuildAllCategoryView(categoryIndex: $categoryIndex, category: isDJ ? $buildVM.djCategories[categoryIndex] : $buildVM.jCategories[categoryIndex], categoryName: categoryName, clueString: clueString, responseString: responseString)
                        .tag(category.id)
                        .padding(.horizontal, 25)
                }
            }
            .tabViewStyle(.page)
        }
        .transaction { transaction in
            transaction.animation = nil
        }
        .onAppear {
            categoryName = category.name
        }
    }
}

struct BuildAllCategoryView: View {
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
        VStack (alignment: .leading, spacing: 10) {
            VStack (alignment: .leading) {
                HStack {
                    ZStack (alignment: .leading) {
                        if categoryName.isEmpty {
                            Text("Untitled")
                                .font(formatter.font(.boldItalic, fontSize: .large))
                                .foregroundColor(formatter.color(.lowContrastWhite))
                        }
                        TextField("", text: $categoryName, onEditingChanged: { didEditingChange in
                            if category.name != categoryName { buildVM.incrementDirtyBit() }
                            category.name = categoryName
                        }) {
                            formatter.resignKeyboard()
                            category.name = categoryName
                        }
                        .padding(.vertical, 30)
                        .font(formatter.font(.bold, fontSize: .large))
                    }
                    Button {
                        formatter.resignKeyboard()
                        category.name.isEmpty ? buildVM.setEditingIndex(index: 0) : ()
                        category.name = categoryName
                        buildVM.incrementDirtyBit()
                    } label: {
                        Text("Done")
                            .font(formatter.font(fontSize: .mediumLarge))
                            .foregroundColor(formatter.color(.secondaryAccent))
                    }
                    .opacity(categoryName != category.name ? 1 : 0)
                    .disabled(categoryName == category.name)
                }
                .padding(.horizontal, 30)
                .background(formatter.color(category.name.isEmpty ? .secondaryFG : .primaryAccent))
                .cornerRadius(10)
            }
            
            HStack (alignment: .top, spacing: 10) {
                BuildAllCluePickerView(category: $category, clueString: $clueString, responseString: $responseString, isShowingCluePreview: $isShowingCluePreview)
                if isShowingCluePreview {
                    BuildAllCluePreviewView(category: $category, clueString: $clueString, responseString: $responseString, isShowingCluePreview: $isShowingCluePreview)
                } else {
                    BuildAllClueEntryView(category: $category, clueString: $clueString, responseString: $responseString, isShowingCluePreview: $isShowingCluePreview)
                }
            }
            .onTapGesture {
                formatter.resignKeyboard()
                category.name = categoryName
            }
            .padding(.bottom, 20)
            .contentShape(Rectangle())
            .disabled(category.name.isEmpty)
            .opacity(category.name.isEmpty ? 0.4 : 1)
            .padding(.bottom)
        }
        .background(formatter.color(.primaryBG))
        .cornerRadius(10)
        .onChange(of: categoryIndex) { newCategoryIndex in
            buildVM.editingCategoryIndex = newCategoryIndex
            formatter.resignKeyboard()
        }
        .onAppear {
            categoryName = category.name
        }
    }
}

struct BuildAllHeaderView: View {
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
                        .font(formatter.iconFont(.mediumLarge))
                    Text("Back to board")
                }
                .foregroundColor(formatter.color(.secondaryAccent))
                .font(formatter.font(.bold, fontSize: .semiLarge))
            }
            Spacer()
            HStack (spacing: 20) {
                Button {
                    categoryIndex -= (categoryIndex == 0) ? 0 : 1
                } label: {
                    Image(systemName: "chevron.left")
                        .font(formatter.iconFont(.mediumLarge))
                        .opacity(categoryIndex == 0 ? 0.4 : 1)
                }
                Text("Category \(categoryIndex + 1)")
                    .font(formatter.font(fontSize: .semiLarge))
                    .frame(width: 200)
                Button {
                    categoryIndex += ((categoryIndex + 1) == roundLen) ? 0 : 1
                } label: {
                    Image(systemName: "chevron.right")
                        .font(formatter.iconFont(.mediumLarge))
                        .opacity((categoryIndex + 1) == roundLen ? 0.4 : 1)
                }
            }
        }
    }
}

struct BuildAllCluePickerView: View {
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
        VStack (spacing: 7) {
            ForEach(0..<category.clues.count, id: \.self) { i in
                Text("\(buildVM.moneySections[i])")
                    .font(formatter.fontFloat(sizeFloat: 60))
                    .foregroundColor(formatter.color(.secondaryAccent))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(formatter.color((!category.clues[i].isEmpty && !category.responses[i].isEmpty) ? .primaryAccent : .primaryFG))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
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
        .frame(maxWidth: 200)
        .onChange(of: category.clues) { _ in
            buildVM.incrementDirtyBit()
        }
        .onChange(of: category.responses) { _ in
            buildVM.incrementDirtyBit()
        }
    }
}

struct BuildAllClueEntryView: View {
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
        VStack (spacing: 25) {
            HStack {
                Text("\(buildVM.moneySections[buildVM.editingClueIndex])")
                    .font(formatter.font(.bold, fontSize: .jumbo))
                    .foregroundColor(formatter.color(.secondaryAccent))
                Spacer()
            }
            
            VStack (spacing: 30) {
                VStack (spacing: 2) {
                    ZStack (alignment: .leading) {
                        if clueString.isEmpty {
                            Text("Clue")
                                .font(formatter.font(.regularItalic, fontSize: .semiLarge))
                                .foregroundColor(formatter.color(.lowContrastWhite))
                        }
                        MultilineTextField("", text: $clueString) {
                            category.clues[buildVM.editingClueIndex] = clueString
                        }
                        .accentColor(formatter.color(.highContrastWhite))
                        .offset(x: -5)
                    }
                    
                    Rectangle()
                        .fill(formatter.color(.highContrastWhite))
                        .frame(maxWidth: .infinity)
                        .frame(height: 2)
                        .offset(y: -3)
                }
                VStack (spacing: 4) {
                    ZStack (alignment: .leading) {
                        if responseString.isEmpty {
                            Text("Response")
                                .font(formatter.font(.regularItalic, fontSize: .semiLarge))
                                .foregroundColor(formatter.color(.lowContrastWhite))
                        }
                        TextField("", text: $responseString, onEditingChanged: { editingChanged in
                            category.clues[buildVM.editingClueIndex] = clueString
                            category.responses[buildVM.editingClueIndex] = responseString
                        })
                        .accentColor(formatter.color(.secondaryAccent))
                        .font(formatter.font(.regular, fontSize: .semiLarge))
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
                            .font(formatter.font(fontSize: .mediumLarge))
                            .foregroundColor(formatter.color(.secondaryAccent))
                            .opacity(canShowPreview ? 1 : 0.4)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(30)
        .background(formatter.color(.primaryFG))
        .cornerRadius(10)
        .transaction { transaction in
            transaction.animation = nil
        }
        .onAppear {
            clueString = category.clues[buildVM.editingClueIndex]
            responseString = category.responses[buildVM.editingClueIndex]
        }
    }
}

struct BuildAllCluePreviewView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    @Binding var category: CustomSetCategory
    @Binding var clueString: String
    @Binding var responseString: String
    @Binding var isShowingCluePreview: Bool
    
    @State var isShowingResponse = false
    
    var body: some View {
        VStack (spacing: 10) {
            VStack (alignment: .leading, spacing: 0) {
                Text("\(category.name.uppercased()) for \(buildVM.moneySections[buildVM.editingClueIndex])")
                    .font(formatter.font(.regular, fontSize: .mediumLarge))
                    .id(category.name)
                    .frame(maxWidth: .infinity, maxHeight: 100)
                    .multilineTextAlignment(.center)
                    .background(formatter.color(.lowContrastWhite))
                Spacer(minLength: 15)
                VStack {
                    Text(clueString.uppercased())
                        .font(formatter.font(.bold, fontSize: .large))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .id(clueString)
                        .lineSpacing(3)
                        .padding(.horizontal, 25)
                        .padding(.bottom, isShowingResponse ? 5 : 0)
                    if isShowingResponse {
                        Text(responseString.uppercased())
                            .font(formatter.font(.bold, fontSize: .large))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                            .foregroundColor(formatter.color(.secondaryAccent))
                            .id(responseString)
                            .padding([.horizontal, .bottom], 25)
                    }
                }
                .padding(.horizontal, 25)
                Spacer(minLength: 0)
                HStack (alignment: .bottom) {
                    Button {
                        isShowingCluePreview.toggle()
                    } label: {
                        Text("Done previewing")
                            .font(formatter.font())
                            .foregroundColor(formatter.color(.secondaryAccent))
                            .padding()
                    }
                    Spacer()
                    Button {
                        isShowingResponse.toggle()
                    } label: {
                        Text(isShowingResponse ? "Hide Response" : "Show Response")
                            .font(formatter.font(fontSize: .regular))
                            .foregroundColor(formatter.color(isShowingResponse ? .primaryBG : .highContrastWhite))
                            .padding(25)
                            .frame(maxWidth: 230)
                            .background(isShowingResponse ? formatter.color(.highContrastWhite) : nil)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(formatter.color(.highContrastWhite), lineWidth: 2)
                            )
                    }
                }
                .padding()
            }
            .background(formatter.color(.primaryAccent))
            .cornerRadius(10)
        }
    }
}
