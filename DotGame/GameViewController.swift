//
//  GameViewController.swift
//  DotGame
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController, ScoreboardDisplayDelegate {
	
	private var lastHighScoreRank: Int?
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            if let scene = SKScene(fileNamed: "GameScene") as? GameScene {
                scene.scaleMode = .aspectFill
				scene.scoreboardDisplayDelegate = self
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
        }
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		lastHighScoreRank = nil
	}

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Set the scoreboard to highlight the high score that was just achieved.
		guard let scoreboardController = segue.destination as? ScoreboardController,
			let lastHighScoreRank = self.lastHighScoreRank else {
				return
		}
		scoreboardController.highScoreRankToHighlight = lastHighScoreRank
		self.lastHighScoreRank = nil
	}
	
	func showScoreboard() {
		self.performSegue(withIdentifier: "showScoreboardSegue", sender: self)
	}
	
	func showHighScoreAlert(forScore score: Int) {
		let alert = UIAlertController(title: "New High Score!", message: "Your Score: \(score)", preferredStyle: .alert)
		alert.addTextField { textField in
			textField.autocapitalizationType = .words
			textField.placeholder = "Enter your name"
		}
		alert.addAction(UIAlertAction(title: "Done", style: .default) { action in
			let name = alert.textFields![0].text!
			self.lastHighScoreRank = Scores.recordTopScore(score, forUser: name)
			self.showScoreboard()
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		self.present(alert, animated: true, completion: nil)
	}
}
