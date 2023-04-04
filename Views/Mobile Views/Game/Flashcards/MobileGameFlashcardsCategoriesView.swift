//
//  MobileGameFlashcardsCategoriesView.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 1/15/23.
//

import Foundation
import SwiftUI

struct MobileGameFlashcardsCategoriesView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @State var currCategoryIndex: Int = 0
    @State var topCardClueIndex: Int = 0
    @State var bottomCardClueIndex: Int = 0
    @State var isPresentingFlashcardsView: Bool = false
    @State var cardIndicesToStudy = [Int]()
    @State var didSelectCardIndex = false
    @State var selectedCardIndex = 0
    @State var studyingClueSide = true
    
    var roundCategoryInfo: (Int, Int) {
        return gamesVM.getReadjustedCategoryIndex(flashcardClue: gamesVM.flashcardClues2D[currCategoryIndex].first!)
    }
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    currCategoryIndex == 0 ? () : (currCategoryIndex -= 1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(formatter.iconFont())
                        .foregroundColor(formatter.color(currCategoryIndex == 0 ? .lowContrastWhite : .highContrastWhite))
                }
                Spacer()
                Text("\(gamesVM.customSet.hasTwoRounds ? "Round \(roundCategoryInfo.0), " : "")Category \(roundCategoryInfo.1 + 1)")
                    .font(formatter.font(fontSize: .mediumLarge))
                Spacer()
                Button {
                    currCategoryIndex == (gamesVM.flashcardClues2D.count - 1) ? () : (currCategoryIndex += 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(formatter.iconFont())
                        .foregroundColor(formatter.color(currCategoryIndex == (gamesVM.flashcardClues2D.count - 1) ? .lowContrastWhite : .highContrastWhite))
                }
            }
            .padding([.horizontal, .top], 15)
            TabView(selection: $currCategoryIndex) {
                ForEach(gamesVM.flashcardClues2D.indices, id: \.self) { categoryIndex in
                    MobileGameFlashcardsSingleCategoryView(
                        isPresentingFlashcardsView: $isPresentingFlashcardsView,
                        didSelectCardIndex: $didSelectCardIndex,
                        selectedCardIndex: $selectedCardIndex,
                        categoryIndex: categoryIndex,
                        startPresentingFlashcardsView: {
                            startPresentingFlashcardsView(categoryIndex: categoryIndex, didSelectCardIndex: didSelectCardIndex, selectedCardIndex: selectedCardIndex)
                        }
                    )
                    .padding(.horizontal)
                }
            }
            .background(formatter.color(.primaryBG))
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(formatter.color(.primaryBG))
        .fullScreenCover(isPresented: $isPresentingFlashcardsView) {
            MobileFlashcardsView(currCategoryIndex: $currCategoryIndex, topCardClueIndex: $topCardClueIndex, bottomCardClueIndex: $bottomCardClueIndex, cardIndicesToStudy: $cardIndicesToStudy, studyingClueSide: $studyingClueSide)
        }
    }
    
    func startPresentingFlashcardsView(categoryIndex: Int, didSelectCardIndex: Bool = false, selectedCardIndex: Int = 0) {
        formatter.hapticFeedback(style: .light)
        cardIndicesToStudy = gamesVM.getCardIndicesToStudy(categoryIndex: categoryIndex)
        if didSelectCardIndex {
            if cardIndicesToStudy.contains(where: {$0 == selectedCardIndex}) {
                cardIndicesToStudy.removeAll(where: {$0 == selectedCardIndex})
            }
            cardIndicesToStudy.insert(selectedCardIndex, at: 0)
        }
        if cardIndicesToStudy.count > 0 {
            topCardClueIndex = cardIndicesToStudy.first!
            bottomCardClueIndex = cardIndicesToStudy.count > 1 ? cardIndicesToStudy[1] : topCardClueIndex
        }
        isPresentingFlashcardsView.toggle()
        self.didSelectCardIndex = false
        self.selectedCardIndex = 0
    }
}

struct MobileGameFlashcardsSingleCategoryView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @Binding var isPresentingFlashcardsView: Bool
    @Binding var didSelectCardIndex: Bool
    @Binding var selectedCardIndex: Int
    
    let categoryIndex: Int
    
    var startPresentingFlashcardsView: () -> ()
    var categoryIsMastered: Bool {
        return gamesVM.flashcardClues2D[categoryIndex].allSatisfy({$0.isLearned})
    }
    
    var body: some View {
        VStack {
            HStack (spacing: 1) {
                ForEach(gamesVM.flashcardClues2D[categoryIndex].indices, id: \.self) { cardIndex in
                    VStack (spacing: 1) {
                        Button {
                            didSelectCardIndex = true
                            selectedCardIndex = cardIndex
                            startPresentingFlashcardsView()
                        } label: {
                            Text("\(gamesVM.flashcardClues2D[categoryIndex][cardIndex].pointValue)")
                                .font(formatter.font(fontSize: .mediumLarge))
                                .foregroundColor(formatter.color(.secondaryAccent))
                                .padding(.top, 16)
                                .padding(.bottom, 13)
                                .frame(maxWidth: .infinity)
                                .background(formatter.color(.primaryAccent))
                        }
                        Rectangle()
                            .frame(maxWidth: .infinity, maxHeight: 4)
                            .foregroundColor(formatter.color(gamesVM.flashcardClues2D[categoryIndex][cardIndex].isLearned ? .green : .red))
                    }
                }
            }
            Spacer()
            ZStack {
                VStack (spacing: 5) {
                    Text(gamesVM.getCardCategoryName(adjustedCategoryIndex: categoryIndex).uppercased())
                        .font(formatter.font(fontSize: .extraLarge))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    HStack (spacing: 0) {
                        Text("\(gamesVM.flashcardClues2D[categoryIndex].filter({$0.isLearned}).count) ")
                            .font(formatter.font(fontSize: .medium))
                            .foregroundColor(formatter.color(.green))
                        Text("cards mastered")
                            .font(formatter.font(.regular, fontSize: .medium))
                    }
                    HStack (spacing: 0) {
                        Text("\(gamesVM.flashcardClues2D[categoryIndex].filter({!$0.isLearned}).count) ")
                            .font(formatter.font(fontSize: .medium))
                            .foregroundColor(formatter.color(.red))
                        Text("cards left to go")
                            .font(formatter.font(.regular, fontSize: .medium))
                    }
                }
                .padding(.bottom, 20)
                
                VStack {
                    if !categoryIsMastered {
                        VStack (spacing: 3) {
                            Text("Tap anywhere to study")
                            Text("this swipe deck")
                        }
                        .font(formatter.font(.regularItalic, fontSize: .small))
                        .foregroundColor(formatter.color(.lowContrastWhite))
                        .multilineTextAlignment(.center)
                        .padding(20)
                    }
                    Spacer()
                    if categoryIsMastered {
                        Button {
                            gamesVM.resetFlashcardCategory(adjustedCategoryIndex: categoryIndex)
                            startPresentingFlashcardsView()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(formatter.iconFont())
                                Text("Restart")
                                    .font(formatter.font(fontSize: .medium))
                            }
                            .foregroundColor(formatter.color(.primaryBG))
                            .frame(width: 180, height: 50)
                            .background(formatter.color(.highContrastWhite))
                            .clipShape(Capsule())
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            Spacer()
        }
        .background(formatter.color(categoryIsMastered ? .secondaryFG : .primaryFG))
        .cornerRadius(20)
        .offset(y: isPresentingFlashcardsView ? 50 : 0)
        .animation(.easeInOut(duration: 0.1))
        .onTapGesture {
            categoryIsMastered ? () : startPresentingFlashcardsView()
        }
    }
}

struct MobileFlashcardsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @Binding var currCategoryIndex: Int
    @Binding var topCardClueIndex: Int
    @Binding var bottomCardClueIndex: Int
    @Binding var cardIndicesToStudy: [Int]
    @Binding var studyingClueSide: Bool
    
    @State var isShowingResponse = false
    @State var xOffset: CGFloat = 0
    @State var xOffsetIsAnimating = false
    
    var bottomClue: FlashcardClue {
        return gamesVM.flashcardClues2D[currCategoryIndex][bottomCardClueIndex]
    }
    var topClue: FlashcardClue {
        return gamesVM.flashcardClues2D[currCategoryIndex][topCardClueIndex]
    }
    var readjustedCardIndex: (Int, Int) {
        return gamesVM.getReadjustedCategoryIndex(flashcardClue: topClue)
    }
    var relevantClues: [[String]] {
        return readjustedCardIndex.0 == 1 ? gamesVM.tidyCustomSet.round1Clues : gamesVM.tidyCustomSet.round2Clues
    }
    
    var bgColor: Color {
        if (abs(xOffset) == 0) {
            return formatter.color(isShowingResponse ? .primaryBG : .primaryFG)
        } else if xOffset < 0 {
            return formatter.color(.red).opacity(-xOffset / 75)
        } else {
            return formatter.color(.green).opacity(xOffset / 75)
        }
    }
    
    var body: some View {
        ZStack {
            bgColor
                .edgesIgnoringSafeArea(.all)
            MobileSingleFlashcardView(xOffset: $xOffset, isShowingResponse: $isShowingResponse, studyingClueSide: $studyingClueSide, flashcardClue: bottomClue, isTopCard: false)
                .opacity((cardIndicesToStudy.count <= 1 && !xOffsetIsAnimating) ? 0 : 1)
            MobileSingleFlashcardView(xOffset: $xOffset, isShowingResponse: $isShowingResponse, studyingClueSide: $studyingClueSide, flashcardClue: topClue, isTopCard: true)
                .opacity(xOffsetIsAnimating ? 0 : 1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(xOffsetIsAnimating ? .clear : bgColor, lineWidth: 2))
                .shadow(color: .black.opacity(xOffset == 0 ? 0 : 0.3), radius: 10)
                .offset(x: xOffset * 2)
                .rotationEffect(Angle(degrees: (xOffset / 20.0)))
                .gesture(DragGesture()
                    .onChanged({ dragGesture in
                        if abs(dragGesture.translation.width) > 0 {
                            xOffset = dragGesture.translation.width
                        }
                    })
                    .onEnded({ _ in
                        if abs(xOffset) >= 75 && (cardIndicesToStudy.count > 0) {
                            if xOffset > 0 {
                                xOffset = 1000
                                gamesVM.markCardAsCorrect(flashcardClue: topClue)
                                formatter.hapticFeedback(style: .heavy)
                                cardIndicesToStudy.removeFirst()
                                if cardIndicesToStudy.isEmpty {
                                    presentationMode.wrappedValue.dismiss()
                                    return
                                }
                            } else {
                                xOffset = -1000
                                gamesVM.markCardAsIncorrect(flashcardClue: topClue)
                                formatter.hapticFeedback(style: .soft, intensity: .strong)
                                cardIndicesToStudy.append(cardIndicesToStudy.removeFirst())
                            }
                            xOffsetIsAnimating = true
                            isShowingResponse = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                topCardClueIndex = cardIndicesToStudy.first!
                                xOffset = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                xOffsetIsAnimating = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                if cardIndicesToStudy.count > 1 {
                                    bottomCardClueIndex = cardIndicesToStudy[1]
                                }
                            }
                        } else {
                            xOffset = 0
                        }
                    })
                )
        }
        .animation(.easeInOut(duration: 0.2))
    }
}

struct MobileSingleFlashcardView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel

    @Binding var xOffset: CGFloat
    @Binding var isShowingResponse: Bool
    @Binding var studyingClueSide: Bool
    
    var flashcardClue: FlashcardClue
    var isTopCard: Bool
    var readjustedCardIndex: (Int, Int) {
        return gamesVM.getReadjustedCategoryIndex(flashcardClue: flashcardClue)
    }
    var relevantCategoryNames: [String] {
        return readjustedCardIndex.0 == 1 ? gamesVM.tidyCustomSet.round1Cats : gamesVM.tidyCustomSet.round2Cats
    }
    
    var body: some View {
        ZStack {
            formatter.color((isShowingResponse && isTopCard) ? .primaryBG : .primaryFG)
                .edgesIgnoringSafeArea(.all)
            VStack (spacing: 15) {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                    }
                    Spacer()
                    VStack (spacing: 5) {
                        Text(relevantCategoryNames[readjustedCardIndex.1])
                            .multilineTextAlignment(.center)
                        Text("for \(flashcardClue.pointValue)")
                        Text("Attempts: \(flashcardClue.numAttempts)")
                            .font(formatter.font(.regular, fontSize: .regular))
                    }
                    .font(formatter.font(fontSize: .medium))
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                        formatter.setAlertSettings(alertAction: {(studyingClueSide = true)}, alertType: .settings, alertTitle: "Flashcard display mode", alertSubtitle: "Select the side you'd like to study", hasCancel: true, actionLabel: "Study clue side", hasSecondaryAction: true, secondaryAction: {(studyingClueSide = false)}, secondaryActionLabel: "Study response side")
                    } label: {
                        Image(systemName: "gear")
                            .font(.system(size: 20))
                    }
                }
                .padding(.vertical, 25)
                Text(studyingClueSide ? flashcardClue.clueString : flashcardClue.responseString)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(formatter.fontFloat(.regular, sizeFloat: 26))
                    .lineSpacing(5)
                
                if isShowingResponse && isTopCard {
                    Text(studyingClueSide ? flashcardClue.responseString : flashcardClue.clueString)
                        .font(formatter.fontFloat(.regular, sizeFloat: 26))
                        .foregroundColor(formatter.color(.secondaryAccent))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
                Button {
                    formatter.hapticFeedback(style: .soft, intensity: .normal)
                    isShowingResponse.toggle()
                } label: {
                    Text(isShowingResponse ? "Hide Response" : "Show Response")
                        .foregroundColor(formatter.color(isShowingResponse ? .primaryBG : (isTopCard ? .highContrastWhite : .lowContrastWhite)))
                        .font(formatter.font())
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(isShowingResponse ? formatter.color(isTopCard ? .highContrastWhite : .lowContrastWhite) : nil)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(formatter.color(isTopCard ? .highContrastWhite : .lowContrastWhite), lineWidth: 2))
                }
                .padding(.bottom)
            }
            .padding(.horizontal)
        }
        .foregroundColor(formatter.color(isTopCard ? .highContrastWhite : .lowContrastWhite))
        .contentShape(Rectangle())
        .cornerRadius(20)
        .onTapGesture {
            formatter.hapticFeedback(style: .soft, intensity: .normal)
            isShowingResponse.toggle()
        }
    }
}
