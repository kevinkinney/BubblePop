//
//  GameScene.swift
//  DotGame
//

import SpriteKit
import GameplayKit

protocol ScoreboardDisplayDelegate: class {
	func showScoreboard()
	func showHighScoreAlert(forScore score: Int)
}

class GameScene: SKScene, SKPhysicsContactDelegate {
	
	weak var scoreboardDisplayDelegate: ScoreboardDisplayDelegate?
	
	private var playButton: ButtonNode?
	private var pauseButton: ButtonNode?
	private var viewScoreboardButton: ButtonNode?
	
	private var scoreLabel: SKLabelNode?
	private var timerLabel: SKLabelNode?
	private var gameStatusLabel: SKLabelNode?
	private var endScoreLabel: SKLabelNode?
	
	private var slider: SKSpriteNode?
	private var sliderHandle: SKShapeNode?
	
	var currentScore = 0
	private var roundActive = false
	
	private var sliderPercentage: CGFloat = 0.5
	
	private var leftTurbulenceField: SKFieldNode?
	private var rightTurbulenceField: SKFieldNode?
	
	private let maxPointsForBubble = 10
	private let topPaddingForControls: CGFloat = 200
	
	private var bubbleGeneratorTimer: Timer?
	private var roundTimer: Timer?
	private let roundLength = 30
	private var timeRemaining = 30
	
	private let pauseButtonFontSize = 36
	private let playButtonFontSize = 48
	
	private var lastBubbleStartingPoint: CGPoint?
	
    override func didMove(to view: SKView) {
		physicsWorld.contactDelegate = self
		
        self.scoreLabel = self.childNode(withName: "//Score") as? SKLabelNode
		self.timerLabel = self.childNode(withName: "//Timer") as? SKLabelNode
		timerLabel?.text = "\(roundLength)"
		self.gameStatusLabel = self.childNode(withName: "//Game Status") as? SKLabelNode
		self.endScoreLabel = self.childNode(withName: "//Your Score") as? SKLabelNode
		endScoreLabel?.isHidden = true
		
		self.slider = self.childNode(withName: "//Slider") as? SKSpriteNode
		setupSlider()
		
		self.leftTurbulenceField = self.childNode(withName: "//Left Turbulence Field") as? SKFieldNode
		leftTurbulenceField?.smoothness = 1.0
		self.rightTurbulenceField = self.childNode(withName: "//Right Turbulence Field") as? SKFieldNode
		rightTurbulenceField?.smoothness = 1.0
		
		addBackgroundImage()
		setupScreenBoundaries()
		
		updateTurbulanceFieldIntensity()
		updateBubbleFrequency()
		updateGravity()
		
		setupButtons()
    }
	
	// MARK: - Setup functions
	
	func setupButtons() {
		// A custom class is used for the buttons so they cannot be included in the scene file and must be created in code.
		addPlayButton()
		addPauseButton()
		addScoreboardButton()
	}
	
	func addPauseButton() {
		guard self.pauseButton == nil else {
			return
		}
		guard let timerFrame = timerLabel?.frame else {
			// Unable to line the button up with the timer frame
			return
		}
		let buttonWidth: CGFloat = 170
		let buttonHeight: CGFloat = 60
		let pauseButton = ButtonNode(rect: CGRect(x: 0 - buttonWidth/2, y: 0 - buttonHeight/2, width: buttonWidth, height: buttonHeight),
									 cornerRadius: 15,
									 text: "Pause",
									 fontSize: pauseButtonFontSize)
		pauseButton.position = CGPoint(x: slider!.frame.origin.x + slider!.frame.width - buttonWidth/2,
									   y: timerFrame.origin.y + timerFrame.height/2)
		pauseButton.fillColor = #colorLiteral(red: 0.2561283727, green: 0.44698372, blue: 1, alpha: 1)
		pauseButton.isHidden = true
		self.pauseButton = pauseButton
		self.addChild(pauseButton)
	}
	
	func addPlayButton() {
		guard self.playButton == nil else {
			return
		}
		let sceneWidth = self.frame.size.width
		let buttonWidth: CGFloat = sceneWidth * 0.4
		let buttonHeight: CGFloat = 100.0
		
		let playButton = ButtonNode(rect: CGRect(x: 0 - buttonWidth/2, y: 0 - buttonHeight/2, width: buttonWidth, height: buttonHeight),
									cornerRadius: 25,
									text: "Play",
									fontSize: playButtonFontSize)
		playButton.position = CGPoint.zero
		playButton.fillColor = #colorLiteral(red: 0.2561283727, green: 0.44698372, blue: 1, alpha: 1)
		
		self.addChild(playButton)
		self.playButton = playButton
	}
	
	func addScoreboardButton() {
		guard self.viewScoreboardButton == nil else {
			return
		}
		let sceneWidth = self.frame.size.width
		let buttonWidth: CGFloat = sceneWidth * 0.5
		let buttonHeight: CGFloat = 70
		
		let viewScoreboardButton = ButtonNode(rect: CGRect(x: 0 - buttonWidth/2, y: -200 - buttonHeight/2, width: buttonWidth, height: buttonHeight),
									cornerRadius: 15,
									text: "View Leaderboard",
									fontSize: 36)
		viewScoreboardButton.position = CGPoint.zero
		viewScoreboardButton.fillColor = #colorLiteral(red: 0.2561283727, green: 0.44698372, blue: 1, alpha: 1)
		
		self.addChild(viewScoreboardButton)
		self.viewScoreboardButton = viewScoreboardButton
	}
	
	func addBackgroundImage() {
		let background = SKSpriteNode(imageNamed: "game_background")
		let scale = self.frame.size.width / background.size.width
		background.xScale = scale
		background.yScale = scale
		background.zPosition = -1.0
		background.position = CGPoint(x: 0, y: (background.frame.size.height - self.frame.size.height)/2)
		self.addChild(background)
	}
	
	func setupScreenBoundaries() {
		// Add "ground" at the bottom of the screen that the bubbles can contact with and pop against
		let ground = SKShapeNode(rect: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 1))
		ground.name = "Ground"
		ground.position = CGPoint(x: -self.frame.size.width/2, y: -self.frame.size.height/2)
		ground.physicsBody = SKPhysicsBody(rectangleOf: ground.frame.size, center: CGPoint(x: self.frame.size.width/2, y: 0))
		ground.physicsBody?.contactTestBitMask = 1
		ground.physicsBody?.isDynamic = false
		self.addChild(ground)
		
		// Add "sides" to the screen to keep the bubbles from floating off in random directions
		let leftWall = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 1, height: self.frame.size.height))
		leftWall.name = "Side"
		leftWall.position = CGPoint(x: -self.frame.size.width/2, y: -self.frame.size.height/2)
		leftWall.physicsBody = SKPhysicsBody(rectangleOf: leftWall.frame.size, center: CGPoint(x: 0, y: self.frame.size.height/2))
		leftWall.physicsBody?.contactTestBitMask = 1
		leftWall.physicsBody?.isDynamic = false
		self.addChild(leftWall)
		
		let rightWall = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 1, height: self.frame.size.height))
		rightWall.name = "Side"
		rightWall.position = CGPoint(x: self.frame.size.width/2, y: -self.frame.size.height/2)
		rightWall.physicsBody = SKPhysicsBody(rectangleOf: leftWall.frame.size, center: CGPoint(x: 0, y: self.frame.size.height/2))
		rightWall.physicsBody?.contactTestBitMask = 1
		rightWall.physicsBody?.isDynamic = false
		self.addChild(rightWall)
	}
	
	// MARK: - Gameplay functions
	
	func generateBubble() {
		let pointsForBubble = Int(arc4random_uniform(UInt32(maxPointsForBubble))) + 1
		
		// Calculate the correct radius for the bubble based on the points value for the bubble.
		// The minimumRadius and radiusMultiplier were picked based on what seemed like good
		// sizes for interacting with the bubbles on an iPhone.
		let minimumRadius: CGFloat = 20
		let radiusMultiplier: CGFloat = 8
		let radius: CGFloat = minimumRadius + CGFloat(maxPointsForBubble-pointsForBubble)*radiusMultiplier
		
		let startPoint = generateRandomStartingPointForBubble(withRadius: radius)
		lastBubbleStartingPoint = startPoint
		
		// Added an extra 10 to the radius here because a 10pt bubble was too small to effectively tap.
		// Increasing the minimimum bubble size improved gameplay significantly.
		let bubble = BubbleNode(withRadius: radius)
		bubble.value = pointsForBubble
		
		bubble.position = startPoint
		bubble.alpha = 0.0
		
		bubble.name = "Bubble"
		self.addChild(bubble)
		bubble.run(SKAction.fadeIn(withDuration: 0.2))
	}
	
	func generateRandomStartingPointForBubble(withRadius r: CGFloat) -> CGPoint {
		let startY = (self.size.height / 2) - (topPaddingForControls + r)
		var startX = CGFloat(arc4random_uniform(UInt32(self.size.width) - UInt32(r*2))) - (self.size.width/2 + r)
		
		// Force each bubble to start a minimum distance from the previous bubble.
		// This helps keep the game interesting and limits bubble collisions
		// when they blow around in the turbulence.
		if let lastStartingPointX = lastBubbleStartingPoint?.x {
			let minDistanceFromLastBubble: CGFloat = 150
			while startX > (lastStartingPointX - minDistanceFromLastBubble) &&
				startX < (lastStartingPointX + minDistanceFromLastBubble) {
				startX = CGFloat(arc4random_uniform(UInt32(self.size.width) - UInt32(r*2))) - (self.size.width/2 + r)
			}
		}
		
		let startPoint = CGPoint(x: startX, y: startY)
		return startPoint
	}
	
	// MARK: - Game Round Lifecycle Functions
	
	func startRound() {
		roundActive = true
		playButton?.isHidden = true
		pauseButton?.isHidden = false
		viewScoreboardButton?.isHidden = true
		gameStatusLabel?.isHidden = true
		endScoreLabel?.isHidden = true
		
		timeRemaining = roundLength
		currentScore = 0
		
		roundTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
			guard self.timeRemaining > 0 else {
				self.endRound()
				return
			}
			if self.roundActive {
				self.timeRemaining -= 1
				self.timerLabel?.text = "\(self.timeRemaining)"
			}
		}
	}
	
	func pauseRound() {
		roundActive = false
		popAllBubbles()
		pauseButton?.isHidden = true
		playButton?.isHidden = false
		
		gameStatusLabel?.isHidden = false
		gameStatusLabel?.text = "Round Paused"
		
		playButton?.updateText(to: "Resume", withFontSize: playButtonFontSize)
	}
	
	func resumeRound() {
		pauseButton?.isHidden = false
		playButton?.isHidden = true
		gameStatusLabel?.isHidden = true
		
		roundActive = true
	}
	
	func endRound() {
		if Scores.isTopScore(currentScore) {
			scoreboardDisplayDelegate?.showHighScoreAlert(forScore: currentScore)
		}
		
		roundActive = false
		roundTimer?.invalidate()
		playButton?.isHidden = false
		pauseButton?.isHidden = true
		viewScoreboardButton?.isHidden = false
		gameStatusLabel?.isHidden = false
		gameStatusLabel?.text = "Game Over"
		endScoreLabel?.isHidden = false
		endScoreLabel?.text = "Your Score: \(currentScore)"
		popAllBubbles()
		timeRemaining = roundLength
		timerLabel?.text = "\(self.timeRemaining)"
		playButton?.updateText(to: "Play Again", withFontSize: playButtonFontSize)
	}
	
	func popAllBubbles() {
		for node in self.children where node is BubbleNode {
			(node as! BubbleNode).pop()
		}
	}
	
	// MARK: - Point handling functions
	
	func getPositivePoints(forBubble bubble: BubbleNode) -> Int {
		return bubble.value
	}
	
	func getNegativePoints(forBubble bubble: BubbleNode) -> Int {
		return bubble.value - maxPointsForBubble - 1
	}
	
	func scorePoints(forBubble bubble: BubbleNode, isPositive positive: Bool = true) {
		guard !bubble.popped else {
			return
		}
		
		let value = positive ? getPositivePoints(forBubble: bubble) : getNegativePoints(forBubble: bubble)
		
		currentScore = max(0, (currentScore + value))
		scoreLabel?.text = "\(currentScore)"
		
		// Create a label to show the points gained or lost when the bubble popped
		let prefix = positive ? "+" : ""
		let pointsNode = SKLabelNode(text: "\(prefix)\(value)")
		pointsNode.fontName = "Helvetica Neue"
		pointsNode.fontSize = CGFloat(26 + abs(value)*4) // Increase the font size for increased bubble value
		pointsNode.fontColor = positive ? #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) : #colorLiteral(red: 0.7753013959, green: 0, blue: 0.02176896839, alpha: 1)
		pointsNode.alpha = 0.0
		
		// Position the points label to the left or right of the bubble based on what side of the screen it is on
		let positionX = (bubble.position.x < 0) ?
			(bubble.position.x + bubble.frame.width/2) :
			(bubble.position.x - bubble.frame.width/2)
		let positionY = bubble.position.y + bubble.frame.height/2
		pointsNode.position = CGPoint(x: positionX, y: positionY)
		
		self.addChild(pointsNode)
		
		// Show the points for a short period of time fading it in and out
		pointsNode.run(SKAction.fadeIn(withDuration: 0.2))
		Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { (timer) in
			pointsNode.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
		}
		
		bubble.pop()
	}
	
	// MARK: - Slider functions
	
	func updateSlider(forTouch touch: UITouch) {
		guard let slider = self.slider,
			let sliderHandle = self.sliderHandle,
			nodes(at: touch.location(in: self)).contains(slider) else {
				return
		}
		
		// Verify that the exact location of the touch is inside the slider's frame
		let x = touch.location(in: slider).x
		guard abs(x) < slider.frame.width/2 else {
			return
		}
		
		sliderPercentage = (x + (slider.frame.width / 2.0)) / slider.frame.width // between 0 and 1
		
		// Update the physics properties to reflect the slider change
		updateTurbulanceFieldIntensity()
		updateBubbleFrequency()
		updateGravity()
		
		sliderHandle.position = CGPoint(x: x, y: sliderHandle.position.y)
	}
	
	func setupSlider() {
		guard self.sliderHandle == nil else {
			return
		}
		let handle = SKShapeNode(circleOfRadius: 15.0)
		handle.fillColor = #colorLiteral(red: 0.2561283727, green: 0.44698372, blue: 1, alpha: 1)
		handle.position = CGPoint.zero
		self.sliderHandle = handle
		slider?.addChild(handle)
	}
	
	func updateBubbleFrequency() {
		bubbleGeneratorTimer?.invalidate()
		let timeInterval = TimeInterval(1.25 - (sliderPercentage * 0.85)) // Bubbles every 0.4 to 1.25 seconds
		bubbleGeneratorTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { timer in
			if self.roundActive {
				self.generateBubble()
			}
		}
	}
	
	func updateTurbulanceFieldIntensity() {
		let maxTurbulenceSpeed: CGFloat = 0.7
		let maxTurbulenceStrength: CGFloat = 0.5
		leftTurbulenceField?.animationSpeed = Float(sliderPercentage * maxTurbulenceSpeed)
		leftTurbulenceField?.strength = Float(sliderPercentage * maxTurbulenceStrength)
		rightTurbulenceField?.animationSpeed = Float(sliderPercentage * maxTurbulenceSpeed)
		rightTurbulenceField?.strength = Float(sliderPercentage * maxTurbulenceStrength)
	}
	
	func updateGravity() {
		let earthsGravity = -9.8
		let dy = earthsGravity + Double(5.0*(1.0-sliderPercentage))
		physicsWorld.gravity = CGVector(dx: 0.0, dy: dy)
	}
	
	// MARK: - Touch interaction functions
	
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		for t in touches {
			let nodes = self.nodes(at: t.location(in: self))
			if !nodes.isEmpty {
				for node in nodes {
					if let bubble = node as? BubbleNode {
						scorePoints(forBubble: bubble)
					} else if node.name == "Play" || node.name == "Play Again" {
						startRound()
					} else if node.name == "Pause"  {
						pauseRound()
					} else if node.name == "Resume" {
						resumeRound()
					} else if node.name == "View Leaderboard" {
						scoreboardDisplayDelegate?.showScoreboard()
					}
					updateSlider(forTouch: t)
				}
			}
		}
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else {
				return
		}
		updateSlider(forTouch: touch)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else {
			return
		}
		updateSlider(forTouch: touch)
    }
	
	// MARK: - SKPhysicsContactDelegate functions
	
	func didBegin(_ contact: SKPhysicsContact) {
		if let bubble = contact.bodyA.node as? BubbleNode,
			let otherNode = contact.bodyB.node {
			processContact(bubble: bubble, node: otherNode)
		}
		if let bubble = contact.bodyB.node as? BubbleNode,
			let otherNode = contact.bodyA.node {
			processContact(bubble: bubble, node: otherNode)
		}
	}
	
	func processContact(bubble: BubbleNode, node: SKNode) {
		switch node.name {
		case "Side":
			// In this case nothing needs to be done, the bubble will just bounce off the side
			break
		case "Ground":
			// In this case points should be removed for the bubble hitting the ground without being popped
			self.scorePoints(forBubble: bubble, isPositive: false)
		default:
			// Default behavior (e.g., bubbles hitting each other) is to pop the bubble without scoring any points
			bubble.pop()
		}
	}
}
