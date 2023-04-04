//
//  GamesViewModel+FinalTrivio.swift
//  Trivio! (iOS)
//
//  Created by David Chen on 7/17/21.
//

import Foundation

extension GamesViewModel {
    func finalTrivioFinishedAction() {
        switch finalTrivioStage {
        case .makeWager:
            finalTrivioStage = .submitAnswer
        case .submitAnswer:
            finalTrivioStage = .revealResponse
        case .revealResponse:
            finalTrivioStage = .podium
        default:
            print("hi")
        }
    }
}

enum FinalTrivioStage {
    case notBegun, makeWager, submitAnswer, revealResponse, podium
}
