//
//  Button.swift
//  Connect
//
//  Created by Scott Taylor on 6/1/16.
//  Copyright © 2016 Scott Taylor. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class Button: UIButton {
    static var buttons = 0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Button.buttons += 1
        print("init \(tag) (\(Button.buttons) \(Button.buttons == 1 ? "button" : "buttons"))")
        switch (tag) {
        case 0:
            Grid.create(CGSize(width: 1024, height: 768))
            if (Grid.level >= 21) {
                setImage(UIImage(named: "Endless"), forState: .Normal)
            } else {
                setImage(UIImage(named: "Play"), forState: .Normal)
            }
        case 1:
            setImage(UIImage(named: "Timed"), forState: .Normal)
        case 2:
            setImage(UIImage(named: "Moves"), forState: .Normal)
        default:
            setImage(nil, forState: .Normal)
        }
        backgroundColor = Tile.getColor(.Blue)
        layer.cornerRadius = bounds.width/2
        clipsToBounds = true
    }
    
    deinit {
        Button.buttons -= 1
        print("deinit \(tag) (\(Button.buttons) left)")
    }
}