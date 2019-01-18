//
//  Scores.swift
//  DotGame
//

import Foundation

struct HighScore: Codable {
	let score: Int
	let name: String
}

class Scores {
	
	private static let scoresKey = "game_scores"
	private static let maxEntries = 10
	
	static func isTopScore(_ score: Int) -> Bool {
		let scores = getTopScores()
		guard scores.count >= maxEntries else {
			return true
		}
		let lowestTopScore = scores[scores.count-1]
		return lowestTopScore.score < score
	}
	
	static func recordTopScore(_ score: Int, forUser name: String) -> Int {
		do {
			var topScores = getTopScores()
			let highScore = HighScore(score: score, name: name)
			topScores.append(highScore)
			topScores.sort { (scoreOne, scoreTwo) -> Bool in
				return scoreOne.score >= scoreTwo.score
			}
			if topScores.count > maxEntries {
				topScores.removeLast()
			}
			let rank = 1 + topScores.index(where: { $0.score == highScore.score } )!
			let encoder = JSONEncoder()
			let encodedScores = try topScores.compactMap { try encoder.encode($0) }
			UserDefaults.standard.set(encodedScores, forKey: scoresKey)
			return rank
		} catch {
			NSLog("Error saving top score")
			return -1
		}
	}
	
	static func getTopScores() -> [HighScore] {
		do {
			let scoresData = UserDefaults.standard.array(forKey: scoresKey) as? [Data] ?? [Data]()
			let decoder = JSONDecoder()
			let scores = try scoresData.compactMap { try decoder.decode(HighScore.self, from: $0) }
			return scores
		} catch {
			NSLog("Error getting top score")
			return []
		}
	}
}
