//
//  BubbleNode.swift
//  DotGame
//

import SpriteKit
import GameplayKit

class ButtonNode: SKShapeNode {
	
	private var buttonLabel: SKLabelNode!
	
	public convenience init(rect: CGRect, cornerRadius: CGFloat, text: String, fontSize: Int) {
		self.init(rect: rect, cornerRadius: cornerRadius)
		updateText(to: text, withFontSize: fontSize)
	}
	
	func updateText(to text: String, withFontSize fontSize: Int) {
		self.name = text
		self.buttonLabel?.removeFromParent()
		let buttonLabel = SKLabelNode(text: text)
		buttonLabel.fontName = "Helvetica Neue"
		buttonLabel.fontSize = CGFloat(fontSize)
		buttonLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
		buttonLabel.horizontalAlignmentMode = .center
		buttonLabel.verticalAlignmentMode = .center
		self.addChild(buttonLabel)
		self.buttonLabel = buttonLabel
	}
}
