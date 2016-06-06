//
//  Grid.swift
//  Connect
//
//  Created by Scott Taylor on 5/16/16.
//  Copyright © 2016 Scott Taylor. All rights reserved.
//

import Foundation
import SpriteKit
import AVFoundation

class Grid: SKScene {
    static let basePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    static let lvlsys = 17
    static let maxEnergy = 144
    static let energyThreshold = Grid.maxEnergy/4
    static let maxLevel = 21
    static let font = "Helvetica Neue"
    static let time = 8 //seconds
    static let versionPath = Grid.basePath + "/version.txt"
    static let savePath = Grid.basePath + "/\(String(Grid.lvlsys)).txt"
    static let lastSavePath = Grid.basePath + "/\(Grid.getLastVersionString()).txt"
    static let moveEnergy = Grid.maxEnergy/36
    static var grids: [Grid.Mode:Grid] = [:]
    static var level = -2
    static var xp = 0
    static var diffs = 1
    static var modes = 1
    static var points = 0
    static var mXP = 1
    static var lc = true
    static var display: (main: String, sub: String) = (main: "nil", sub: "nil")
    static var newPowerup = false
    static var active: Grid?
    static let moveSound = SoundPlayer.getSound("Move")
    static let powerupSound = SoundPlayer.getSound("Powerup")
    static let dieSound = SoundPlayer.getSound("Die")
    static let winSound = SoundPlayer.getSound("Win")
    static let timeSound = SoundPlayer.getSound("Time")
    var chain: [(Int,Int,SKShapeNode?)]?
    var chainLine: SKShapeNode?
    var falling: [SKShapeNode?] = []
    var energy = maxEnergy
    var swaps = 0
    var frames = 0
    var started = false
    var running = false
    var diff: Grid.Difficulty = .Easy
    let mode: Grid.Mode
    var lastTime = NSDate().timeIntervalSince1970
    var gridPaused = false
    var freezeMoves = 0
    var restoring = false
    var shuffling = false
    var sc: Int = 0
    var xpBar: Bar?
    var energyBar: Bar?
    var pointsSoFar = 0
    var record: Records?
    var sh = false
    var label: SKLabelNode?
    
    static func create(size: CGSize) {
        if (grids.count == 0) {
            for i in 0..<3 {
                let m = Grid.Mode(rawValue: i)
                if (m != nil) {
                    Grid.grids[m!] = Grid(size: size, mode: m!)
                }
            }
            loadAll()
        }
    }
    
    static func loadAll() {
        let lastVersion = getLastVersion()
        if (lastVersion < 14) {
            if let oldData = loadData(basePath+"/save\(lastVersion).txt") {
                level = Int(oldData[1]) ?? level
                xp = Int(oldData[2]) ?? xp
                points = Int(oldData[6]) ?? points
                Challenge.load(oldData.last ?? "0")
            }
        } else {
            if let data = loadData(basePath+"/\(lastVersion).txt") {
                level = Int(data[0]) ?? level
                xp = Int(data[1]) ?? xp
                points = Int(data[2]) ?? points
                Challenge.load(data[3])
            }
        }
        if (lastVersion != lvlsys) {
            let (l1, x1) = fixXP(level, xp, lastVersion)
            level = l1
            xp = x1
        }
        if (level > -2) {
            for i in -1...level {
                newUpgrade(i)
            }
        } else {
            Tile.setColors(1)
        }
        if (lastVersion == lvlsys) {
            for n in grids.keys {
                let g = grids[n]
                g?.loadAll()
            }
        } else {
            for n in grids.keys {
                let g = grids[n]
                g?.loadAll(lastVersion)
                active = g
                g?.saveAll()
            }
            active = nil
        }
    }
    
    static func clear() {
        Grid.grids = [:]
    }
    
    static func setMode(mode: Grid.Mode) {
        if (active != nil) {
            active!.saveAll()
        }
        active = grids[mode]
    }
    
    deinit {
        saveAll()
    }
    
    init(size: CGSize, mode: Grid.Mode) {
        self.mode = mode
        super.init(size: size)
        backgroundColor = UIColor.whiteColor()
    }
    
    enum Mode: Int {
        case Standard = 0
        case Timed = 1
        case Moves = 2
    }
    
    enum Difficulty: Int {
        case Easy = 0
        case Hard = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func loadAll() {
        loadAll(Grid.lvlsys)
    }
    
    func loadAll(lvlsys: Int) {
        if let data = Grid.loadData(Grid.basePath+"/\(lvlsys)-\(mode.rawValue).txt") {
            if (lvlsys != Grid.lvlsys) {
                gridPaused = false
                if (data.count >= 3) {
                    record = Records(s: data[2])
                } else {
                    record = Records(s: nil)
                }
            } else {
                energy = Int(data[0]) ?? Grid.maxEnergy
                freezeMoves = Int(data[1]) ?? 0
                record = Records(s: data[2])
                if (data.count > 3) {
                    gridPaused = true
                    Tile.loadData(data[3], grid: self)
                    swaps = Int(data[4]) ?? 0
                    pointsSoFar = Int(data[5]) ?? 0
                } else {
                    gridPaused = false
                }
            }
        } else {
            record = Records(s: nil)
        }
        falling = [SKShapeNode?](count: Tile.width, repeatedValue: nil)
    }
    
    func saveAll() {
        Grid.saveData([String(Grid.level),String(Grid.xp),String(Grid.points),Challenge.save()], path: Grid.basePath+"/\(Grid.lvlsys).txt")
        if (running || gridPaused) {
            Grid.saveData([String(energy),String(freezeMoves),record!.save(),Tile.getData(mode),String(swaps),String(pointsSoFar)], path: Grid.basePath+"/\(Grid.lvlsys)-\(mode.rawValue).txt")
        } else {
            Grid.saveData([String(energy),String(freezeMoves),record!.save()], path: Grid.basePath+"/\(Grid.lvlsys)-\(mode.rawValue).txt")
        }
        Grid.saveVersion()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            if (findPoint(location) != nil) {
                move(location)
            } else if (location.y >= size.height-36) {
                pause()
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            move(location)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        releaseChain()
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        cancel()
    }
    
    static func getLastVersion() -> Int {
        do {
            return try Int(String(contentsOfFile: Grid.versionPath, encoding: NSASCIIStringEncoding))!
        } catch {
            return 0
        }
    }
    
    static func getLastVersionString() -> String {
        do {
            return try String(contentsOfFile: Grid.versionPath, encoding: NSASCIIStringEncoding)
        } catch {
            return ""
        }
    }
    
    static func saveVersion() {
        do {
            try String(Grid.lvlsys).writeToFile(Grid.versionPath, atomically: true, encoding: NSASCIIStringEncoding)
        } catch {
            print("Unable to save version")
        }
    }
    
    static func saveData(array: [String], path: String) {
        let j = array.joinWithSeparator(",")
        print("Save: \(j) to \(path.stringByReplacingOccurrencesOfString(Grid.basePath+"/", withString: "\""))\"")
        do {
            try j.writeToFile(path, atomically: true, encoding: NSASCIIStringEncoding)
        } catch {
            print("Unable to write data")
        }
    }
    
    static func loadData(path: String) -> [String]? {
        do {
            let c = try String(contentsOfFile: path, encoding: NSASCIIStringEncoding)
            print("Load: \(c) from \(path.stringByReplacingOccurrencesOfString(Grid.basePath+"/", withString: "\""))\"")
            return c.componentsSeparatedByString(",")
        } catch {
            return nil
        }
    }
    
    func pause() {
        saveAll()
        if (running) {
            forcePause()
        }
    }
    
    static func maxXP() -> Int {
        return Grid.maxXP(Grid.level, Grid.lvlsys, lc: lc, u: true)
    }
    
    static func maxXP(level: Int) -> Int {
        return maxXP(level, Grid.lvlsys, lc: true, u: false)
    }
    
    static func maxXP(level: Int, _ lvlsys: Int) -> Int {
        return maxXP(level, lvlsys, lc: true, u: false)
    }
    
    static func maxXP(level: Int, _ lvlsys: Int, lc: Bool, u: Bool) -> Int {
        if (!lc) {
            return mXP
        }
        var r = 1
        if (level >= 1) {
            switch (lvlsys) {
            case 0:
                r = 12*Int(pow(Double(level),Double(2)))+144*level+288
            case 1,2,3,4:
                r = 36*Int(pow(Double(level),Double(2)))+216*level+360
            case 5,6,7,8,9,10,11:
                r = 48*Int(pow(Double(level),Double(2)))+288*level+864
            case 12:
                let a = 48*Int(pow(Double(level),Double(2)))+288*level+864
                let b = 216*Int(pow(Double(level),Double(2)))+864*level
                let c = 864*level+4096
                r = max(a,min(b,c))
            default:
                let a = 48*Int(pow(Double(level),Double(2)))+288*level+864
                let b = 288*Int(pow(Double(level),Double(2)))+864*level
                let c = 1024*level+4096
                r = max(a,min(b,c))
            }
        }
        if (u) {
            mXP = r
        }
        return r
    }
    
    static func fixXP(lvl: Int, _ exp: Int, _ l1: Int) -> (Int, Int) {
        var level = lvl
        var xp = exp
        var i = -2
        while (level > -2) {
            let mxp = maxXP(i, l1)
            xp += mxp
            level -= 1
            i += 1
        }
        i = -2
        while (i < Grid.maxLevel) {
            let mxp = maxXP(i)
            if (xp >= mxp) {
                xp -= mxp
                level += 1
            } else {
                break
            }
            i += 1
        }
        return (level, xp)
    }
    
    func forcePause() {
        gridPaused = true
        Grid.display.main = "Paused"
        Grid.display.sub = "Score: \(GameViewController.number(pointsSoFar))\(pointsSoFar >= record!.points ? " (High Score)" : "")"
        Grid.moveSound?.play()
        reset()
    }
    
    static func getColor(color: Int) -> UIColor {
        return Tile.getColor(Tile.Color(rawValue: color)!)
    }
    
    func checkChain(point: (Int, Int)) -> Bool {
        for p in chain! {
            if (p.0 == point.0 && p.1 == point.1) {
                return true
            }
        }
        return false
    }
    
    func checkForAll() -> Int {
        var v = 0
        for p in chain! {
            let (x, y, _) = p
            for i in -1...1 {
                for o in -1...1 {
                    if (x+i >= 0 && x+i < Tile.width && y+o >= 0 && y+o < Tile.height && !checkChain((x+i,y+o)) && Grid.nextTo(a: (x,y),b: (x+i,y+o))) {
                        let nn = Tile.tiles[mode.rawValue]![x+i][y+o] != nil && Tile.tiles[mode.rawValue]![chain!.first!.0][chain!.first!.1] != nil
                        if (nn && Tile.tiles[mode.rawValue]![x+i][y+o]!.color == Tile.tiles[mode.rawValue]![chain!.first!.0][chain!.first!.1]!.color) {
                            v += 1
                        }
                    }
                }
            }
        }
        return v
    }
    
    func check(point: (Int,Int)) -> Bool {
        return !Tile.tiles[mode.rawValue]![point.0][point.1]!.move
    }
    
    static func nextTo(a a: (Int,Int), b: (Int,Int)) -> Bool {
        let bx = abs(a.0-b.0)
        let by = abs(a.1-b.1)
        return bx + by == 1
    }
    
    func drawLine(from source: CGPoint, to destination: CGPoint, color: UIColor, z: CGFloat) -> SKShapeNode {
        return drawLine(from: source, to: destination, color: color, z: z, size: CGFloat(Tile.size)/4)
    }
    
    func drawLine(from source: CGPoint, to destination: CGPoint, color: UIColor, z: CGFloat, size: CGFloat) -> SKShapeNode {
        let path = CGPathCreateMutable()
        let line = SKShapeNode()
        CGPathMoveToPoint(path, nil, source.x, source.y)
        CGPathAddLineToPoint(path, nil, destination.x, destination.y)
        line.path = path
        line.lineWidth = size
        line.fillColor = color
        line.strokeColor = color
        line.zPosition = z
        line.lineCap = .Round
        addChild(line)
        return line
    }
    
    func move(point: CGPoint) {
        if (running) {
            if (started == false) {
                lastTime = NSDate().timeIntervalSince1970
                started = true
            }
            if let location = findPoint(point) {
                updateChain(location)
            }
            if (chain == nil && chainLine != nil) {
                chainLine!.removeFromParent()
                chainLine = nil
            }
            if (chain != nil) {
                if (chainLine != nil) {
                    chainLine!.removeFromParent()
                    chainLine = nil
                }
                let first = Tile.tiles[mode.rawValue]![chain!.first!.0][chain!.first!.1]!
                let old = Tile.tiles[mode.rawValue]![chain!.last!.0][chain!.last!.1]!
                if (first.color == old.color || first.color == .None || old.color == .None) {
                    chainLine = drawLine(from: old.node!.position, to: point, color: chain!.count == 1 || first.color != old.color ? UIColor.blackColor() : Tile.getColor(first.color), z: -13)
                }
            }
        }
    }
    
    func clearChain() {
        if (chain != nil) {
            for (x, y, line) in chain! {
                if (line != nil) {
                    line!.removeFromParent()
                }
                if (Tile.tiles[mode.rawValue]![x][y] != nil && Tile.tiles[mode.rawValue]![x][y]!.type == .Wildcard) {
                    Tile.tiles[mode.rawValue]![x][y]!.color = .None
                    Tile.tiles[mode.rawValue]![x][y]!.node!.fillColor = UIColor.whiteColor()
                }
            }
        }
        if (chainLine != nil) {
            chainLine!.removeFromParent()
            chainLine = nil
        }
        chain = nil
        update()
    }
    
    func getDiff() -> Int {
        return max(0,diff.rawValue)*2+max(0,mode == .Timed ? 3 : 1)
    }
    
    func runPowerup(type1: String, color color1: Int, _ xb: Int, _ yb: Int) {
        let type = Tile.SpecialType(rawValue: type1)!
        let color = Tile.Color(rawValue: color1)!
        switch (type) {
        case .Shuffle:
            if (!sh) {
                sh = true
                shuffle()
                let i = 1024
                Grid.xp += i
                Grid.points += i
                pointsSoFar += i
            }
        case .Explode:
            var pus: [(Tile.SpecialType, Tile.Color, Int, Int)] = []
            for x in max(xb-3,0)..<min(xb+3,Tile.width) {
                for y in max(yb-3,0)..<min(yb+3,Tile.height) {
                    if (Tile.tiles[mode.rawValue]![x][y] != nil && distance(from: CGPoint(x: x, y: y), to: CGPoint(x: xb, y: yb)) <= 2.75) {
                        let i = Tile.tiles[mode.rawValue]![x][y]!.type == .Wildcard ? 72 : 60
                        Grid.xp += i
                        Grid.points += i
                        pointsSoFar += i
                        let t = Tile.tiles[mode.rawValue]![x][y]!.type
                        if (Challenge.challenge != nil) {
                            Challenge.challenge!.clear(Tile.tiles[mode.rawValue]![x][y]!.color, type: t)
                        }
                        if (t != .Normal && t != .Wildcard) {
                            Grid.xp += 24
                            Grid.points += 24
                            pointsSoFar += 24
                            pus.append((t,Tile.tiles[mode.rawValue]![x][y]!.color, x, y))
                        }
                        Tile.tiles[mode.rawValue]![x][y]!.node!.removeFromParent()
                        Tile.tiles[mode.rawValue]![x][y] = nil
                    }
                }
            }
            for (a, b, x, y) in pus {
                runPowerup(a.rawValue, color: b.rawValue, x, y)
            }
        case .ClearColor:
            var pus: [(Tile.SpecialType, Tile.Color, Int, Int)] = []
            for x in 0..<Tile.width {
                for y in 0..<Tile.height {
                    if (Tile.tiles[mode.rawValue]![x][y] != nil && Tile.tiles[mode.rawValue]![x][y]!.color == color && Tile.tiles[mode.rawValue]![x][y]!.type != .Wildcard) {
                        Grid.xp += 60
                        Grid.points += 60
                        pointsSoFar += 60
                        let t = Tile.tiles[mode.rawValue]![x][y]!.type
                        if (Challenge.challenge != nil) {
                            Challenge.challenge!.clear(Tile.tiles[mode.rawValue]![x][y]!.color, type: t)
                        }
                        if (t != .Normal && t != .Wildcard && t != .ClearColor) {
                            Grid.xp += 24
                            Grid.points += 24
                            pointsSoFar += 24
                            pus.append((t,Tile.tiles[mode.rawValue]![x][y]!.color, x, y))
                        }
                        Tile.tiles[mode.rawValue]![x][y]!.node!.removeFromParent()
                        Tile.tiles[mode.rawValue]![x][y] = nil
                    }
                }
            }
            for (a, b, x, y) in pus {
                runPowerup(a.rawValue, color: b.rawValue, x, y)
            }
        case .Star:
            var pus: [(Tile.SpecialType, Tile.Color, Int, Int)] = []
            let x = xb
            for y in 0..<Tile.height {
                if (Tile.tiles[mode.rawValue]![x][y] != nil) {
                    let i = Tile.tiles[mode.rawValue]![x][y]!.type == .Wildcard ? 72 : 60
                    Grid.xp += i
                    Grid.points += i
                    pointsSoFar += i
                    let t = Tile.tiles[mode.rawValue]![x][y]!.type
                    if (Challenge.challenge != nil) {
                        Challenge.challenge!.clear(Tile.tiles[mode.rawValue]![x][y]!.color, type: t)
                    }
                    if (t != .Normal && t != .Wildcard) {
                        Grid.xp += 24
                        Grid.points += 24
                        pointsSoFar += 24
                        pus.append((t,Tile.tiles[mode.rawValue]![x][y]!.color, x, y))
                    }
                    Tile.tiles[mode.rawValue]![x][y]!.node!.removeFromParent()
                    Tile.tiles[mode.rawValue]![x][y] = nil
                }
            }
            let y = yb
            for x in 0..<Tile.width {
                if (Tile.tiles[mode.rawValue]![x][y] != nil) {
                    let i = Tile.tiles[mode.rawValue]![x][y]!.type == .Wildcard ? 72 : 60
                    Grid.xp += i
                    Grid.points += i
                    pointsSoFar += i
                    let t = Tile.tiles[mode.rawValue]![x][y]!.type
                    if (Challenge.challenge != nil) {
                        Challenge.challenge!.clear(Tile.tiles[mode.rawValue]![x][y]!.color, type: t)
                    }
                    if (t != .Normal && t != .Wildcard) {
                        Grid.xp += 24
                        Grid.points += 24
                        pointsSoFar += 24
                        pus.append((t,Tile.tiles[mode.rawValue]![x][y]!.color, x, y))
                    }
                    Tile.tiles[mode.rawValue]![x][y]!.node!.removeFromParent()
                    Tile.tiles[mode.rawValue]![x][y] = nil
                }
            }
            for (a, b, x, y) in pus {
                runPowerup(a.rawValue, color: b.rawValue, x, y)
            }
        case .EnergyBoost:
            Grid.xp += 72
            Grid.points += 72
            pointsSoFar += 72
            if (mode == .Moves) {
                freezeMoves += 6
            } else {
                freezeMoves += 4 + Int(round(2*Double(energy)/Double(Grid.maxEnergy)))
                energy = Grid.maxEnergy
            }
        case .WildcardBomb:
            for x in 0..<Tile.width {
                for y in 0..<Tile.height {
                    if (Tile.tiles[mode.rawValue]![x][y] != nil && Tile.tiles[mode.rawValue]![x][y]!.type == .Normal && Int(arc4random_uniform(11)) <= 1) {
                        let i = 72
                        Grid.xp += i
                        Grid.points += i
                        pointsSoFar += i
                        Tile.tiles[mode.rawValue]![x][y]!.type = .Wildcard
                        Tile.tiles[mode.rawValue]![x][y]!.color = .None
                        Tile.tiles[mode.rawValue]![x][y]!.node!.fillColor = UIColor.whiteColor()
                        Tile.tiles[mode.rawValue]![x][y]!.node!.strokeColor = UIColor.blackColor()
                    }
                }
            }
        default:
            break
        }
        started = false
    }
    
    func releaseChain() {
        if (chain != nil) {
            record?.chain(chain!.count)
            Tile.save += 1
            if (Tile.save >= 6) {
                saveAll()
            }
            var t = chain!.count
            let inf = checkForAll()
            if (inf == 0) {
                t += t-3
            }
            if (chain!.count == 2) {
                let a = Tile.tiles[mode.rawValue]![chain![0].0][chain![0].1]!
                let b = Tile.tiles[mode.rawValue]![chain![1].0][chain![1].1]!
                if (a.color != b.color || a.type != b.type) {
                    if (Grid.level == 1) {
                        deleteLabel()
                    } else if (Grid.level == 0) {
                        makeLabel("If You Run Out of Energy, You Lose")
                    }
                    if (Challenge.challenge != nil) {
                        Challenge.challenge!.swap()
                    }
                    if (freezeMoves == 0) {
                        if (mode != .Moves) {
                            energy = max(energy-(6*((mode == .Timed) ? 4 : 6)),0)
                        } else {
                            energy = max(energy-Grid.moveEnergy,0)
                        }
                        swaps += 1
                    } else {
                        freezeMoves -= 1
                        lastTime = NSDate().timeIntervalSince1970
                    }
                    movePoint(from: (chain!.first!.0,chain!.first!.1), to: (chain!.last!.0,chain!.last!.1))
                    clearChain()
                    if (energy <= (mode == .Moves ? Grid.moveEnergy*3 : Grid.energyThreshold) && mode != .Timed && energy > 0) {
                        Grid.timeSound?.play()
                    } else if (energy > 0) {
                        Grid.moveSound?.play()
                    }
                    return
                }
            } else if (chain!.count > 2 && (inf == 0 || diff != .Hard)) {
                if (Grid.level == 1) {
                    deleteLabel()
                }
                let t2 = (inf+Int(exp2(Double(inf)))-t)/(max(1,mode.rawValue)*2)
                let t3 = Int(exp2(Double(min(t-2,10))))*(max(1,mode.rawValue)*3)
                if (mode != .Moves) {
                    if (diff != .Hard || inf == 0) {
                        energy = min((energy+t3*2),Grid.maxEnergy)
                    } else {
                        energy = min(max(energy+t3-t2,0),Grid.maxEnergy)
                    }
                }
                let increase = max(min(max(Int(exp2(Double(min(t-2,6))))-(swaps*2),0)+t-t2,Grid.maxXP()),0)*getDiff()
                if (mode != .Standard && freezeMoves > 0) {
                    freezeMoves -= 1
                    lastTime = NSDate().timeIntervalSince1970
                } else if (mode == .Moves) {
                    energy = max(energy-Grid.moveEnergy,0)
                }
                if (Challenge.challenge != nil) {
                    Challenge.challenge!.chain(chain!.count)
                }
                Grid.xp += increase
                Grid.points += increase
                pointsSoFar += increase
                swaps = max(swaps-(t/3),0)
                var pus: [(Tile.SpecialType, Tile.Color, Int, Int)] = []
                for (x, y, _) in chain! {
                    if (Tile.tiles[mode.rawValue]![x][y] != nil) {
                        let t = Tile.tiles[mode.rawValue]![x][y]!.type
                        let c = Tile.tiles[mode.rawValue]![x][y]!.color
                        if (Tile.tiles[mode.rawValue]![x][y]!.type == .Wildcard) {
                            Grid.xp += 60
                            Grid.points += 60
                            pointsSoFar += 60
                        }
                        Tile.tiles[mode.rawValue]![x][y]!.node!.removeFromParent()
                        Tile.tiles[mode.rawValue]![x][y] = nil
                        if (Challenge.challenge != nil) {
                            Challenge.challenge!.clear(c, type: t)
                        }
                        if (t != .Wildcard && t != .Normal) {
                            pus.append((t,c, x, y))
                            Grid.xp += 24
                            Grid.points += 24
                            pointsSoFar += 24
                        }
                    }
                }
                for (a,b,x,y) in pus {
                    runPowerup(a.rawValue, color: b.rawValue, x, y)
                }
                sh = false
                if (Challenge.challenge != nil) {
                    Challenge.challenge!.check()
                }
                if (energy <= Grid.moveEnergy*3 && mode == .Moves && energy > 0) {
                    Grid.timeSound?.play()
                } else if (energy > 0) {
                    if (pus.count > 0) {
                        Grid.powerupSound?.play()
                    } else {
                        Grid.moveSound?.play()
                    }
                }
            }
            clearChain()
        }
    }
    
    func cancel() {
        clearChain()
    }
    
    func updateChain(point: (Int, Int)) {
        if (check(point)) {
            if (chain == nil) {
                chain = [(point.0,point.1,nil)]
            } else {
                if (!Grid.nextTo(a: point,b: (chain!.last!.0,chain!.last!.1))) {
                    return
                }
                if (chain!.count >= 2 && chain![chain!.count-2].0 == point.0 && chain![chain!.count-2].1 == point.1) {
                    if let line = chain!.last!.2 {
                        line.removeFromParent()
                    }
                    if (Tile.tiles[mode.rawValue]![chain!.last!.0][chain!.last!.1]!.type == .Wildcard) {
                        Tile.tiles[mode.rawValue]![chain!.last!.0][chain!.last!.1]!.color = .None
                        Tile.tiles[mode.rawValue]![chain!.last!.0][chain!.last!.1]!.node!.fillColor = UIColor.whiteColor()
                    }
                    chain!.removeLast()
                    if (chain!.count == 1) {
                        if (Tile.tiles[mode.rawValue]![chain!.first!.0][chain!.first!.1]!.type == .Wildcard) {
                            Tile.tiles[mode.rawValue]![chain!.first!.0][chain!.first!.1]!.color = .None
                            Tile.tiles[mode.rawValue]![chain!.first!.0][chain!.first!.1]!.node!.fillColor = UIColor.whiteColor()
                        }
                    }
                    return
                }
                if (checkChain(point)) {
                    return
                }
                if ((checkColor([chain!.first!.0,chain!.last!.0,point.0],[chain!.first!.1,chain!.last!.1,point.1])) || (chain!.count == 1)) {
                    let first = Tile.tiles[mode.rawValue]![chain!.first!.0][chain!.first!.1]!
                    let old = Tile.tiles[mode.rawValue]![chain!.last!.0][chain!.last!.1]!
                    let new = Tile.tiles[mode.rawValue]![point.0][point.1]!
                    let p = old.node!.position
                    let p2 = Tile.tiles[mode.rawValue]![point.0][point.1]!.node!.position
                    let color = first.color == new.color ? Tile.getColor(first.color) : UIColor.blackColor()
                    chain!.append((point.0,point.1,drawLine(from: p, to: p2, color: color, z: -12)))
                }
            }
        } else {
            if (chain != nil) {
                clearChain()
            }
        }
    }
    
    func distance(from source: CGPoint, to destination: CGPoint) -> Double {
        let x = source.x-destination.x
        let y = source.y-destination.y
        let xs = x*x
        let ys = y*y
        return Double(sqrt(xs+ys))
    }
    
    func findPoint(location: CGPoint) -> (Int, Int)? {
        var x = 0
        var y = 0
        for o in Tile.tiles[mode.rawValue]! {
            y = 0
            for i in o {
                if (i != nil) {
                    let xd = abs(i!.node!.position.x-location.x)
                    let yd = abs(i!.node!.position.y-location.y)
                    if (xd <= CGFloat(Tile.size+Tile.spacing)/2 && yd <= CGFloat(Tile.size+Tile.spacing)/2) {
                        return (x: x,y: y)
                    }
                }
                y += 1
            }
            x += 1
        }
        return nil
    }
    
    func movePoint(from source: (Int,Int), to destination: (Int,Int)) {
        movePoint(from: source, to: destination, update: true)
    }
    
    func movePoint(from source: (Int,Int), to destination: (Int,Int), update shouldUpdate: Bool) {
        if (Tile.tiles[mode.rawValue]![source.0][source.1] == nil || Tile.tiles[mode.rawValue]![destination.0][destination.1] == nil || check(source) && check(destination)) {
            let transition = Tile.tiles[mode.rawValue]![destination.0][destination.1]
            Tile.tiles[mode.rawValue]![destination.0][destination.1] = Tile.tiles[mode.rawValue]![source.0][source.1]
            Tile.tiles[mode.rawValue]![source.0][source.1] = transition
            if (shouldUpdate) {
                update()
            }
        }
    }
    
    func shuffle() {
        shuffling = true
        for x in 0..<Tile.width {
            for y in 0..<Tile.height {
                shufflePoint((x,y), update: false)
            }
        }
        update()
        shuffling = false
    }
    
    func shufflePoint(point: (Int,Int)) {
        shufflePoint(point, update: false)
    }
    
    func shufflePoint(point: (Int,Int), update: Bool) {
        movePoint(from: point, to: (Int(arc4random_uniform(UInt32(Tile.width))),Int(arc4random_uniform(UInt32(Tile.height)))),update: update)
    }
    
    func getPoint(x: Int, _ y: Int) -> CGPoint {
        let pivot = Double(Tile.size+Tile.spacing)
        let xp = Double(size.width)/2-pivot*Double(Tile.width-1)/2
        let yp = Double(size.height)/2-pivot*Double(Tile.height-1)/2
        return CGPoint(x: Double(x)*pivot+xp, y: Double(y)*pivot+yp)
    }
    
    func getPoint(x: Int, _ y: Int, gridSize: (Int,Int), tileSize: (Int, Int), spacing: (Int, Int), offset: Int) -> CGPoint {
        let pivotx = Double(tileSize.0+spacing.0)
        let pivoty = Double(tileSize.1+spacing.1)
        let xp = Double(size.width)/2-pivotx*Double(gridSize.0-1)/2
        let yp = Double(size.height)/2-pivoty*Double(gridSize.1-1)/2
        return CGPoint(x: Double(x)*pivotx+xp, y: Double(y)*pivoty+yp-Double(offset))
    }
    /*
    func dropNode(x: Int) {
        createNode(x: x, y: Tile.height-1, drop: true)
    }
    
    func createNode(x x: Int, y: Int, drop: Bool) {
        let color = Int(arc4random_uniform(UInt32(colors)))
        createNode(x: x, y: y, drop: drop, color: color)
    }
    
    func createNode(x x: Int, y: Int, drop: Bool, color: Int) {
        createNode(x: x, y: y, drop: drop, color: color, wildcard: false)
    }
    
    func createNode(x x: Int, y: Int, drop: Bool, color: Int, powerup: Int) {
        createNode(x: x, y: y, drop: drop, color: color, wildcard: false, powerup: powerup)
    }
    
    func createNode(x x: Int, y: Int, drop: Bool, color: Int, wildcard: Bool) {
        createNode(x: x, y: y, drop: drop, color: color, wildcard: wildcard, powerup: -1)
    }
    
    func createNode(x x: Int, y: Int, drop: Bool, wildcard: Bool) {
        let color = Int(arc4random_uniform(UInt32(colors)))
        createNode(x: x, y: y, drop: drop, color: color, wildcard: wildcard)
    }
    
    func createNode(x x: Int, y: Int, drop: Bool, powerup: Int) {
        let color = Int(arc4random_uniform(UInt32(colors)))
        createNode(x: x, y: y, drop: drop, color: color, powerup: powerup)
    }
    
    func createNode(x x: Int, y: Int, drop: Bool, color: Int, wildcard wc: Bool, powerup pu: Int) {
        if (nodes[x][y] == nil) {
            var wildcard = wc
            var powerup = min(pu,powerups)
            if (!wc && powerup == -1 && level > 0 && !restoring) {
                wildcard = Int(arc4random_uniform(432/UInt32(getDiff()))) == 0
            }
            if (powerup == -1 && powerups > 0 && !wildcard && Int(arc4random_uniform(864/UInt32(getDiff()))) == 0 && !restoring) {
                powerup = Int(arc4random_uniform(UInt32(powerups)))
            }
//            let shape = Int(arc4random_uniform(UInt32(shapes)))
            /*switch(shape) {
            case 0: //Circle
                product = SKShapeNode(circleOfRadius: CGFloat(Double(Tile.size)/2))
            case 1: //Triangle
                let path = CGPathCreateMutable()
                CGPathMoveToPoint(path, nil, -CGFloat(Tile.size)/2, -CGFloat(Tile.size)/2)
                CGPathAddLineToPoint(path, nil, CGFloat(Tile.size)/2 , -CGFloat(Tile.size)/2)
                CGPathAddLineToPoint(path, nil, 0, CGFloat(Tile.size)/2)
                CGPathCloseSubpath(path)
                product = SKShapeNode()
                product!.path = path
            case 2: //Square
                product = SKShapeNode(rectOfSize: CGSize(width: Tile.size, Tile.height: Tile.size))
            default:
                break
             }*/
            let product = circle.copy() as! SKShapeNode
            if (powerup != -1) {
                product.addChild(SKSpriteNode(imageNamed: Grid.powerupNames[powerup]))
            }
            product.fillColor = wildcard ? UIColor.whiteColor() : Grid.getColor(color)
            product.strokeColor = wildcard ? UIColor.blackColor() : Grid.getColor(color)
            product.lineWidth = 3.0
            product.position = getPoint(x,y)
            if (drop) {
                product.position.y = size.height+CGFloat(Tile.size+Tile.spacing)/2
                falling[x] = product
            }
            nodes[x][y] = (product,0,wildcard ? -1 : color,false,wildcard,powerup)
            addChild(product)
        }
    } */
    
    func checkColor(x: [Int], _ y: [Int]) -> Bool {
        var color = Tile.Color.None
        for i in 0..<min(x.count, y.count) {
            if (Tile.tiles[mode.rawValue]![x[i]][y[i]] != nil) {
                if (color == .None) {
                    color = Tile.tiles[mode.rawValue]![x[i]][y[i]]!.color
                } else if (color != Tile.tiles[mode.rawValue]![x[i]][y[i]]!.color && Tile.tiles[mode.rawValue]![x[i]][y[i]]!.color != .None) {
                    return false
                }
            }
        }
        if (chain!.count > 1 && color != .None) {
            for i in 0..<min(x.count, y.count) {
                if (Tile.tiles[mode.rawValue]![x[i]][y[i]]!.type == .Wildcard) {
                    Tile.tiles[mode.rawValue]![x[i]][y[i]]!.node!.fillColor = Tile.getColor(color)
                    Tile.tiles[mode.rawValue]![x[i]][y[i]]!.color = color
                }
            }
            for (x, y, l) in chain! {
                if (Tile.tiles[mode.rawValue]![x][y]!.type == .Wildcard) {
                    Tile.tiles[mode.rawValue]![x][y]!.node!.fillColor = Tile.getColor(color)
                    Tile.tiles[mode.rawValue]![x][y]!.color = color
                }
                if (l != nil) {
                    l!.strokeColor = Tile.getColor(color)
                }
            }
        }
        return true
    }
    
    static func newUpgrade(level: Int) {
        lc = true
        switch (level) {
        case -1:
            Tile.setColors(1)
            Tile.resize(3,1)
            display.sub = "Wildcards"
        case 0:
            Tile.setColors(2)
            Tile.resize(3,2)
            display.sub = "Swapping"
        case 1:
            Tile.setColors(3)
            Tile.resize(4,4)
            display.sub = "Good Luck"
        case 2:
            diffs = 2
            display.sub = "Hard Difficulty Unlocked"
        case 3:
            Tile.resize(4,5)
            display.sub = "Bigger Grid Unlocked"
        case 4:
            modes = 2
            display.sub = "Timed Mode Unlocked"
        case 5:
            Tile.setColors(4)
            display.sub = "New Color Unlocked"
        case 6:
            Tile.unlockPowerup(.Shuffle)
            newPowerup = true
            display.sub = "Shuffle Power-Up Unlocked"
        case 7:
            display.sub = "Challenges Unlocked"
        case 8:
            Tile.resize(5,6)
            display.sub = "Bigger Grid Unlocked"
        case 9:
            Tile.unlockPowerup(.Explode)
            newPowerup = true
            display.sub = "Explode Power-Up Unlocked"
        case 10:
            Tile.resize(6,7)
            display.sub = "Bigger Grid Unlocked"
        case 11:
            modes = 3
            display.sub = "Moves Mode Unlocked"
        case 12:
            Tile.unlockPowerup(.ClearColor)
            newPowerup = true
            display.sub = "Clear Power-Up Unlocked"
        case 13:
            Tile.resize(6,8)
            display.sub = "Bigger Grid Unlocked"
        case 14:
            Tile.setColors(5)
            display.sub = "New Color Unlocked"
        case 15:
            Tile.unlockPowerup(.Star)
            newPowerup = true
            display.sub = "Star Power-Up Unlocked"
        case 16:
            Tile.resize(6,9)
            display.sub = "Bigger Grid Unlocked"
        case 17:
            Tile.setColors(6)
            display.sub = "New Color Unlocked"
        case 18:
            Tile.unlockPowerup(.EnergyBoost)
            newPowerup = true
            display.sub = "Energy Boost Unlocked"
        case 19:
            Tile.resize(7,9)
            display.sub = "Bigger Grid Unlocked"
        case 20:
            Tile.unlockPowerup(.WildcardBomb)
            newPowerup = true
            display.sub = "Wildcard Bomb Unlocked"
        case 21:
            Tile.resize(7,10)
            display.sub = "Biggest Grid Unlocked"
        default:
            break
        }
    }
    
    func levelUp() {
        Grid.winSound?.play()
        Grid.xp = min(max(Grid.xp-Grid.maxXP(),0),288)
        Grid.level = min(Grid.level+1,Grid.maxLevel)
        Grid.newUpgrade(Grid.level)
        if (Grid.level <= 0) {
            Grid.display.main = "Tutorial \(Grid.level+3)"
        } else {
            Grid.display.main = Grid.level == Grid.maxLevel ? "Level \(Grid.level) (MAX)" : "Level \(Grid.level)"
        }
        if (Grid.level <= 1) {
            Grid.xp = 0
        }
        Challenge.challenge?.points(pointsSoFar)
        reset()
    }
    
    func die() {
        Grid.dieSound?.play()
        Grid.xp = max(Grid.xp-Tile.rg((864,2048)),0)
        if (mode == .Standard) {
            Grid.display.main = "You Died"
        } else if (mode == .Moves) {
            Grid.display.main = "Round Over"
        } else if (mode == .Timed) {
            Grid.display.main = "Game Over"
        }
        Grid.display.sub = "Score: \(GameViewController.number(pointsSoFar))\(pointsSoFar >= record!.points ? " (High Score)" : "")"
        Challenge.challenge?.points(pointsSoFar)
        record?.points(pointsSoFar)
        if (mode != .Moves) {
            Challenge.challenge?.die()
        }
        pointsSoFar = 0
        reset()
    }
    
    func reset() {
        if (!gridPaused) {
            started = false
        }
        running = false
        swaps = 0
        if (!gridPaused) {
            falling = [SKShapeNode?](count: Tile.width, repeatedValue: nil)
            for i in Tile.tiles[mode.rawValue]! {
                for o in i {
                    if (o != nil) {
                        o!.node!.removeFromParent()
                    }
                }
            }
            xpBar?.clearBar()
            energyBar?.clearBar()
            xpBar = nil
            energyBar = nil
        }
        record?.points(pointsSoFar)
        Challenge.challenge?.check()
        clearChain()
        frames = 0
        Grid.lc = true
        GameViewController.cont?.performSegueWithIdentifier("pause", sender: nil)
    }
    
    func restore() {
        if (Grid.level >= 7) {
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert, categories: nil))
        }
        lastTime = NSDate().timeIntervalSince1970
        running = true
        if (!gridPaused) {
            started = false
            Tile.reset(mode)
            energy = Grid.maxEnergy
            if (Grid.level == -1) {
                Tile.tiles[mode.rawValue]![1][0] = Tile(x: 1, y: 0, type: .Wildcard, drop: false, grid: self)
            } else if (Grid.newPowerup) {
                let x = Int(arc4random_uniform(UInt32(Tile.width)))
                let y = Int(arc4random_uniform(UInt32(Tile.height)))
                Tile.tiles[mode.rawValue]![x][y] = Tile(x: x, y: y, type: Tile.powerupsUnlocked.last!, drop: false, grid: self)
                Grid.newPowerup = false
            }
            if (Grid.level != 0) {
                for x in 0..<Tile.width {
                    for y in 0..<Tile.height {
                        if (Tile.tiles[mode.rawValue]![x][y] == nil) {
                            Tile.tiles[mode.rawValue]![x][y] = Tile(x: x, y: y, drop: false, grid: self)
                        }
                    }
                }
            } else {
                Tile.tiles[mode.rawValue]![0][0] = Tile(x: 0, y: 0, color: .Blue, type: .Normal, drop: false, grid: self)
                Tile.tiles[mode.rawValue]![1][0] = Tile(x: 1, y: 0, color: .Blue, type: .Normal, drop: false, grid: self)
                Tile.tiles[mode.rawValue]![2][0] = Tile(x: 2, y: 0, color: .Green, type: .Normal, drop: false, grid: self)
                Tile.tiles[mode.rawValue]![2][1] = Tile(x: 2, y: 1, color: .Blue, type: .Normal, drop: false, grid: self)
            }
            saveAll()
        } else {
            gridPaused = false
        }
        Challenge.new()
        Challenge.challenge?.check()
        sc = 0
        Grid.lc = true
        if (Grid.level <= 1) {
            if (Grid.level == 1 && Grid.xp == 0) {
                makeLabel("Fill the Green Bar to Level Up")
            } else if (Grid.level == -2) {
                makeLabel("Draw a Line Between the Dots")
            } else if (Grid.level == -1) {
                makeLabel("Wildcards Can Be Any Color")
            } else if (Grid.level == 0) {
                makeLabel("You Can Swap Dots, But It Takes Energy")
            }
        } else {
            deleteLabel()
        }
        update()
        saveAll()
    }
    
    func makeLabel(n: String) {
        if (label === nil) {
            label = SKLabelNode(fontNamed: Grid.font)
            addChild(label!)
        }
        label!.text = n
        label!.fontSize = 16
        label!.hidden = false
        label!.zPosition = 512
        label!.fontColor = UIColor.blackColor()
        label!.position = getPoint(0, Tile.height, gridSize: (1,1), tileSize: (Tile.size,Tile.size), spacing: (Tile.spacing,Tile.spacing), offset: 0)
    }
    
    func deleteLabel() {
        label?.removeFromParent()
        label = nil
    }
    
    override func update(currentTime: NSTimeInterval) {
        update()
    }
    
    func update() {
        if (running) {
            Challenge.challenge?.points(pointsSoFar)
            var i = 0
            if (Grid.level < Grid.maxLevel && Grid.level > 0) {
                if (xpBar == nil) {
                    xpBar = Bar(current: Grid.xp, max: Grid.maxXP(), color: Tile.getColor(.Green), index: 0, text: nil, grid: self)
                } else {
                    xpBar!.updateBar(Grid.xp)
                }
                i += 1
            } else {
                xpBar?.clearBar()
            }
            if (Grid.level >= 0) {
                if (energyBar == nil) {
                    energyBar = Bar(current: energy, max: Grid.maxEnergy, color: Tile.getColor(.Yellow), index: i, text: nil, grid: self)
                } else {
                    energyBar!.updateBar(energy)
                }
            } else {
                energyBar?.clearBar()
            }
            if (Grid.xp >= Grid.maxXP() && Grid.level < Grid.maxLevel) {
                levelUp()
            } else if (energy == 0) {
                die()
            }
            var x = 0
            var y = 0
            let d = NSDate().timeIntervalSince1970 - lastTime
            if (mode == .Timed && freezeMoves == 0 && started && d >= 1) {
                energy = max(energy - Grid.maxEnergy/Grid.time, 0)
                if (energy <= (mode == .Moves ? Grid.moveEnergy*3 : Grid.energyThreshold) && energy > 0) {
                    Grid.timeSound?.play()
                }
                sc += 1
                if (d > 4) {
                    lastTime = (NSDate().timeIntervalSince1970)-3
                } else {
                    lastTime += 1
                }
                if (Challenge.challenge != nil) {
                    Challenge.challenge!.survive(1)
                }
            }
            Challenge.new()
            for o in Tile.tiles[mode.rawValue]! {
                y = 0
                for i in o {
                    if (i != nil && running) {
                        let p = getPoint(x, y)
                        if (i!.node!.position != p && Tile.tiles[mode.rawValue]![x][y]!.move == false) {
                            Tile.tiles[mode.rawValue]![x][y]!.move = true
                            i!.node!.removeAllActions()
                            i!.node!.runAction(SKAction.moveTo(p, duration: shuffling ? 0.5 : distance(from: i!.node!.position, to: p)/576))
                        } else if (y - 1 >= 0 && Tile.tiles[mode.rawValue]![x][y-1] == nil && Grid.level > 0) {
                            var v: Int = y
                            for v2 in 1...y {
                                if (Tile.tiles[mode.rawValue]![x][y-v2] != nil) {
                                    break
                                } else {
                                    v = y-v2
                                }
                            }
                            movePoint(from: (x, y), to: (x, v), update: false)
                            i!.node!.removeAllActions()
                            i!.node!.runAction(SKAction.moveTo(getPoint(x,v), duration: shuffling ? 0.5 : distance(from: i!.node!.position, to: getPoint(x,v))/576))
                            Tile.tiles[mode.rawValue]![x][v]!.move = true
                            if (running && y == Tile.height-1 && (falling[x] == nil || falling[x]!.position.y <= size.height-(CGFloat(Tile.size)/2+CGFloat(Tile.spacing)))) {
                                Tile.tiles[mode.rawValue]![x][Tile.height-1] = Tile(x: x, y: Tile.height-1, drop: true, grid: self)
                            }
                        } else if (Tile.tiles[mode.rawValue]![x][y] != nil && Tile.tiles[mode.rawValue]![x][y]!.move && i!.node!.position == p) {
                            Tile.tiles[mode.rawValue]![x][y]!.move = false
                        }
                    } else if (running && y == Tile.height-1 && (falling[x] == nil || falling[x]!.position.y <= size.height-(CGFloat(Tile.size)/2+CGFloat(Tile.spacing))) && Grid.level > 0) {
                        Tile.tiles[mode.rawValue]![x][Tile.height-1] = Tile(x: x, y: Tile.height-1, drop: true, grid: self)
                    }
                    y += 1
                }
                x += 1
            }
        }
    }
}