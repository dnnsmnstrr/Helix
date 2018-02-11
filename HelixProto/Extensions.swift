//
//  Extensions.swift
//  HelixProto
//
//  Created by Alexander Schülke on 11.02.18.
//  Copyright © 2018 Alexander Schülke. All rights reserved.
//

import Foundation
import SpriteKit

extension CGPoint {
    
    func distance(point: CGPoint) -> CGFloat {
        return abs(CGFloat(hypotf(Float(point.x - x), Float(point.y - y))))
    }
}

