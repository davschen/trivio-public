//
//  GamePreviewView.swift
//  Trivio!
//
//  Created by David Chen on 12/7/22.
//

import Foundation
import SwiftUI

struct GamePreviewView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @State var playingMode: PlayingMode = .game
    @State var headerString = "Set Preview"
    
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
            VStack {
                GamePlayingModeSelectorView(playingMode: $playingMode, headerString: $headerString)
                if playingMode == .game {
                    GameGameshowPreviewView()
                } else {
                    GameFlashcardsCategoriesView()
                }
            }
        }
        .withBackButton()
        .navigationBarTitle(headerString, displayMode: .inline)
    }
}

struct GamePlayingModeSelectorView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    
    @Binding var playingMode: PlayingMode
    @Binding var headerString: String
    
    var body: some View {
        HStack (spacing: 7) {
            Button {
                formatter.hapticFeedback(style: .medium, intensity: .weak)
                headerString = "Set Preview"
                playingMode = .game
            } label: {
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .font(formatter.iconFont(.small))
                    Text("Game")
                        .font(formatter.font())
                }
                .padding(.horizontal, 20)
                .frame(height: 40)
                .background(formatter.color(.primaryFG))
                .cornerRadius(5)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(formatter.color(.highContrastWhite), lineWidth: playingMode == .game ? 1 : 0))
            }
            
            Button {
                formatter.hapticFeedback(style: .medium, intensity: .weak)
                playingMode = .flashcards
                headerString = gamesVM.customSet.title
                gamesVM.flashcardClues2D = gamesVM.generateFlashcards2D()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.fill")
                        .font(formatter.iconFont(.small))
                    Text("Flashcards")
                        .font(formatter.font())
                }
                .padding(.horizontal, 20)
                .frame(height: 40)
                .background(formatter.color(.primaryFG))
                .cornerRadius(5)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(formatter.color(.highContrastWhite), lineWidth: playingMode == .flashcards ? 1 : 0))
            }
            Spacer()
        }
        .padding([.top, .horizontal])
    }
}

struct GameGameshowPreviewView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var isPresentingGameView = false
    @State var isPresentingTrivioLiveView = false
    @State var isPresentingBuildView = false
    
    init() {
        Theme.navigationBarColors(
            background: UIColor(MasterHandler().color(.primaryFG)),
            titleColor: UIColor(MasterHandler().color(.highContrastWhite))
        )
    }
    
    var isSetMine: Bool {
        guard let myUID = profileVM.myUID else { return false }
        return gamesVM.customSet.userID == myUID
    }
    
    var bgColor: Color {
        return formatter.color(.primaryBG)
    }
    
    var body: some View {
        // Supa neat, supa tight, everyone be like GamePreviewView
        ZStack {
            formatter.color(.primaryBG)
                .edgesIgnoringSafeArea(.all)
            ZStack (alignment: .bottom) {
                ScrollView (.vertical, showsIndicators: false) {
                    VStack (alignment: .leading, spacing: 25) {
                        // Settings header
                        GameSettingsHeaderView(isPresentingGameView: $isPresentingGameView, isPresentingBuildView: $isPresentingBuildView)
                            .padding([.top, .horizontal], 25)
                            .padding(.top, 15)
                        
                        GameSettingsCategoryPreviewView()
                            .padding(.vertical)
                            .padding(.horizontal, 25)
                        
                        // Contestants View
                        GameSettingsContestantsView()
                        
                        // Game Settings
                        GameSettingsCardView()
                            .padding(.horizontal, 25)
                    }
                }
            }
            .fullScreenCover(isPresented: $isPresentingGameView) {
                GameBoardView()
            }
            
            NavigationLink(isActive: $isPresentingBuildView, destination: {
                BuildView()
            }, label: { EmptyView() })
            .isDetailLink(false)
            .hidden()
//
//            NavigationLink(isActive: $isPresentingTrivioLiveView, destination: {
//                MobileTrivioLivePreviewView()
//            }, label: { EmptyView() })
//            .isDetailLink(false)
//            .hidden()
        }
        .withBackButton()
    }
}

struct GameSettingsHeaderView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @Binding var isPresentingGameView: Bool
    @Binding var isPresentingBuildView: Bool
    
    @State var trivioLiveViewActive = false
    @State var userViewActive = false
    
    var isSetMine: Bool {
        guard let myUID = profileVM.myUID else { return false }
        return gamesVM.customSet.userID == myUID
    }
    
    var body: some View {
        ZStack {
            VStack (alignment: .leading, spacing: 15) {
                Text("\(gamesVM.customSet.title)")
                    .font(formatter.font(fontSize: .large))
                    .id(gamesVM.customSet.title)
                HStack (spacing: 0) {
                    Text("Created by ")
                    Button {
                        exploreVM.pullAllFromUser(withID: gamesVM.customSet.userID)
                        userViewActive.toggle()
                    } label: {
                        Text(exploreVM.getUsernameFromUserID(userID: gamesVM.customSet.userID))
                            .underline()
                    }
                    Text(" on \(gamesVM.dateFormatter.string(from: gamesVM.customSet.dateCreated))")
                }
                .id(gamesVM.customSet.title)
                if !gamesVM.customSet.description.isEmpty {
                    Text(gamesVM.customSet.description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(formatter.color(.mediumContrastWhite))
                        .lineSpacing(3)
                }
                GameSettingsPromptButtonsView(isPresentingGameView: $isPresentingGameView, isPresentingTrivioLiveView: $trivioLiveViewActive, isPresentingBuildView: $isPresentingBuildView)
            }
            .font(formatter.font(.regular, fontSize: .medium))
            NavigationLink(destination: UserView()
                .navigationBarTitle("Profile", displayMode: .inline),
                           isActive: $userViewActive,
                           label: { EmptyView() }).hidden()
        }
    }
}

struct GameSettingsCategoryPreviewView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel

    var body: some View {
        VStack (alignment: .leading, spacing: 3) {
            HStack {
                Text("Round 1")
                Text("(\(gamesVM.tidyCustomSet.round1Cats.count) categories)")
                    .font(formatter.font(.regularItalic, fontSize: .regular))
            }
            CategoryPreviewView(categories: gamesVM.tidyCustomSet.round1Cats)
                .padding(.bottom, 15)
            if gamesVM.customSet.hasTwoRounds {
                HStack {
                    Text("Round 2")
                    Text("(\(gamesVM.tidyCustomSet.round2Cats.count) categories)")
                        .font(formatter.font(.regularItalic, fontSize: .regular))
                }
                CategoryPreviewView(categories: gamesVM.tidyCustomSet.round2Cats)
            }
        }
        .id(UUID().uuidString)
    }
}

struct GameSettingsContestantsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State var editingName = ""
    @State var editingColor = "blue"
    @State var editingID: String? = nil
    
    var body: some View {
        VStack (alignment: .leading, spacing: 10) {
            HStack {
                Text("Contestants")
                    .font(formatter.font(fontSize: .semiLarge))
                Button {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    participantsVM.teamToEdit = Empty().team
                    participantsVM.teamToEdit.index = participantsVM.savedTeams.count
                    editingName.removeAll()
                    editingColor.removeAll()
                    
                    participantsVM.savedTeams.append(participantsVM.teamToEdit)
                    editingID = participantsVM.teamToEdit.id
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                }
                Spacer()
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 7)
            
            VStack (spacing: 10) {
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .foregroundColor(formatter.color(.lowContrastWhite))
                    .padding(.leading, 25)
                // Contestants currently in the game float to the top
                ForEach(participantsVM.teams) { team in
                    VStack (alignment: .leading, spacing: 14) {
                        ContestantsCellView(editingID: $editingID, editingName: $editingName, editingColor: $editingColor, team: team)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if team.id == editingID { return }
                                formatter.hapticFeedback(style: .rigid, intensity: .weak)
                                if gamesVM.gameInProgress() && team.score > 0 {
                                    formatter.setAlertSettings(alertAction: {
                                        participantsVM.removeTeam(index: participantsVM.getIndexByID(id: team.id))
                                    }, alertTitle: "Remove \(team.name)?", alertSubtitle: "\(team.name) has \(team.score) points right now. If you remove a contestant during a game, their score will not be saved.", hasCancel: true, actionLabel: "Yes, remove \(team.name)")
                                } else {
                                    participantsVM.removeTeam(index: participantsVM.getIndexByID(id: team.id))
                                }
                            }
                        
                        Rectangle()
                            .frame(maxWidth: .infinity)
                            .frame(height: 1)
                            .foregroundColor(formatter.color(.lowContrastWhite))
                            .padding(.leading, 25)
                    }
                    .animation(.easeInOut(duration: 0.2))
                }
                ForEach(participantsVM.savedTeams) { team in
                    if !participantsVM.teams.contains(team) {
                        VStack (alignment: .leading, spacing: 14) {
                            ContestantsCellView(editingID: $editingID, editingName: $editingName, editingColor: $editingColor, team: team)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if team.id == editingID { return }
                                    formatter.hapticFeedback(style: .rigid, intensity: .weak)
                                    participantsVM.addTeam(id: team.id, name: team.name, members: team.members, score: 0, color: team.color)
                                }
                            Rectangle()
                                .frame(maxWidth: .infinity)
                                .frame(height: 1)
                                .foregroundColor(formatter.color(.lowContrastWhite))
                                .padding(.leading, 25)
                        }
                        .animation(.easeInOut(duration: 0.2))
                    }
                }
            }
        }
    }
}

struct ContestantsCellView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @Binding var editingID: String?
    @Binding var editingName: String
    @Binding var editingColor: String
    
    let team: Team
    
    var body: some View {
        HStack {
            ZStack (alignment: .leading) {
                EditContestantsCellView(editingID: $editingID, editingName: $editingName, editingColor: $editingColor, team: team)
                if team.id != editingID {
                    HStack (spacing: 7) {
                        Image(systemName: participantsVM.teams.contains(team) ? "circle.fill" : "circle")
                        Circle()
                            .foregroundColor(ColorMap().getColor(color: team.color))
                            .frame(width: 8, height: 8)
                        HStack {
                            Text(team.name)
                                .font(formatter.font(participantsVM.teams.contains(team) ? .bold : .regular))
                            if profileVM.myUID == team.id {
                                Text("(me)")
                                    .font(formatter.font(.regularItalic))
                            }
                        }
                        .transition(.identity)
                        .id(team.id)
                    }
                }
            }
            Spacer()
            Button {
                formatter.hapticFeedback(style: .soft, intensity: .strong)
                if editingID == team.id {
                    // "Done"
                    if editingName.isEmpty && team.name.isEmpty {
                        // The nevermind case
                        if let lastIndex = participantsVM.savedTeams.indices.last {
                            participantsVM.savedTeams.remove(at: lastIndex)
                            editingID = nil
                            participantsVM.teamToEdit = Empty().team
                        }
                        return
                    }
                    participantsVM.teamToEdit.id = editingID!
                    participantsVM.teamToEdit.name = editingName
                    participantsVM.teamToEdit.color = editingColor
                    participantsVM.editTeamInDB(team: participantsVM.teamToEdit)
                    team.name.isEmpty ? participantsVM.addTeam(team: participantsVM.teamToEdit) : ()
                    editingID = nil
                    participantsVM.teamToEdit = Empty().team
                } else {
                    // "Edit"
                    editingID = team.id
                    editingName = team.name
                    editingColor = team.color
                    editingID = team.id
                }
            } label: {
                Text(editingID == team.id ? "Done" : "Edit")
                    .font(formatter.font(.regular))
                    .frame(minWidth: 100, alignment: .trailing)
            }
        }
        .frame(height: 30)
        .foregroundColor(formatter.color(participantsVM.teams.contains(team) ? .secondaryAccent : .highContrastWhite))
        .padding(.horizontal, 25)
    }
}

struct EditContestantsCellView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @Binding var editingID: String?
    @Binding var editingName: String
    @Binding var editingColor: String
    
    let team: Team
    
    var body: some View {
        if editingID == team.id {
            HStack (spacing: 7) {
                Button {
                    if team.name.isEmpty {
                        editingID = nil
                        participantsVM.teamToEdit = Empty().team
                        if let lastIndex = participantsVM.savedTeams.indices.last {
                            participantsVM.savedTeams.remove(at: lastIndex)
                        }
                        return
                    }
                    formatter.setAlertSettings(alertAction: {
                        formatter.hapticFeedback(style: .soft)
                        participantsVM.removeTeamFromFirestore(id: team.id)
                    }, alertTitle: "Remove \(team.name) from saved teams?", alertSubtitle: "You cannot undo this action", hasCancel: true, actionLabel: "Yes, remove \(team.name)")
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 24))
                        .foregroundColor(formatter.color(.red))
                        .offset(y: -4)
                }
                Circle()
                    .foregroundColor(ColorMap().getColor(color: editingColor))
                    .frame(width: 8, height: 8)
                TextField("Aa", text: $editingName)
                    .font(formatter.font(.regular, fontSize: .medium))
                    .frame(height: 25)
                    .frame(maxWidth: 140)
                HStack (spacing: 4) {
                    ColorPickerView(teamColor: $editingColor, color: formatter.color(.blue), colorString: "blue")
                    ColorPickerView(teamColor: $editingColor, color: formatter.color(.purple), colorString: "purple")
                    ColorPickerView(teamColor: $editingColor, color: formatter.color(.green), colorString: "green")
                    ColorPickerView(teamColor: $editingColor, color: formatter.color(.yellow), colorString: "yellow")
                    ColorPickerView(teamColor: $editingColor, color: formatter.color(.orange), colorString: "orange")
                    ColorPickerView(teamColor: $editingColor, color: formatter.color(.red), colorString: "red")
                }
                .frame(width: 250)
            }
        }
    }
}

struct ColorPickerView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @Binding var teamColor: String
    
    @State var color: Color
    @State var colorString: String
    
    var isSettingsPicker = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .opacity(teamColor == colorString ? 1 : 0.2)
                .onTapGesture {
                    formatter.hapticFeedback(style: .rigid, intensity: .weak)
                    teamColor = colorString
                }
        }
        .frame(height: 40)
    }
}

// MARK: - Game Settings Card

struct GameSettingsCardView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @State var editingSettingName = ""
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            Text("Game Settings")
                .font(formatter.font(.bold, fontSize: .semiLarge))
                .padding(.horizontal).padding(.bottom, 10)
            ThinDividerView()
            // Disabling clue appearance option on tablet for version Cherry 3.0
//            GameSettingsClueAppearanceView(editingSettingName: $editingSettingName)
//            ThinDividerView()
            GameSettingsVoiceTypeView(editingSettingName: $editingSettingName)
            ThinDividerView()
            GameSettingsVoiceSpeedView(editingSettingName: $editingSettingName)
            ThinDividerView()
            GameSettingsGenderView(editingSettingName: $editingSettingName)
            ThinDividerView()
        }
        .padding(.vertical, 25)
        .background(formatter.color(.secondaryFG))
        .cornerRadius(10)
        .padding(.bottom, 20)
        .animation(.easeIn(duration: 0.15))
    }
    
    func ThinDividerView() -> some View {
        return Rectangle()
            .frame(maxWidth: .infinity)
            .frame(height: 1)
            .foregroundColor(formatter.color(.lowContrastWhite))
    }
}

struct GameSettingsClueAppearanceView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var editingSettingName: String
    
    @State var selectedAppearance: ClueAppearance = ClueAppearance(rawValue: UserDefaults.standard.string(forKey: "clueAppearance") ?? "classic") ?? .classic
    
    let settingName = "Clue Appearance"
    
    var body: some View {
        VStack {
            HStack {
                Text(settingName)
                Spacer()
                HStack (spacing: 5) {
                    Text("\(selectedAppearance == .modern ? "Modern" : "Classic")")
                    Image(systemName: "chevron.down")
                        .rotationEffect(Angle(degrees: editingSettingName == settingName ? 180 : 0))
                }
                .font(formatter.font(.regular))
                .foregroundColor(formatter.color(.lowContrastWhite))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                formatter.hapticFeedback(style: .rigid, intensity: .weak)
                editingSettingName = editingSettingName == settingName ? "" : settingName
            }
            
            if editingSettingName == settingName {
                HStack (spacing: 7) {
                    Spacer()
                    GameSettingsClueAppearancePickerView(selectedAppearance: $selectedAppearance, clueAppearance: .modern, appearanceString: "Modern")
                    GameSettingsClueAppearancePickerView(selectedAppearance: $selectedAppearance, clueAppearance: .classic, appearanceString: "Classic")
                }
            }
        }
        .padding()
    }
}

struct GameSettingsClueAppearancePickerView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var selectedAppearance: ClueAppearance
    
    let clueAppearance: ClueAppearance
    let appearanceString: String
    let defaults = UserDefaults.standard
    
    var body: some View {
        Text("\(appearanceString)")
            .font(formatter.font(.regular, fontSize: .regular))
            .padding(15).padding(.horizontal, 10)
            .foregroundColor(formatter.color(selectedAppearance == clueAppearance ? .primaryFG : .highContrastWhite))
            .background(formatter.color(selectedAppearance == clueAppearance ? .highContrastWhite : .primaryFG))
            .clipShape(Capsule())
            .onTapGesture {
                formatter.hapticFeedback(style: .soft, intensity: .weak)
                UserDefaults.standard.set(clueAppearance.rawValue, forKey: "clueAppearance")
                NotificationCenter.default.post(name: NSNotification.Name("ClueAppearanceChange"), object: nil)
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: NSNotification.Name("ClueAppearanceChange"), object: nil, queue: .main) { (_) in
                    let selectedAppearance = ClueAppearance(rawValue: UserDefaults.standard.string(forKey: "clueAppearance") ?? "classic") ?? .classic
                    self.selectedAppearance = selectedAppearance
                }
            }
    }
}

struct GameSettingsVoiceTypeView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var editingSettingName: String

    @State var selectedLanguage: SpeechLanguage = SpeechLanguage(rawValue: UserDefaults.standard.string(forKey: "speechLanguage") ?? "americanEnglish") ?? .britishEnglish
    
    let settingName = "Reading Voice"
    
    var emphasisColor: ColorType = .primaryFG
    
    var body: some View {
        VStack {
            HStack {
                Text(settingName)
                Spacer()
                HStack (spacing: 5) {
                    Text("\(selectedLanguage == .americanEnglish ? "American" : "British") English")
                    Image(systemName: "chevron.down")
                        .rotationEffect(Angle(degrees: editingSettingName == settingName ? 180 : 0))
                }
                .font(formatter.font(.regular))
                .foregroundColor(formatter.color(.lowContrastWhite))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                formatter.hapticFeedback(style: .rigid, intensity: .weak)
                editingSettingName = editingSettingName == settingName ? "" : settingName
            }
            if editingSettingName == settingName {
                HStack (spacing: 7) {
                    Spacer()
                    GameSettingsLanguagePickerView(selectedLanguage: $selectedLanguage, speechLanguage: .americanEnglish, languageString: "American English")
                    GameSettingsLanguagePickerView(selectedLanguage: $selectedLanguage, speechLanguage: .britishEnglish, languageString: "British English")
                }
            }
        }
        .padding()
    }
}

struct GameSettingsLanguagePickerView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var selectedLanguage: SpeechLanguage
    
    let speechLanguage: SpeechLanguage
    let languageString: String
    let defaults = UserDefaults.standard
    
    var body: some View {
        Text("\(languageString)")
            .font(formatter.font(.regular, fontSize: .regular))
            .padding(15).padding(.horizontal, 10)
            .foregroundColor(formatter.color(selectedLanguage == speechLanguage ? .primaryFG : .highContrastWhite))
            .background(formatter.color(selectedLanguage == speechLanguage ? .highContrastWhite : .primaryFG))
            .clipShape(Capsule())
            .onTapGesture {
                formatter.hapticFeedback(style: .soft, intensity: .weak)
                UserDefaults.standard.set(speechLanguage.rawValue, forKey: "speechLanguage")
                NotificationCenter.default.post(name: NSNotification.Name("SpeechLanguageChange"), object: nil)
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: NSNotification.Name("SpeechLanguageChange"), object: nil, queue: .main) { (_) in
                    let selectedLanguage = SpeechLanguage(rawValue: UserDefaults.standard.string(forKey: "speechLanguage") ?? "britishEnglish") ?? .britishEnglish
                    self.selectedLanguage = selectedLanguage
                }
            }
    }
}


struct GameSettingsVoiceSpeedView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var editingSettingName: String
    
    @State var selectedSpeed: Float = UserDefaults.standard.value(forKey: "speechSpeed") as? Float ?? 0.5
    
    let settingName = "Reading Speed"
    
    var emphasisColor: ColorType = .primaryFG
    var floatSpeedToString: [Float:String] {
        return [
            0.45 : "Slow",
            0.5 : "Medium",
            0.55 : "Fast",
        ]
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(settingName)
                Spacer()
                HStack (spacing: 5) {
                    Text(floatSpeedToString[selectedSpeed] ?? "Medium")
                    Image(systemName: "chevron.down")
                        .rotationEffect(Angle(degrees: editingSettingName == settingName ? 180 : 0))
                }
                .font(formatter.font(.regular))
                .foregroundColor(formatter.color(.lowContrastWhite))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                formatter.hapticFeedback(style: .rigid, intensity: .weak)
                editingSettingName = editingSettingName == settingName ? "" : settingName
            }
            if editingSettingName == settingName {
                HStack (spacing: 7) {
                    Spacer()
                    GameSettingsSpeedPickerView(selectedSpeed: $selectedSpeed, speechSpeed: .slow, speedString: "Slow")
                    GameSettingsSpeedPickerView(selectedSpeed: $selectedSpeed, speechSpeed: .medium, speedString: "Medium")
                    GameSettingsSpeedPickerView(selectedSpeed: $selectedSpeed, speechSpeed: .fast, speedString: "Fast")
                }
            }
        }
        .padding()
    }
}

struct GameSettingsGenderView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var editingSettingName: String
    
    @State var selectedGender: SpeechGender = SpeechGender(rawValue: UserDefaults.standard.string(forKey: "speechGender") ?? "male") ?? .male
    
    let settingName = "Narration Gender"
    
    var body: some View {
        VStack {
            HStack {
                Text(settingName)
                Spacer()
                HStack (spacing: 5) {
                    Text("\(selectedGender == .male ? "Male" : "Female")")
                    Image(systemName: "chevron.down")
                        .rotationEffect(Angle(degrees: editingSettingName == settingName ? 180 : 0))
                }
                .font(formatter.font(.regular))
                .foregroundColor(formatter.color(.lowContrastWhite))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                formatter.hapticFeedback(style: .rigid, intensity: .weak)
                editingSettingName = editingSettingName == settingName ? "" : settingName
            }
            if editingSettingName == settingName {
                HStack (spacing: 7) {
                    Spacer()
                    GameSettingsGenderPickerView(selectedGender: $selectedGender, speechGender: .male, genderString: "Male")
                    GameSettingsGenderPickerView(selectedGender: $selectedGender, speechGender: .female, genderString: "Female")
                }
            }
        }
        .padding()
    }
}

struct GameSettingsGenderPickerView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var selectedGender: SpeechGender
    
    let speechGender: SpeechGender
    let genderString: String
    let defaults = UserDefaults.standard
    
    var body: some View {
        Text("\(genderString)")
            .font(formatter.font(.regular, fontSize: .regular))
            .padding(15).padding(.horizontal, 10)
            .foregroundColor(formatter.color(selectedGender == speechGender ? .primaryFG : .highContrastWhite))
            .background(formatter.color(selectedGender == speechGender ? .highContrastWhite : .primaryFG))
            .clipShape(Capsule())
            .onTapGesture {
                formatter.hapticFeedback(style: .soft, intensity: .weak)
                UserDefaults.standard.set(speechGender.rawValue, forKey: "speechGender")
                NotificationCenter.default.post(name: NSNotification.Name("SpeechGenderChange"), object: nil)
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: NSNotification.Name("SpeechGenderChange"), object: nil, queue: .main) { (_) in
                    let selectedGender = SpeechGender(rawValue: UserDefaults.standard.string(forKey: "speechGender") ?? "male") ?? .male
                    self.selectedGender = selectedGender
                }
            }
    }
}

struct GameSettingsSpeedPickerView: View {
    @EnvironmentObject var formatter: MasterHandler
    
    @Binding var selectedSpeed: Float
    
    let speechSpeed: SpeechSpeed
    let speedString: String
    let defaults = UserDefaults.standard
    
    var emphasisColor: ColorType = .primaryFG
    
    var body: some View {
        Text("\(speedString)")
            .font(formatter.font(.regular, fontSize: .regular))
            .padding(15).padding(.horizontal, 10)
            .foregroundColor(formatter.color(selectedSpeed == speechSpeed.rawValue ? .primaryFG : .highContrastWhite))
            .background(formatter.color(selectedSpeed == speechSpeed.rawValue ? .highContrastWhite : .primaryFG))
            .clipShape(Capsule())
            .onTapGesture {
                formatter.hapticFeedback(style: .soft, intensity: .weak)
                UserDefaults.standard.set(speechSpeed.rawValue, forKey: "speechSpeed")
                NotificationCenter.default.post(name: NSNotification.Name("SpeechSpeedChange"), object: nil)
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: NSNotification.Name("SpeechSpeedChange"), object: nil, queue: .main) { (_) in
                    let selectedSpeed = UserDefaults.standard.value(forKey: "speechSpeed") as? Float ?? 0.5
                    self.selectedSpeed = selectedSpeed
                }
            }
    }
}

struct GameSettingsPromptButtonsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var buildVM: BuildViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var participantsVM: ParticipantsViewModel
    
    @Binding var isPresentingGameView: Bool
    @Binding var isPresentingTrivioLiveView: Bool
    @Binding var isPresentingBuildView: Bool
    
    var gameIsPlayable: Bool {
        return participantsVM.teams.count > 0
    }
    
    var bgColor: Color {
        return formatter.color(.primaryBG)
    }
    
    var isSetMine: Bool {
        guard let myUID = profileVM.myUID else { return false }
        return gamesVM.customSet.userID == myUID
    }
    
    var body: some View {
        HStack {
            Button(action: {
                if gameIsPlayable {
                    isPresentingGameView.toggle()
                    gamesVM.gameSetupMode = .play
                    gamesVM.gameplayDisplay = .grid
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                }
            }, label: {
                Text("\(gamesVM.gameInProgress() ? "Resume Game" : "Play Game")")
                    .font(formatter.font(.boldItalic, fontSize: .regular))
                    .foregroundColor(formatter.color(.primaryFG))
                    .frame(height: 60)
                    .frame(maxWidth: 180)
                    .padding(.horizontal, 30)
                    .background(formatter.color(.highContrastWhite))
                    .opacity(gameIsPlayable ? 1 : 0.5)
                    .clipShape(Capsule())
            })
            if isSetMine {
                Button(action: {
                    formatter.hapticFeedback(style: .soft, intensity: .strong)
                    isPresentingBuildView.toggle()
                    buildVM.edit(customSet: gamesVM.customSet)
                }, label: {
                    Text("Edit")
                        .font(formatter.font(.boldItalic, fontSize: .regular))
                        .foregroundColor(formatter.color(.highContrastWhite))
                        .frame(height: 60)
                        .padding(.horizontal, 30)
                        .background(formatter.color(.primaryAccent))
                        .clipShape(Capsule())
                })
                Button(action: {
                    formatter.setAlertSettings(alertAction: {
                        buildVM.deleteSet(customSet: gamesVM.customSet)
                    }, alertTitle: "Are You Sure?", alertSubtitle: "You're about to delete your set named \"\(gamesVM.customSet.title)\" — deleting a set is irreversible.", hasCancel: true, actionLabel: "Yes, delete my set")
                }, label: {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                        .foregroundColor(formatter.color(.red))
                        .frame(height: 60)
                        .padding(.horizontal, 30)
                        .background(formatter.color(.primaryFG))
                        .clipShape(Capsule())
                })
            }
            
            // So sad, gotta leave this for now (12/7/22); will come back to it later
//            Button(action: {
//                isPresentingTrivioLiveView.toggle()
//                formatter.hapticFeedback(style: .soft, intensity: .strong)
//                gamesVM.createLiveGameDocument(hostUsername: profileVM.username, hostName: profileVM.name)
//            }, label: {
//                Text("Host this game live!")
//                    .font(formatter.font(.boldItalic, fontSize: .regular))
//                    .foregroundColor(formatter.color(.highContrastWhite))
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(formatter.color(.primaryAccent))
//                    .clipShape(Capsule())
//            })
        }
    }
}

