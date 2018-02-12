//
//  GameScene.swift
//  HelixProto
//
//  Created by Alexander Schülke on 10.02.18.
//  Copyright © 2018 Alexander Schülke. All rights reserved.
//

import SpriteKit
import GameplayKit
import AudioKit

class GameScene: SKScene {
    
    private var background = SKSpriteNode(imageNamed: "background")
    // The parts represent the individual pieces of the DNA. Each part can hold a tone.
    private var parts: [SKSpriteNode] = []
    // The bases that are available for the user on the right of the screen
    private var bases: [Int:SKSpriteNode] = [:]
    // All the bases that were assigned to the DNA
    private var basesOnDna: [SKSpriteNode] = []
    // All DNA parts are listed here with according bases
    private var BasesByParts: [(SKSpriteNode, SKSpriteNode?)] = []
    
    // For dragging bases
    private let panRecognizer = UIPanGestureRecognizer()
    // Currently moved base
    private var currentBase: SKSpriteNode?
    private var originalBasePosition: CGPoint?
    
    
    var piano1 = AKMIDISampler()
    var piano2 = AKMIDISampler()
    var piano3 = AKMIDISampler()
    var piano4 = AKMIDISampler()
    
    var bell = AKMIDISampler()
    var sequencer = AKSequencer(filename: "4tracks")
    
    override init(size: CGSize) {
        // Create the one side of the DNA string.
        for index in 0...11 {
            let part = SKSpriteNode(imageNamed: "stridepart")
            part.zPosition = 0
            part.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            parts.append(part)
            BasesByParts.append((part, nil))
            
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
            base.name = "tone\(index+1)"
            let overallHeight = base.frame.size.height * CGFloat(bases.count)
            base.position = CGPoint(x: self.frame.size.width / 1.68, y: (self.frame.size.height / 2) + (overallHeight / 2) - (base.frame.size.height * 2 * CGFloat(index)))
        }
        
        let playButton = SKSpriteNode(imageNamed: "playButton")
        playButton.name = "playButton"
        addChild(playButton)
        playButton.zPosition = 99
        playButton.position = CGPoint(x: self.frame.size.width / 1.58, y: self.frame.size.height / 7.7)
        playButton.scale(to: CGSize(width: playButton.size.width * CGFloat(1.5), height: playButton.size.height * CGFloat(1.5)))
        
        panRecognizer.addTarget(self, action: #selector(GameScene.drag(_:)))
        self.view!.addGestureRecognizer(panRecognizer)
        
        setupAudio()
        
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
                    // Only assign base to position if base is near enough and part doesn't hold a base yet
                    if nearest.position.x.distance(to: currentBase.position.x) < 100 && isPartEmpty(nearest){
                        currentBase.position = CGPoint(x: nearest.position.x + currentBase.frame.width / 24, y: nearest.position.y)
                        basesOnDna.append(currentBase)
                        for (index, tuple) in BasesByParts.enumerated() {
                            if tuple.0 == nearest {
                                cleanOldParts(from: currentBase)
                                BasesByParts[index] = (nearest, currentBase)
                            }
                        }
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
    
    // Return true when given part doesn't hold a base.
    func isPartEmpty(_ part: SKSpriteNode) -> Bool {
        for (index, tuple) in BasesByParts.enumerated() {
            if part == BasesByParts[index].0 && BasesByParts[index].1 == nil {
                return true
            }
        }
        return false
    }
    
    func cleanOldParts(from base: SKSpriteNode) {
        for (index, tuple) in BasesByParts.enumerated() {
            if base == BasesByParts[index].1 {
                print("cleaned")
                // Clean the part from base by reassigning nil as base
                BasesByParts[index] = (tuple.0, nil)
                return
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
                if let name = node.name {
                    if name == "playButton" {
                        node.playPressedAnimation()
                        node.name = "stopButton"
                        updateLoop()
                        sequencer.play()
                    }
                    else if name == "stopButton"{

                        node.playPressedAnimation()
                        node.name = "playButton"
                        sequencer.stop()
                    }
                }
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
            newBase.name = "tone\(position+1)"
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
    
    private func setupAudio() {
        
        // Load wav files into samplers
        do {
            try piano1.loadWav("FM Piano")
            try piano2.loadWav("FM Piano")
            try piano3.loadWav("FM Piano")
            try piano4.loadWav("FM Piano")
            try bell.loadWav("Bell")
        } catch let error {
            print(error.localizedDescription)
        }
        
        let mixer = AKMixer(piano1, piano2, piano3, piano4, bell)
        AudioKit.output = mixer
        
        sequencer = AKSequencer(filename: "4tracks")
        sequencer.setLength(AKDuration(beats: 12))
        sequencer.setTempo(160)
        sequencer.enableLooping()
        // Set the instruments
        sequencer.tracks[0].setMIDIOutput(piano1.midiIn)
        sequencer.tracks[1].setMIDIOutput(piano2.midiIn)
        sequencer.tracks[3].setMIDIOutput(piano3.midiIn)
        sequencer.tracks[4].setMIDIOutput(piano4.midiIn)
        
        // Remove all previous sampler events
        for track in sequencer.tracks {
            track.clear()
        }

        AudioKit.start()
    }
    
    func updateLoop() {
        // Remove all previous sampler events
        for track in sequencer.tracks {
            track.clear()
        }
        var index = 1
        
        for (_, base) in BasesByParts {
            if let base = base {
                if base.name == "tone1" {
                    sequencer.tracks[0].add(noteNumber: 62, velocity: 127, position: AKDuration(beats: Double(index)), duration: AKDuration(beats: 12+1 - index))
                } else if base.name == "tone2" {
                    sequencer.tracks[1].add(noteNumber: 60, velocity: 127, position: AKDuration(beats: Double(index)), duration: AKDuration(beats: 12+1 - index))
                } else if base.name == "tone3" {
                     sequencer.tracks[2].add(noteNumber: 58, velocity: 127, position: AKDuration(beats: Double(index)), duration: AKDuration(beats: 12+1 - index))
                } else if base.name == "tone4" {
                    sequencer.tracks[3].add(noteNumber: 56, velocity: 127, position: AKDuration(beats: Double(index)), duration: AKDuration(beats: 12+1 - index))
                }
            }
           
            index = index + 1
        }
    }
    
}

