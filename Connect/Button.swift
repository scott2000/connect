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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        switch (tag) {
        case 0:
            Grid.create(CGSize(width: 1024, height: 768))
            if (Grid.level >= Grid.maxLevel) {
                setImage(UIImage(named: "Endless"), forState: .Normal)
            } else {
                setImage(UIImage(named: "Play"), forState: .Normal)
            }
        case 1:
            setImage(UIImage(named: "Timed"), forState: .Normal)
        case 2:
            setImage(UIImage(named: "Moves"), forState: .Normal)
        case -3:
            setImage(UIImage(named: "Back"), forState: .Normal)
        case -4:
            setImage(UIImage(named: "PlaySmall"), forState: .Normal)
        case -5:
            setImage(UIImage(named: "Main"), forState: .Normal)
        case -6:
            setImage(UIImage(named: "Pause"), forState: .Normal)
        default:
            setImage(nil, forState: .Normal)
        }
        if (tag > -6) {
            backgroundColor = Tile.getColor(.Blue)
        } else {
            backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        }
        layer.cornerRadius = min(bounds.width,bounds.height)/2
        clipsToBounds = true
    }
}