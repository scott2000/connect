//
//  Bar.swift
//  Connect
//
//  Created by Scott Taylor on 6/3/16.
//  Copyright © 2016 Scott Taylor. All rights reserved.
//

import Foundation
import SpriteKit
import UIKit

class Bar {
    weak var scene: SKScene?
    let back: SKSpriteNode
    var front: SKSpriteNode
    let separator: SKSpriteNode
    let width: Int
    var text: String?
    let fs: CGFloat
    private var current: Int
    var max: Int
    let position: CGPoint
    var color: UIColor
    var label: SKLabelNode?
    var u: Double
    
    init(current: Int, max: Int, position: CGPoint, width: Int, color: UIColor, fontSize fs: CGFloat, text: String?) {
        scene = MainViewController.scene
        self.text = text
        self.fs = fs
        self.current = current
        self.max = max
        self.position = position
        self.width = width
        self.color = color
        back = SKSpriteNode(color: UIColor.lightGrayColor(), size: CGSize(width: width, height: 5))
        separator = SKSpriteNode(color: UIColor.darkGrayColor(), size: CGSize(width: 4, height: 13))
        u = (Double(width)*Double(min(current,max))/Double(max))
        front = SKSpriteNode(color: color, size: CGSize(width: u, height: 9))
        createBar()
    }
    
    init(current: Int, max: Int, color: UIColor, index: Int, text: String?, grid: Grid?) {
        scene = grid
        self.color = color
        self.current = current
        self.max = max
        self.text = text
        let i: Bool = index < 0
        let c: Int = -1
        let d: Int = Tile.height
        let i2: Int = i ? c : d
        let a = Grid.active!.getPoint(0, i2)
        let b = Grid.active!.getPoint(Tile.width, i2)
        self.width = Int(b.x-a.x-CGFloat(Tile.size/2))
        let oy = CGFloat(Tile.spacing)/2+CGFloat((i ? (-index)-1 : index)*24)
        self.position = CGPoint(x: a.x-CGFloat(Tile.size/2), y: i ? a.y-oy : a.y+oy)
        back = SKSpriteNode(color: UIColor.lightGrayColor(), size: CGSize(width: width, height: 5))
        separator = SKSpriteNode(color: UIColor.darkGrayColor(), size: CGSize(width: 4, height: 13))
        u = (Double(width)*Double(min(current,max))/Double(max))
        front = SKSpriteNode(color: color, size: CGSize(width: u, height: 9))
        fs = 14+(7*CGFloat(Grid.level-7)/CGFloat(Grid.maxLevel-7))
        createBar()
    }
    
    deinit {
        clearBar()
    }
    
    func createBar() {
        back.position = position
        back.position.x += CGFloat(width/2)
        back.zPosition = -288
        back.blendMode = .Replace
        scene?.addChild(back)
        separator.zPosition = -286
        separator.blendMode = .Replace
        scene?.addChild(separator)
        if (text != nil) {
            label = SKLabelNode(text: text)
            label!.position = CGPoint(x: 0, y: Tile.spacing/2+6)
            label!.fontName = Grid.font
            label!.fontSize = fs
            label!.fontColor = UIColor.blackColor()
            back.addChild(label!)
        }
        front.anchorPoint = CGPoint(x: 0, y: 0.5)
        front.position = position
//            front.position.x += CGFloat(u/2)
        front.zPosition = -287
        front.blendMode = .Replace
        scene?.addChild(front)
        separator.position = position
        separator.position.x += CGFloat(u)
    }
    
    func updateBar(current: Int) {
        updateBar(current, text: text)
    }
    
    func updateBar(current: Int, color: UIColor) {
        self.color = color
        updateBar(current, text: text)
    }
    
    func updateBar(current: Int, max: Int, color: UIColor, text: String?) {
        updateBar(current, text: text)
        if (self.max != max || self.color != color) {
            self.max = max
            self.color = color
        }
    }
    
    func updateBar(current: Int, text: String?) {
        if (self.current != current || self.text != text) {
            if (self.current > 0) {
                front.color = color
            }
            let t = Double(abs(min(current,max)-min(self.current,max)))/Double(max)
            self.current = current
            self.text = text
            u = (Double(width)*Double(min(current,max))/Double(max))
            separator.removeAllActions()
            separator.runAction(SKAction.moveToX(position.x + CGFloat(u), duration: t), withKey: "Move\(current)-\(t)")
            label?.text = text
            front.removeAllActions()
            front.runAction(SKAction.resizeToWidth(CGFloat(u), duration: t), withKey: "Resize\(current)-\(t)")
        }
    }
    
    func clearBar() {
        back.removeFromParent()
        separator.removeFromParent()
        front.removeFromParent()
    }
}