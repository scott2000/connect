//
//  Tile.swift
//  Connect
//
//  Created by Scott Taylor on 5/25/16.
//  Copyright © 2016 Scott Taylor. All rights reserved.
//

import Foundation
import SpriteKit

class Tile {
    static let size = 36
    static let spacing = 18
    static let circle = SKShapeNode(circleOfRadius: CGFloat(Double(Tile.size)/2) - 1.5)
    static let wildcardCooldown = (12,24)
    static let powerupCooldown = (48,72)
    static let maxColors = 6
    static var scene: SKScene?
    static var colorsUnlocked = 3
    static var powerupsUnlocked: [SpecialType] = []
    static var cooldown = 48
    static var secondary = 0
    static var tiles: [[Tile?]] = [[Tile?]](count: width, repeatedValue: [Tile?](count: height, repeatedValue: nil))
    static var width: Int = 3
    static var height: Int = 1
    static var grid: Grid?
    static var save = -96
    var color: Color
    var node: SKShapeNode?
    var move = false
    var x: Int
    var y: Int
    var type: SpecialType = .Normal
    
    enum SpecialType: String {
        case Normal = "N"
        case Wildcard = "W"
        case Shuffle = "S"
        case Explode = "E"
        case ClearColor = "C"
        case Star = "T"
        case EnergyBoost = "R"
        case WildcardBomb = "B"
    }
    
    enum Color: Int {
        case None = -1, Blue, Green, Red, Yellow, Purple, Orange
    }
    
    init(x: Int, y: Int, drop: Bool) {
        self.x = x
        self.y = y
        self.color = Color.init(rawValue: Int(arc4random_uniform(UInt32(Tile.colorsUnlocked))))!
        if (Tile.cooldown <= 0 && Tile.grid!.level > 0 && Tile.secondary == 0) {
            let r = Int(arc4random_uniform(5));
            if (Tile.powerupsUnlocked.count == 0 || (r != 0 && r != 1)) {
                self.type = .Wildcard
            } else {
                self.type = Tile.powerupsUnlocked[Int(arc4random_uniform(UInt32(Tile.powerupsUnlocked.count)))]
            }
        }
        if (type == .EnergyBoost && Tile.grid!.mode == 0) {
            type = .Wildcard
        }
        if (type == .Normal) {
            Tile.cooldown -= 1
            Tile.secondary = max(Tile.secondary-1,0)
        } else if (type == .Wildcard) {
            Tile.cooldown = Tile.cooldown + Tile.rg(Tile.wildcardCooldown)
            Tile.secondary += 3
        } else {
            Tile.cooldown = Tile.cooldown + Tile.rg(Tile.powerupCooldown)
            Tile.secondary += 6
        }
        create(drop)
    }
    
    init(x: Int, y: Int, type: SpecialType, drop: Bool) {
        self.x = x
        self.y = y
        self.color = Color.init(rawValue: Int(arc4random_uniform(UInt32(Tile.colorsUnlocked))))!
        self.type = type
        create(drop)
    }
    
    init(x: Int, y: Int, color: Color, type: SpecialType, drop: Bool) {
        self.x = x
        self.y = y
        self.color = color
        self.type = type
        create(drop)
    }
    
    deinit {
        clearNode()
    }
    
    static func resize(x: Int, _ y: Int) {
        clearNodes()
        Tile.width = x
        Tile.height = y
        Tile.cooldown = 48
        Tile.tiles = [[Tile?]](count: x, repeatedValue: [Tile?](count: y, repeatedValue: nil))
    }
    
    static func reset() {
        clearNodes()
        Tile.cooldown = 48
        Tile.tiles = [[Tile?]](count: width, repeatedValue: [Tile?](count: height, repeatedValue: nil))
    }
    
    static func clearNodes() {
        for x in 0..<width {
            for y in 0..<height {
                if let tile = Tile.tiles[x][y] {
                    tile.clearNode()
                }
            }
        }
    }
    
    static func rg(input: (Int, Int)) -> Int {
        let r = input.1 - input.0
        return input.0 + Int(arc4random_uniform(UInt32(r)))
    }
    
    static func setScene(scene: SKScene) {
        Tile.scene = scene
    }
    
    static func removeGrid(grid: Grid) {
        if (Tile.grid == grid) {
            Tile.grid = nil
            Tile.reset()
        }
    }
    
    static func setGrid(grid: Grid?) {
        Tile.grid = grid
        Tile.reset()
    }
    
    static func setColors(colors: Int) {
        Tile.colorsUnlocked = min(colors, Tile.maxColors)
    }
    
    static func unlockPowerup(type: SpecialType) {
        if (type != .Normal && type != .Wildcard && !Tile.powerupsUnlocked.contains(type)) {
            powerupsUnlocked.append(type)
        }
    }
    
    static func getColor(color: Color) -> UIColor {
        switch(color) {
        case .Red:
            return UIColor.redColor()
        case .Orange:
            return UIColor.orangeColor()
        case .Yellow:
            return UIColor(red: 0.9, green: 0.75, blue: 0.0, alpha: 1.0)
        case .Green:
            return UIColor(red: 0.1, green: 0.75, blue: 0.1, alpha: 1.0)
        case .Blue:
            return UIColor(red: 0.25, green: 0.25, blue: 1.0, alpha: 1.0)
        case .Purple:
            return UIColor(red: 0.5, green: 0.0, blue: 0.7, alpha: 1.0)
        default:
            return UIColor.blackColor()
        }
    }
    
    static func getData() -> String {
        Tile.save = -96
        var str = "\(Tile.width).\(Tile.height).\(Tile.colorsUnlocked).\(Tile.cooldown):"
        if (Tile.tiles.count != Tile.width) {
            print("Error Compiling Node List")
            str += "?"
        } else {
            for x in 0..<width {
                for y in 0..<height {
                    if (Tile.tiles[x][y] == nil) {
                        str += "?"
                    } else {
                        str += "\(Tile.tiles[x][y]!.color.rawValue+1)\(Tile.tiles[x][y]!.type.rawValue)"
                    }
                    if (y < Tile.height-1) {
                        str += "."
                    }
                }
                if (x < Tile.width-1) {
                    str += ";"
                }
            }
        }
        Tile.save = 0
        return str
    }
    
    static func loadData(str: String) {
        let a = str.componentsSeparatedByString(":")
        let a0 = a[0].componentsSeparatedByString(".")
        Tile.resize(Int(a0[0])!,Int(a0[1])!)
        Tile.setColors(Int(a0[2])!)
        Tile.save = -96
        if (a[1] != "?") {
            let a1 = a[1].componentsSeparatedByString(";")
            Tile.grid!.gridPaused = true
            var x = 0
            for b in a1 {
                var y = 0
                for c in b.componentsSeparatedByString(".") {
                    if (c != "?") {
                        let d = [String(c.substringToIndex(c.startIndex.successor())),String(c.substringFromIndex(c.startIndex.successor()))]
                        Tile.tiles[x][y]! = Tile(x: x, y: y, color: Tile.Color(rawValue: Int(d[0])!-1)!, type: Tile.SpecialType(rawValue: d[1])!, drop: false)
                        Tile.tiles[x][y]!.node!.hidden = true
                    }
                    y += 1
                }
                x += 1
            }
        }
        Tile.cooldown = Int(a0[3])!
        Tile.save = 0
    }
    
    func clearNode() {
        if (node != nil) {
            node!.removeFromParent()
            node = nil
        }
    }
    
    func getPoint(x: Int, _ y: Int) -> CGPoint {
        let pivot = Double(Tile.size+Tile.spacing)
        let xp = Double(Tile.scene!.size.width)/2-pivot*Double(Tile.width-1)/2
        let yp = Double(Tile.scene!.size.height)/2-pivot*Double(Tile.height-1)/2
        return CGPoint(x: Double(x)*pivot+xp, y: Double(y)*pivot+yp)
    }
    
    func create(drop: Bool) {
        let product = Tile.circle.copy() as! SKShapeNode
        if (type == .Wildcard) {
            color = .None
        } else if (type != .Normal) {
            product.addChild(SKSpriteNode(imageNamed: type.rawValue))
        }
        product.fillColor = type == .Wildcard ? UIColor.whiteColor() : Tile.getColor(color)
        product.strokeColor = type == .Wildcard ? UIColor.blackColor() : Tile.getColor(color)
        product.lineWidth = 3.0
        product.position = getPoint(x,y)
        if (drop) {
            product.position.y = Tile.scene!.size.height+CGFloat(Tile.size+Tile.spacing)/2
            Tile.grid!.falling[x] = product
        }
        node = product
        Tile.tiles[x][y] = self
        
        Tile.scene!.addChild(product)
    }
}