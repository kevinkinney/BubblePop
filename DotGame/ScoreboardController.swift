//
//  ScoreboardController.swift
//  DotGame
//

import Foundation
import UIKit

class ScoreboardController: UITableViewController {
	
	var highScoreRankToHighlight: Int?
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	@IBAction func dismissScoreboard() {
		dismiss(animated: true, completion: nil)
	}
	
	// MARK: - UITableViewDelegate functions
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1 + Scores.getTopScores().count
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 44
	}
	
	// MARK: UITableViewDataSource functions
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "GameScoreTableViewCell", for: indexPath) as! GameScoreTableViewCell
		let scores = Scores.getTopScores()
		if indexPath.row == 0 {
			cell.rankLabel.text = "Rank"
			cell.rankLabel.font = UIFont.boldSystemFont(ofSize: 17)
			cell.nameLabel.text = "Name"
			cell.nameLabel.font = UIFont.boldSystemFont(ofSize: 17)
			cell.scoreLabel.text = "Score"
			cell.scoreLabel.font = UIFont.boldSystemFont(ofSize: 17)
		} else {
			let row = indexPath.row
			cell.rankLabel.text = "\(row)"
			if row-1 < scores.count {
				cell.nameLabel.text = scores[row-1].name
				cell.scoreLabel.text = "\(scores[row-1].score)"
			} else {
				cell.nameLabel.text = ""
				cell.scoreLabel.text = ""
			}
			if row == highScoreRankToHighlight {
				cell.backgroundColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
			}
		}
		
		return cell
	}
}
