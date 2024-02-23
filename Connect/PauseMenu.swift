//
//  PauseMenu.swift
//  Connect
//
//  Created by Scott Taylor on 6/1/16.
//  Copyright © 2016 Scott Taylor. All rights reserved.
//

import Foundation
import SpriteKit
import UIKit

class PauseMenu: SKScene {
    let box: SKShapeNode? = nil
    let label = SKLabelNode(fontNamed: Grid.font)
    
    override func didMoveToView(view: SKView) {
        backgroundColor = UIColor.whiteColor()
        let box = SKShapeNode(rectOfSize: CGSize(width: 128, height: 27))
        box.position = CGPoint(x: size.width/2, y: size.height/2)
        box.strokeColor = Tile.getColor(.Blue)
        label.text = "Continue"
        label.position.y = -8
        label.fontSize = 16
        label.fontColor = UIColor.blackColor()
        box.addChild(label)
        addChild(box)
    }
}