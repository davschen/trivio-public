//
//  MobileBuildTrivioView.swift
//  Trivio!
//
//  Created by David Chen on 7/24/21.
//

import Foundation
import SwiftUI

struct MobileBuildFinalTrivioView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    
    @State var categoryName = ""
    @State var finalClue = ""
    @State var finalResponse = ""
    
    init() {
        UIScrollView.appearance().keyboardDismissMode = .onDrag
    }
    
    var body: some View {
        ScrollView (.vertical, showsIndicators: false) {
            VStack (alignment: .leading, spacing: 15) {
                VStack (alignment: .leading, spacing: 3) {
                    Text("Category name")
                        .font(formatter.font(fontSize: .medium))
                        .padding(.top, 20)
                    ZStack (alignment: .leading) {
                        if categoryName.isEmpty {
                            Text("Untitled")
                                .font(formatter.font(.boldItalic, fontSize: .medium))
                                .foregroundColor(formatter.color(.lowContrastWhite))
                        }
                        TextField("", text: $categoryName) { editingChanged in
                            buildVM.currCustomSet.finalCat = categoryName
                        }
                    }
                    .font(formatter.font(.bold, fontSize: .medium))
                    .padding(20)
                    .background(formatter.color(.primaryAccent))
                    .cornerRadius(5)
                    .onAppear {
                        categoryName = buildVM.currCustomSet.finalCat
                        finalClue = buildVM.currCustomSet.finalClue
                        finalResponse = buildVM.currCustomSet.finalResponse
                    }
                }
                VStack (spacing: 2) {
                    ZStack (alignment: .leading) {
                        if finalClue.isEmpty {
                            Text("Clue")
                                .font(formatter.font(.boldItalic))
                                .foregroundColor(formatter.color(.lowContrastWhite))
                        }
                        HStack (alignment: .bottom) {
                            MobileMultilineTextField("", text: $finalClue) {
                                buildVM.currCustomSet.finalClue = finalClue
                            }
                            .accentColor(formatter.color(.highContrastWhite))
                            .offset(x: -5)
                            Button {
                                buildVM.currCustomSet.finalClue = finalClue
                                formatter.resignKeyboard()
                            } label: {
                                Text("Done")
                                    .font(formatter.font(.regular))
                                    .padding(.vertical, 7)
                            }
                            .opacity(buildVM.currCustomSet.finalClue == finalClue ? 0 : 1)
                        }
                    }
                    
                    Rectangle()
                        .fill(formatter.color(.highContrastWhite))
                        .frame(maxWidth: .infinity)
                        .frame(height: 2)
                        .offset(y: -5)
                }
                VStack (spacing: 4) {
                    ZStack (alignment: .leading) {
                        if finalResponse.isEmpty {
                            Text("Response")
                                .font(formatter.font(.boldItalic))
                                .foregroundColor(formatter.color(.lowContrastWhite))
                        }
                        HStack {
                            TextField("", text: $finalResponse, onEditingChanged: { editingChanged in
                                // insurance
                                buildVM.currCustomSet.finalClue = finalClue
                                buildVM.currCustomSet.finalResponse = finalResponse
                            })
                            .accentColor(formatter.color(.secondaryAccent))
                            .font(formatter.font(.bold))
                            .foregroundColor(formatter.color(.secondaryAccent))
                            Button {
                                buildVM.currCustomSet.finalResponse = finalResponse
                                formatter.resignKeyboard()
                            } label: {
                                Text("Done")
                                    .font(formatter.font(.regular))
                                    .padding(.vertical, 5)
                            }
                            .opacity(buildVM.currCustomSet.finalResponse == finalResponse ? 0 : 1)
                        }
                    }
                    Rectangle()
                        .fill(formatter.color(.secondaryAccent))
                        .frame(maxWidth: .infinity)
                        .frame(height: 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .resignKeyboardOnDragGesture()
    }
}

