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
        print("init \(tag) (\(Button.buttons) buttons)")
        Button.buttons += 1
        switch (tag) {
        case 0:
            setImage(UIImage(named: "E"), forState: .Normal)
        case 1:
            setImage(UIImage(named: "R"), forState: .Normal)
        case 2:
            setImage(UIImage(named: "T"), forState: .Normal)
        default:
            setImage(nil, forState: .Normal)
        }
        layer.cornerRadius = bounds.width/2
        clipsToBounds = true
    }
    
    deinit {
        Button.buttons -= 1
        print("deinit \(tag) (\(Button.buttons) left)")
    }
}