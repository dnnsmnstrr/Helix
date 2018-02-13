//
//  selectionFrame.swift
//  HelixProto
//
//  Created by Alexander Schülke on 12.02.18.
//  Copyright © 2018 Alexander Schülke. All rights reserved.
//

import Foundation
import SpriteKit

class SelectionFrame: SKShapeNode {
    
    public var accordingPart: SKSpriteNode?
    
    init(rectOfSize: CGSize) {
        
        
        super.init()
        self.fillColor = SKColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.15)
        self.strokeColor = SKColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.10)
        var rect = CGRect(origin: CGPoint(x: 0.5, y: 0.5), size: rectOfSize)
        self.path = CGPath(rect: rect, transform: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setPart(part: SKSpriteNode) {
        accordingPart = part
    }
}
