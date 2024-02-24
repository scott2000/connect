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
            Grid.create(size: CGSize(width: 1024, height: 768))
            if (Grid.level >= Grid.maxLevel) {
                setImage(UIImage(named: "Endless"), for: .normal)
            } else {
                setImage(UIImage(named: "Play"), for: .normal)
            }
        case 1:
            setImage(UIImage(named: "Timed"), for: .normal)
        case 2:
            setImage(UIImage(named: "Moves"), for: .normal)
        case -3:
            setImage(UIImage(named: "Back"), for: .normal)
        case -4:
            setImage(UIImage(named: "PlaySmall"), for: .normal)
        case -5:
            setImage(UIImage(named: "Main"), for: .normal)
        case -6:
            setImage(UIImage(named: "Pause"), for: .normal)
        default:
            setImage(nil, for: .normal)
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
