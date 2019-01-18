//
//  BubbleNode.swift
//  DotGame
//

import SpriteKit
import GameplayKit

class BubbleNode: SKSpriteNode {
	
	var value = 1
	
	private var frames: [SKTexture] = []
	private var playBubblePop: SKAction = SKAction()
	private(set) public var popped = false
	
	public convenience init(withRadius r: CGFloat) {
		let animationAtlas = SKTextureAtlas(named: "bubble_pop")
		var frames: [SKTexture] = []
		let numImages = animationAtlas.textureNames.count
		for i in 1...numImages {
			let textureName = "bubble_pop_frame_0\(i)"
			frames.append(animationAtlas.textureNamed(textureName))
		}
		let firstFrameTexture = frames[0]
		self.init(texture: firstFrameTexture, size: CGSize(width: r*2, height: r*2))
		
		let physicsBody = SKPhysicsBody(texture: firstFrameTexture, size: CGSize(width: r*2, height: r*2))
		physicsBody.affectedByGravity = true
		physicsBody.contactTestBitMask = 1
		physicsBody.allowsRotation = false
		physicsBody.density = 0.01 // Simulate the low density of a bubble
		physicsBody.linearDamping = 1.0 // Simulate the high friction of the air on the bubble
		
		self.physicsBody = physicsBody
		self.frames = frames
		self.playBubblePop = SKAction.playSoundFileNamed("pop.mp3", waitForCompletion: false)
	}
	
	func pop() {
		guard popped == false else {
			return
		}
		popped = true
		physicsBody?.contactTestBitMask = 0
		value = 0
		physicsBody?.isDynamic = false // Stop the bubble from bouncing and interacting
		run(SKAction.sequence([playBubblePop,
							   SKAction.animate(with: frames, timePerFrame: 0.05, resize: false, restore: true),
							   SKAction.removeFromParent()]))
	}
}
