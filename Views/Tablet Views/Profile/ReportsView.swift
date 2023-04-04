//
//  ReportsView.swift
//  Trivio
//
//  Created by David Chen on 3/7/21.
//

import Foundation
import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var reportVM: ReportViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
     
    var body: some View {
        ZStack {
            VStack (alignment: .leading, spacing: 20) {
                Text("Past Games")
                    .font(formatter.font(fontSize: .extraLarge))
                    .foregroundColor(formatter.color(.highContrastWhite))
                if reportVM.allGameReports.count == 0 {
                    EmptyListView(label: "You haven't played any games yet. Once you do, they will show up here with detailed in-game reports")
                        .padding(.vertical, 30)
                } else {
                    ScrollView (.horizontal, showsIndicators: false) {
                        HStack (spacing: 15) {
                            ForEach(reportVM.allGameReports, id: \.self) { game in
                                ReportPreviewView(game: game)
                            }
                        }
                    }
                    if !self.reportVM.selectedGameID.isEmpty {
                        AnalysisView()
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ReportPreviewView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var reportVM: ReportViewModel
    @EnvironmentObject var gamesVM: GamesViewModel
    
    let game: Report
    
    var body: some View {
        let gameID = game.id ?? "NID"
        VStack (alignment: .leading, spacing: 15) {
            HStack (spacing: 15) {
                Text("\(reportVM.dateFormatter.string(from: game.date))")
                    .font(formatter.font(.bold))
                RoundedRectangle(cornerRadius: 2).frame(width: 1, height: 15)
                Text("\(reportVM.timeFormatter.string(from: game.date))")
                    .font(formatter.font(.regular))
            }
            .foregroundColor(formatter.color(.highContrastWhite))
            ScrollView (.horizontal) {
                HStack (spacing: 15) {
                    ForEach(game.getNames(), id: \.self) { name in
                        Text(name.uppercased())
                            .font(formatter.font())
                            .foregroundColor(formatter.color(.secondaryAccent))
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .padding(20)
        .background(formatter.color(reportVM.selectedGameID == gameID ? .secondaryFG : .primaryFG))
        .cornerRadius(10)
        .onTapGesture {
            if reportVM.selectedGameID != gameID {
                self.reportVM.getGameInfo(id: gameID)
            }
        }
        .onLongPressGesture {
            self.reportVM.delete(id: gameID)
        }
    }
}

struct AnalysisView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var reportVM: ReportViewModel
    
    var body: some View {
        if let game = reportVM.currentReport {
            ScrollView (.vertical, showsIndicators: false) {
                VStack (alignment: .leading, spacing: 15) {
                    // Includes "Game Dynamics" text, play button, and contestants scrollview
                    AnalysisInfoView(game: game)
                    // chart magic
                    HStack (spacing: 0) {
                        // y axis
                        VStack (alignment: .trailing) {
                            ForEach(self.reportVM.yAxis.reversed(), id: \.self) { yVal in
                                Text("\(yVal)")
                                    .font(formatter.font(fontSize: .micro))
                                    .frame(maxHeight: .infinity, alignment: .leading)
                                    .minimumScaleFactor(0.1)
                            }
                            .frame(maxHeight: .infinity)
                        }
                        .frame(width: 40)
                        .padding(.bottom, 10)
                        .padding(.trailing, 5)
                        VStack (spacing: 0) {
                            ChartView(min: reportVM.min, max: reportVM.max)
                            // x axis
                            HStack {
                                ForEach(self.reportVM.xAxis, id: \.self) { xVal in
                                    Text("\(xVal)")
                                        .font(formatter.font(fontSize: .micro))
                                        .frame(maxWidth: .infinity)
                                        .minimumScaleFactor(0.1)
                                }
                            }
                            .frame(height: 15)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 5)
                        }
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.4)
                    
                    // "game played" label with set title
                    Button(action: {
                        gamesVM.menuChoice = .game
                        if game.episode_played.contains("game_id") {
                            gamesVM.getEpisodeData(gameID: game.episode_played)
                        } else {
                            gamesVM.getCustomData(setID: game.episode_played)
                        }
                    }, label: {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 15))
                            Text("\(reportVM.getGameName(from: game.episode_played))")
                                .font(formatter.font())
                        }
                        .foregroundColor(formatter.color(.primaryFG))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(formatter.color(.highContrastWhite))
                        .cornerRadius(5)
                    })
                    
                    HStack {
                        if let set = reportVM.currentSet {
                            Text("Clues in Set: \(set.numclues)")
                                .padding(10)
                                .padding(.horizontal, 30)
                                .background(formatter.color(.secondaryFG))
                                .cornerRadius(5)
                        }
                        Spacer()
                    }
                    .font(formatter.font())
                }
            }
            .padding(20)
            .background(formatter.color(.primaryFG))
            .cornerRadius(10)
        }
    }
}

struct ChartView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var reportVM: ReportViewModel
    @State var on = true
    
    var min: CGFloat
    var max: CGFloat
    var newMax: CGFloat {
        return max - min
    }
    var newMin: CGFloat {
        return min - min
    }
    
    var body: some View {
        VStack {
            ZStack (alignment: .topLeading) {
                if let currentGame = reportVM.currentReport {
                    formatter.color(.secondaryFG)
                    ForEach(currentGame.team_ids, id: \.self) { id in
                        if let scores = reportVM.scores[id] {
                            LineGraph(dataPoints: scores.map { CGFloat($0) }, min: min, max: max)
                                .stroke(style: StrokeStyle(lineCap: .round, lineJoin: .round))
                                .stroke(ColorMap().getColor(color: currentGame.color_id_map[id]!), lineWidth: 2)
                                .opacity((reportVM.selectedID == id || reportVM.selectedID.isEmpty) ? 1 : 0.25)
                        }
                    }
                }
            }
            .cornerRadius(5)
        }
    }
}

struct AnalysisInfoView: View {
    @EnvironmentObject var formatter: MasterHandler
    @EnvironmentObject var gamesVM: GamesViewModel
    @EnvironmentObject var reportVM: ReportViewModel
    
    var game: Report
    
    var body: some View {
        VStack (alignment: .leading, spacing: 15) {
            Text("Game Dynamics")
                .font(formatter.font(fontSize: .large))
                .foregroundColor(formatter.color(.highContrastWhite))
            
            // contestants/teams that played
            ScrollView (.horizontal, showsIndicators: false) {
                HStack (spacing: 15) {
                    ForEach(game.team_ids, id: \.self) { id in
                        if let name = game.name_id_map[id], let color = game.color_id_map[id], let score = reportVM.scores[id]?.last {
                            VStack (alignment: .leading, spacing: 5) {
                                HStack {
                                    Circle()
                                        .foregroundColor(ColorMap().getColor(color: color))
                                        .frame(width: 15)
                                    Text(name)
                                        .font(formatter.font(fontSize: .mediumLarge))
                                        .foregroundColor(formatter.color(.highContrastWhite))
                                }
                                Text("$\(score)")
                                    .font(formatter.font(fontSize: .mediumLarge))
                                    .foregroundColor(formatter.color(.highContrastWhite))
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(formatter.color(.primaryFG))
                                    .cornerRadius(5)
                            }
                            .padding()
                            .frame(width: 200)
                            .background(RoundedRectangle(cornerRadius: 5).stroke(formatter.color(.highContrastWhite), lineWidth: reportVM.selectedID == id ? 10 : 0))
                            .background(formatter.color(.secondaryFG))
                            .cornerRadius(formatter.cornerRadius(5))
                            .onTapGesture {
                                reportVM.selectedID = (reportVM.selectedID == id) ? "" : id
                            }
                        }
                    }
                }
            }
        }
    }
}

struct LineGraph: Shape {
    var dataPoints: [CGFloat]
    var min: CGFloat
    var max: CGFloat
    var newMax: CGFloat {
        return max - min
    }
    var newMin: CGFloat {
        return min - min
    }
    
    func path(in rect: CGRect) -> Path {
        func point(at ix: Int) -> CGPoint {
            let point = dataPoints[ix] - min
            let x = rect.width * CGFloat(ix) / CGFloat(dataPoints.count - 1)
            let y = ((newMax-point) / (newMax - newMin)) * rect.height
            return CGPoint(x: x, y: y)
        }

        return Path { p in
            guard dataPoints.count > 1 else { return }
            let start = dataPoints[0] - min
            p.move(to: CGPoint(x: 0, y: ((newMax-start) / (newMax - newMin)) * rect.height))
            for idx in dataPoints.indices {
                p.addLine(to: point(at: idx))
            }
        }
    }
}
