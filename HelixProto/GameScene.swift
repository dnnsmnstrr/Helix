//
//  GameScene.swift
//  HelixProto
//
//  Created by Alexander Schülke on 10.02.18.
//  Copyright © 2018 Alexander Schülke. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    private var background = SKSpriteNode(imageNamed: "background")
    // The parts represent the individual pieces of the DNA. Each part can hold a tone.
    private var parts: [SKSpriteNode] = []
    // The bases that are available for the user on the right of the screen
    private var bases: [Int:SKSpriteNode] = [:]
    // All the bases that were assigned to the DNA
    private var basesOnDna: [SKSpriteNode] = []
    
    // For dragging bases
    private let panRecognizer = UIPanGestureRecognizer()
    // Currently moved base
    private var currentBase: SKSpriteNode?
    private var originalBasePosition: CGPoint?
    
    
    override init(size: CGSize) {
        // Create the one side of the DNA string.
        for _ in 0...12 {
            let part = SKSpriteNode(imageNamed: "stridepart")
            part.zPosition = 0
            part.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            parts.append(part)
        }
        
        // Create the 4 bases available for the user
        bases[0] = SKSpriteNode(imageNamed: "base1")
        bases[1] = SKSpriteNode(imageNamed: "base2")
        bases[2] = SKSpriteNode(imageNamed: "base3")
        bases[3] = SKSpriteNode(imageNamed: "base4")
        
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Initial setup
    override func didMove(to view: SKView) {
        // Create background
        backgroundColor = SKColor.black
        background.zPosition = -1
        addChild(background)
        
        // Manage background
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5) // default
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.size = self.frame.size
        
        // Build the dna string, part by part
        for (index, part) in parts.enumerated() {
            addChild(part)
            part.position = CGPoint(x: self.frame.size.width / 2.8, y: self.frame.size.height - part.frame.size.height * CGFloat(index))
            
        }
        
        // Position the 4 bases
        for (index, base) in bases {
            addChild(base)
            base.anchorPoint = CGPoint(x: 0, y: 0.5)
            base.zPosition = 1
            let overallHeight = base.frame.size.height * CGFloat(bases.count)
            base.position = CGPoint(x: self.frame.size.width / 1.68, y: (self.frame.size.height / 2) + (overallHeight / 2) - (base.frame.size.height * 2 * CGFloat(index)))
        }
        
        panRecognizer.addTarget(self, action: #selector(GameScene.drag(_:)))
        self.view!.addGestureRecognizer(panRecognizer)
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
    }
    
    // Gets called by the UIPanGestureRecognizer.
    // Describes the behaviour while being dragged and what should happen at the end of a drag.
    @objc func drag(_ gestureRecognizer: UIPanGestureRecognizer) {
        // While dragging update base's position to current finger position.
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            
            let translation = gestureRecognizer.translation(in: self.view)
            
            guard let currentBase = currentBase else {
                return
            }
            currentBase.position = CGPoint(x: currentBase.position.x + translation.x*2, y: currentBase.position.y - translation.y*2)
            gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
        }
            // End of drag, decide wether to snap to the stride or return to original position
        else if gestureRecognizer.state == .ended {
            if let currentBase = currentBase {
                if let nearest = getNearestPart() {
                    if nearest.position.x.distance(to: currentBase.position.x) < 100 {
                        currentBase.position = CGPoint(x: nearest.position.x + currentBase.frame.width / 24, y: nearest.position.y)
                        basesOnDna.append(currentBase)
                        // Get next base of same type
                        reloadSample(for: currentBase)
                        return
                    }
                }
                // Move bases back to original position, because it could not snap with any DNA slot
                if let originalBasePosition = self.originalBasePosition {
                    let snapBack = SKAction.move(to: originalBasePosition, duration: 0.3)
                    currentBase.run(snapBack)
                }
            }
        }
    }
    
    // In this method it is set which base the user wants to move right now,
    // which means to set 'currentBase', so the drag method can work properly.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let nodes = self.nodes(at: location)
            if nodes.first is SKSpriteNode {
                let node = nodes.first as! SKSpriteNode
                if bases.values.contains(node) || basesOnDna.contains(node){
                    originalBasePosition = node.position
                    currentBase = node
                } else {
                    currentBase = nil
                }
            } else {
                currentBase = nil
            }
        }
    }
    
    // This method checks all DNA parts to return the nearest one to the currentBase
    private func getNearestPart() -> SKSpriteNode? {
        if let currentBase = currentBase {
            var nearest: (part: SKSpriteNode, distance: CGFloat) = (parts.first!, parts.first!.position.distance(point: currentBase.position))
            
            for part in parts {
                let distance = part.position.distance(point: currentBase.position)
                if distance < nearest.distance {
                    nearest = (part, distance)
                }
            }
            return nearest.part
        }
        return nil
    }
    
    // Recreates a base for the user, so one base can be assigned to the DNA multiple times
    private func reloadSample(for base: SKSpriteNode) {
        if let index = bases.values.index(of: base) {
            let position = bases.keys[index]
            bases.removeValue(forKey: position)
            var newBase: SKSpriteNode
            switch position {
            case 0:
                newBase = SKSpriteNode(imageNamed: "base1")
            case 1:
                newBase = SKSpriteNode(imageNamed: "base2")
            case 2:
                newBase = SKSpriteNode(imageNamed: "base3")
            case 3:
                newBase = SKSpriteNode(imageNamed: "base4")
            default:
                newBase = SKSpriteNode(imageNamed: "base1")
            }
            bases[position] = newBase
            addChild(newBase)
            newBase.anchorPoint = CGPoint(x: 0, y: 0.5)
            newBase.zPosition = 1
            let overallHeight = newBase.frame.size.height * CGFloat(bases.count)
            newBase.position = CGPoint(x: self.frame.size.width, y: (self.frame.size.height / 2) + (overallHeight / 2) - (newBase.frame.size.height * 2 * CGFloat(position)))
            let finalPos = CGPoint(x: self.frame.size.width / 1.68, y: (self.frame.size.height / 2) + (overallHeight / 2) - (newBase.frame.size.height * 2 * CGFloat(position)))
            
            let appear = SKAction.move(to: finalPos, duration: 0.5)
            newBase.run(appear)
        }
    }
    
}

