//
//  Grid.swift
//  Connect
//
//  Created by Scott Taylor on 5/16/16.
//  Copyright © 2016 Scott Taylor. All rights reserved.
//

import Foundation
import SpriteKit

class Grid: SKScene {
    static let basePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    static let lvlsys = 13
    static let maxEnergy = 144
    static let maxLevel = 21
    static let font = "Helvetica Neue"
    static let time = 8 //seconds
    static let versionPath = Grid.basePath + "/version.txt"
    static let savePath = Grid.basePath + "/save\(String(Grid.lvlsys)).txt"
    static let lastSavePath = Grid.basePath + "/save\(Grid.getLastVersionString()).txt"
    var labelNode: SKLabelNode?
    var subLabelNode: SKLabelNode?
    var chain: [(Int,Int,SKShapeNode?)]?
    var chainLine: SKShapeNode?
    var falling: [SKShapeNode?] = []
    var energy = maxEnergy
    var level = -2
    var xp = 0
    var swaps = 0
    var frames = 0
    var started = false
    var running = false
    var diff = 0
    var mode = 1
    var continued = -1
    var diffs: [String] = ["Easy"]
    var modes: [String] = ["Standard"]
    var diffNodes: [SKNode] = []
    var modeNodes: [SKNode] = []
    var continueNodes: [SKNode] = []
    var points = 0
    var lastTime = NSDate().timeIntervalSince1970
    var gridPaused = false
    var deaths = 0
    var newPowerup = false
    var freezeMoves = 0
    var restoring = false
    var shuffling = false
    var notifications = false
    var sc: Int = 0
    var lc = true
    var mXP = 1
    var xpBar: Bar?
    var energyBar: Bar?
    
    deinit {
        print("DEINIT GRID")
        save()
        Tile.removeGrid(self)
    }
    
    override init(size: CGSize) {
        print("INIT GRID")
        super.init(size: size)
        backgroundColor = UIColor.whiteColor()
        print("Save Path: \(Grid.savePath)")
        Tile.setScene(self)
        load()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            if (findPoint(location) != nil || !running || location.y > size.height-12) {
                move(location)
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            if (location.y <= size.height-12) {
                move(location)
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        releaseChain()
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        cancel()
        if (touches != nil) {
            for touch in touches! {
                let location = touch.locationInNode(self)
                if (location.y > size.height-12) {
                    debugMenu()
                }
            }
        }
    }
    
    func debugPopup() {
        let alert = UIAlertController(title: "Debug Menu", message: "Enter Command", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.text = self.saveData().joinWithSeparator(",")
        })
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            let textField = alert.textFields![0] as UITextField
            if (textField.text!.hasPrefix("RUN:")) {
                let c = textField.text!.lowercaseString.componentsSeparatedByString(",")
                switch (c[0]) {
                case "run:save":
                    self.save(self.saveData(), path: Grid.basePath+"/debugSave.txt")
                case "run:restore":
                    self.removeAllChildren()
                    self.loadData(Grid.basePath+"/debugSave.txt")
                case "run:shuffle":
                    self.shuffle()
                case "run:cooldown":
                    Tile.cooldown = 0
                case "run:party":
                    Tile.cooldown = -512
                case "run:challenge":
                    Challenge.lastChallenge = NSDate(timeIntervalSince1970: 0)
                    Challenge.new()
                case "run:pause":
                    if (c.count == 1) {
                        self.pause()
                    } else if (c.count == 2) {
                        self.gridPaused = c[1].lowercaseString == "true" || c[1].lowercaseString == "yes" || c[1].lowercaseString == "1"
                    }
                default:
                    print("No Debug Options Found for \"\(textField.text!)\"")
                }
            } else {
                self.save(textField.text!.componentsSeparatedByString(","))
                self.removeAllChildren()
                self.load()
            }
        }))
        GameViewController.cont!.presentViewController(alert, animated: true, completion: nil)
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
    
    func saveData() -> [String] {
        if (running || gridPaused) {
            let a = ["RES",String(level),String(xp),String(energy),String(diff),String(mode)]
            let b = [String(points),String(swaps),String(deaths)]
            let c = [String(freezeMoves),Tile.getData(),Challenge.save()]
            return a+b+c
        } else {
            let a = ["NEW",String(level),String(xp),String(diff),String(mode)]
            let b = [String(deaths),String(points),labelNode!.text!,subLabelNode!.text!,Challenge.save()]
            return a+b
        }
    }
    
    func save() {
        save(saveData())
    }
    
    func debugMenu() {
        debugPopup()
    }
    
    func load() {
        load(nil)
    }
    
    func load(path: String?) {
        Tile.setGrid(self)
        Tile.resize(3, 1)
        Tile.setColors(1)
        Tile.powerupsUnlocked = []
        level = -2
        xp = 0
        energy = Grid.maxEnergy
        swaps = 0
        deaths = 0
        diff = 0
        mode = 1
        freezeMoves = 0
        points = 0
        diffs = ["Easy"]
        modes = ["Standard"]
        newPowerup = false
        cancel()
        started = false
        gridPaused = false
        restoring = true
        if let a = loadAll(path) {
            if (a.count == 10 && a[0] == "NEW") {
                level = Int(a[1])!
                diff = Int(a[3])!
                mode = Int(a[4])!
                deaths = Int(a[5])!
                points = Int(a[6])!
                newLabel(a[7])
                if (level > -2) {
                    for i in -1...level {
                        newUpgrade(i)
                    }
                    newSubLabel(a[8])
                    falling = [SKShapeNode?](count: Tile.width, repeatedValue: nil)
                    Tile.reset()
                    restoring = false
                    xp = Int(a[2])!
                    Challenge.load(a[9])
                    reset()
                    return
                }
            } else if (a.count == 12 && a[0] == "RES"){
                level = Int(a[1])!
                energy = Int(a[3])!
                diff = Int(a[4])!
                mode = Int(a[5])!
                points = Int(a[6])!
                swaps = Int(a[7])!
                deaths = Int(a[8])!
                freezeMoves = Int(a[9])!
                if (level > -2) {
                    for i in -1...level {
                        newUpgrade(i)
                    }
                    Tile.loadData(a[10])
                    falling = [SKShapeNode?](count: Tile.width, repeatedValue: nil)
                    restoring = false
                    xp = Int(a[2])!
                    Challenge.load(a[11])
                    forcePause()
                    return
                }
            } else if (a.count == 4 && a[0] == "DEL") {
                print("All Save Data Deleted at \(a[1]) from Level \(a[2]) with \(a[3]) Points")
            } else if (a.count >= 2 && a[0] == "DEL") {
                print("All Save Data Deleted: \(a.joinWithSeparator(","))")
            } else if (a.count == 1 && a[0] == "DEL") {
                print("All Save Data Deleted")
            } else {
                print("Incorrect Save Format (\(a.count))")
            }
        } else {
            print("Unable to Load Data")
        }
        falling = [SKShapeNode?](count: Tile.width, repeatedValue: nil)
        restoring = false
        newLabel("Tutorial 1")
        newSubLabel("Connections")
        reset()
    }
    
    func save(array: [String]) {
        save(array, path: Grid.savePath)
    }
    
    func save(array: [String], path: String) {
        let j = array.joinWithSeparator(",")
        print("Save: \(j)")
        do {
            try j.writeToFile(path, atomically: true, encoding: NSASCIIStringEncoding)
            try String(Grid.lvlsys).writeToFile(Grid.versionPath, atomically: true, encoding: NSASCIIStringEncoding)
        } catch {
            print("Unable to write data")
        }
    }
    
    func pause() {
        save()
        if (running) {
            forcePause()
        }
    }
    
    func maxXP() -> Int {
        return maxXP(level, Grid.lvlsys, lc: lc, u: true)
    }
    
    func maxXP(level: Int) -> Int {
        return maxXP(level, Grid.lvlsys, lc: true, u: false)
    }
    
    func maxXP(level: Int, _ lvlsys: Int) -> Int {
        return maxXP(level, lvlsys, lc: true, u: false)
    }
    
    func maxXP(level: Int, _ lvlsys: Int, lc: Bool, u: Bool) -> Int {
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
    
    func fixXP(lvl: Int, _ exp: Int, _ l1: Int) -> (Int, Int) {
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
    
    func loadAll(path: String?) -> [String]? {
        if (path == nil || path == Grid.basePath) {
            return loadAll()
        } else {
            return loadData(path!)
        }
    }
    
    func loadAll() -> [String]? {
        if (Grid.lastSavePath == Grid.savePath) {
            return loadData(Grid.savePath)
        }
        if var last = loadData(Grid.lastSavePath) {
            if (last.count >= 8 && (last[0] == "NEW" || last[0] == "RES")) {
                let (level, xp) = fixXP(Int(last[1])!,Int(last[2])!,Grid.getLastVersion())
                let p = last[6]
                let diff = level - Int(last[1])!
                last.removeAll(keepCapacity: true)
                last.append("NEW")
                last.append(String(level))
                last.append(String(xp))
                last.append("0")
                last.append("1")
                last.append("0")
                last.append(p)
                last.append("Level \(level)\((level == Grid.maxLevel ? " (MAX)" : ""))")
                last.append("Update Successful")
                last.append("0")
                print("Updated Format (\(diff) levels): \(last.joinWithSeparator(","))")
                return last
            }
        }
        return nil
    }
    
    func loadData(path: String) -> [String]? {
        do {
            let c = try String(contentsOfFile: path, encoding: NSASCIIStringEncoding)
            print("Load: \(c)")
            return c.componentsSeparatedByString(",")
        } catch {
            return nil
        }
    }
    
    func forcePause() {
        gridPaused = true
        newLabel("Paused")
        newSubLabel("Points: \(points)")
        reset()
    }
    
    func newLabel(text: String) {
        if (labelNode != nil) {
            labelNode!.removeFromParent()
        }
        labelNode = SKLabelNode(fontNamed: Grid.font)
        labelNode!.position = getPoint(0, 5, gridSize: (1,7), tileSize: (36,36), spacing: (0,0), offset: 6)
        labelNode!.fontSize = 36
        labelNode!.fontColor = UIColor.blackColor()
        labelNode!.text = text
        labelNode!.zPosition = -143
        addChild(labelNode!)
    }
    
    func newSubLabel(text: String) {
        if (subLabelNode != nil) {
            subLabelNode!.removeFromParent()
        }
        subLabelNode = SKLabelNode(fontNamed: Grid.font)
        subLabelNode!.position = getPoint(0, 4, gridSize: (1,7), tileSize: (36,36), spacing: (0,0), offset: 0)
        subLabelNode!.fontSize = 18
        subLabelNode!.fontColor = UIColor.blackColor()
        subLabelNode!.text = text
        subLabelNode!.zPosition = -143
        addChild(subLabelNode!)
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
                        let nn = Tile.tiles[x+i][y+o] != nil && Tile.tiles[chain!.first!.0][chain!.first!.1] != nil
                        if (nn && Tile.tiles[x+i][y+o]!.color == Tile.tiles[chain!.first!.0][chain!.first!.1]!.color) {
                            v += 1
                        }
                    }
                }
            }
        }
        return v
    }
    
    func check(point: (Int,Int)) -> Bool {
        return !Tile.tiles[point.0][point.1]!.move
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
            if (point.y > size.height-12) {
                pause()
                return
            }
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
                let first = Tile.tiles[chain!.first!.0][chain!.first!.1]!
                let old = Tile.tiles[chain!.last!.0][chain!.last!.1]!
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
                if (Tile.tiles[x][y] != nil && Tile.tiles[x][y]!.type == .Wildcard) {
                    Tile.tiles[x][y]!.color = .None
                    Tile.tiles[x][y]!.node!.fillColor = UIColor.whiteColor()
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
        return max(0,diff)*2+max(0,mode)*3+1
    }
    
    func runPowerup(type: Tile.SpecialType, color: Tile.Color, _ xb: Int, _ yb: Int) {
        switch (type) {
        case .Shuffle:
            shuffle()
            let i = 48
            xp += i
            points += i
            if (Challenge.challenge != nil) {
                Challenge.challenge!.points(i)
            }
        case .Explode:
            var pus: [(Tile.SpecialType, Tile.Color, Int, Int)] = []
            for x in max(xb-3,0)..<min(xb+3,Tile.width) {
                for y in max(yb-3,0)..<min(yb+3,Tile.height) {
                    if (Tile.tiles[x][y] != nil && distance(from: CGPoint(x: x, y: y), to: CGPoint(x: xb, y: yb)) <= 2.75) {
                        let i = Tile.tiles[x][y]!.type == .Wildcard ? 36 : 9
                        xp += i
                        points += i
                        if (Challenge.challenge != nil) {
                            Challenge.challenge!.points(i)
                        }
                        let t = Tile.tiles[x][y]!.type
                        if (Challenge.challenge != nil) {
                            Challenge.challenge!.clear(Tile.tiles[x][y]!.color, type: t)
                        }
                        if (t != .Normal && t != .Wildcard) {
                            xp += 18
                            points += 18
                            if (Challenge.challenge != nil) {
                                Challenge.challenge!.points(18)
                            }
                            pus.append((t,Tile.tiles[x][y]!.color, x, y))
                        }
                        Tile.tiles[x][y]!.node!.removeFromParent()
                        Tile.tiles[x][y] = nil
                    }
                }
            }
            for (a, b, x, y) in pus {
                runPowerup(a, color: b, x, y)
            }
        case .ClearColor:
            var pus: [(Tile.SpecialType, Tile.Color, Int, Int)] = []
            for x in 0..<Tile.width {
                for y in 0..<Tile.height {
                    if (Tile.tiles[x][y] != nil && Tile.tiles[x][y]!.color == color && Tile.tiles[x][y]!.type != .Wildcard) {
                        let i = 9
                        xp += 9
                        points += 9
                        if (Challenge.challenge != nil) {
                            Challenge.challenge!.points(i)
                        }
                        let t = Tile.tiles[x][y]!.type
                        if (Challenge.challenge != nil) {
                            Challenge.challenge!.clear(Tile.tiles[x][y]!.color, type: t)
                        }
                        if (t != .Normal && t != .Wildcard && t != .ClearColor) {
                            xp += 18
                            points += 18
                            if (Challenge.challenge != nil) {
                                Challenge.challenge!.points(18)
                            }
                            pus.append((t,Tile.tiles[x][y]!.color, x, y))
                        }
                        Tile.tiles[x][y]!.node!.removeFromParent()
                        Tile.tiles[x][y] = nil
                    }
                }
            }
            for (a, b, x, y) in pus {
                runPowerup(a, color: b, x, y)
            }
        case .Star:
            var pus: [(Tile.SpecialType, Tile.Color, Int, Int)] = []
            let x = xb
            for y in 0..<Tile.height {
                if (Tile.tiles[x][y] != nil) {
                    let i = Tile.tiles[x][y]!.type == .Wildcard ? 36 : 9
                    xp += i
                    points += i
                    if (Challenge.challenge != nil) {
                        Challenge.challenge!.points(i)
                    }
                    let t = Tile.tiles[x][y]!.type
                    if (Challenge.challenge != nil) {
                        Challenge.challenge!.clear(Tile.tiles[x][y]!.color, type: t)
                    }
                    if (t != .Normal && t != .Wildcard) {
                        xp += 18
                        points += 18
                        if (Challenge.challenge != nil) {
                            Challenge.challenge!.points(18)
                        }
                        pus.append((t,Tile.tiles[x][y]!.color, x, y))
                    }
                    Tile.tiles[x][y]!.node!.removeFromParent()
                    Tile.tiles[x][y] = nil
                }
            }
            let y = yb
            for x in 0..<Tile.width {
                if (Tile.tiles[x][y] != nil) {
                    let i = Tile.tiles[x][y]!.type == .Wildcard ? 36 : 9
                    xp += i
                    points += i
                    if (Challenge.challenge != nil) {
                        Challenge.challenge!.points(i)
                    }
                    let t = Tile.tiles[x][y]!.type
                    if (Challenge.challenge != nil) {
                        Challenge.challenge!.clear(Tile.tiles[x][y]!.color, type: t)
                    }
                    if (t != .Normal && t != .Wildcard) {
                        xp += 18
                        points += 18
                        if (Challenge.challenge != nil) {
                            Challenge.challenge!.points(18)
                        }
                        pus.append((t,Tile.tiles[x][y]!.color, x, y))
                    }
                    Tile.tiles[x][y]!.node!.removeFromParent()
                    Tile.tiles[x][y] = nil
                }
            }
            for (a, b, x, y) in pus {
                runPowerup(a, color: b, x, y)
            }
        case .EnergyBoost:
            freezeMoves += 3
            energy = Grid.maxEnergy
        case .WildcardBomb:
            for x in 0..<Tile.width {
                for y in 0..<Tile.height {
                    if (Tile.tiles[x][y] != nil && Tile.tiles[x][y]!.type == .Normal && Int(arc4random_uniform(6)) == 0) {
                        let i = 6
                        xp += i
                        points += i
                        if (Challenge.challenge != nil) {
                            Challenge.challenge!.points(i)
                        }
                        Tile.tiles[x][y]!.type = .Wildcard
                        Tile.tiles[x][y]!.color = .None
                        Tile.tiles[x][y]!.node!.fillColor = UIColor.whiteColor()
                        Tile.tiles[x][y]!.node!.strokeColor = UIColor.blackColor()
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
            Tile.save += 1
            if (Tile.save >= 6) {
                save()
            }
            var t = chain!.count
            let inf = checkForAll()
            if (inf == 0) {
                t += t-3
            }
            if (chain!.count == 2) {
                let a = Tile.tiles[chain![0].0][chain![0].1]!
                let b = Tile.tiles[chain![1].0][chain![1].1]!
                if (a.color != b.color || a.type != b.type) {
                    if (Challenge.challenge != nil) {
                        Challenge.challenge!.swap()
                    }
                    if (freezeMoves == 0) {
                        energy = max(energy-Int(exp2(Double(min(swaps+1,6)))*((mode == 2) ? 4 : 6)),0)
                        swaps += 1
                    } else {
                        freezeMoves -= 1
                    }
                    movePoint(from: (chain!.first!.0,chain!.first!.1), to: (chain!.last!.0,chain!.last!.1))
                    clearChain()
                    return
                }
            } else if (chain!.count > 2 && (inf == 0 || diff != 1)) {
                let t2 = (inf+Int(exp2(Double(inf)))-t)/(max(1,mode)*2)
                let t3 = Int(exp2(Double(min(t-2,10))))*(max(1,mode)*3)
                if (diff != 1 || inf == 0) {
                    energy = min((energy+t3*2),Grid.maxEnergy)
                } else {
                    energy = min(max(energy+t3-t2,0),Grid.maxEnergy)
                }
                let increase = max(min(max(Int(exp2(Double(min(t-2,4))))-(swaps*2),0)+t-t2,maxXP()),0)*getDiff()
                if (mode == 2 && freezeMoves > 0) {
                    freezeMoves -= 1
                }
                if (Challenge.challenge != nil) {
                    Challenge.challenge!.chain(chain!.count)
                }
                if (Challenge.challenge != nil) {
                    Challenge.challenge!.points(increase)
                }
                xp += increase
                points += increase
                swaps = max(swaps-(t/3),0)
                var pus: [(Tile.SpecialType, Tile.Color, Int, Int)] = []
                for (x, y, _) in chain! {
                    if (Tile.tiles[x][y] != nil) {
                        let t = Tile.tiles[x][y]!.type
                        let c = Tile.tiles[x][y]!.color
                        if (Tile.tiles[x][y]!.type == .Wildcard) {
                            xp += 24
                            points += 24
                        }
                        Tile.tiles[x][y]!.node!.removeFromParent()
                        Tile.tiles[x][y] = nil
                        if (Challenge.challenge != nil) {
                            Challenge.challenge!.clear(c, type: t)
                        }
                        if (t != .Wildcard && t != .Normal) {
                            pus.append((t,c, x, y))
                            xp += 12
                            points += 12
                        }
                    }
                }
                for (a,b,x,y) in pus {
                    runPowerup(a, color: b, x, y)
                }
                if (Challenge.challenge != nil) {
                    Challenge.challenge!.check()
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
                    if (Tile.tiles[chain!.last!.0][chain!.last!.1]!.type == .Wildcard) {
                        Tile.tiles[chain!.last!.0][chain!.last!.1]!.color = .None
                        Tile.tiles[chain!.last!.0][chain!.last!.1]!.node!.fillColor = UIColor.whiteColor()
                    }
                    chain!.removeLast()
                    if (chain!.count == 1) {
                        if (Tile.tiles[chain!.first!.0][chain!.first!.1]!.type == .Wildcard) {
                            Tile.tiles[chain!.first!.0][chain!.first!.1]!.color = .None
                            Tile.tiles[chain!.first!.0][chain!.first!.1]!.node!.fillColor = UIColor.whiteColor()
                        }
                    }
                    return
                }
                if (checkChain(point)) {
                    return
                }
                if ((checkColor([chain!.first!.0,chain!.last!.0,point.0],[chain!.first!.1,chain!.last!.1,point.1])) || (chain!.count == 1)) {
                    let first = Tile.tiles[chain!.first!.0][chain!.first!.1]!
                    let old = Tile.tiles[chain!.last!.0][chain!.last!.1]!
                    let new = Tile.tiles[point.0][point.1]!
                    let p = old.node!.position
                    let p2 = Tile.tiles[point.0][point.1]!.node!.position
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
        for o in Tile.tiles {
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
        if (Tile.tiles[source.0][source.1] == nil || Tile.tiles[destination.0][destination.1] == nil || check(source) && check(destination)) {
            let transition = Tile.tiles[destination.0][destination.1]
            Tile.tiles[destination.0][destination.1] = Tile.tiles[source.0][source.1]
            Tile.tiles[source.0][source.1] = transition
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
            if (Tile.tiles[x[i]][y[i]] != nil) {
                if (color == .None) {
                    color = Tile.tiles[x[i]][y[i]]!.color
                } else if (color != Tile.tiles[x[i]][y[i]]!.color && Tile.tiles[x[i]][y[i]]!.color != .None) {
                    return false
                }
            }
        }
        if (chain!.count > 1 && color != .None) {
            for i in 0..<min(x.count, y.count) {
                if (Tile.tiles[x[i]][y[i]]!.type == .Wildcard) {
                    Tile.tiles[x[i]][y[i]]!.node!.fillColor = Tile.getColor(color)
                    Tile.tiles[x[i]][y[i]]!.color = color
                }
            }
            for (x, y, l) in chain! {
                if (Tile.tiles[x][y]!.type == .Wildcard) {
                    Tile.tiles[x][y]!.node!.fillColor = Tile.getColor(color)
                    Tile.tiles[x][y]!.color = color
                }
                if (l != nil) {
                    l!.strokeColor = Tile.getColor(color)
                }
            }
        }
        return true
    }
    
    func newUpgrade(level: Int) {
        lc = true
        switch (level) {
        case -1:
            xp = 0
            Tile.setColors(2)
            Tile.resize(3,2)
            newSubLabel("Swapping")
        case 0:
            xp = 0
            Tile.setColors(1)
            Tile.resize(3,1)
            newSubLabel("Wildcards")
        case 1:
            Tile.setColors(3)
            Tile.resize(4,4)
            newSubLabel("Good Luck")
        case 2:
            diffs.append("Hard")
            newSubLabel("Hard Difficulty Unlocked")
        case 3:
            Tile.resize(4,5)
            newSubLabel("Bigger Grid Unlocked")
        case 4:
            modes.append("Timed")
            newSubLabel("Timed Mode Unlocked")
        case 5:
            Tile.setColors(4)
            newSubLabel("New Color Unlocked")
        case 6:
            Tile.unlockPowerup(.Shuffle)
            newPowerup = true
            newSubLabel("Shuffle Power-Up Unlocked")
        case 7:
            newSubLabel("Challenges Unlocked")
        case 8:
            Tile.resize(5,6)
            newSubLabel("Bigger Grid Unlocked")
        case 9:
            Tile.unlockPowerup(.Explode)
            newPowerup = true
            newSubLabel("Explode Power-Up Unlocked")
        case 10:
            Tile.resize(6,7)
            newSubLabel("Bigger Grid Unlocked")
        case 11:
            Tile.setColors(5)
            newSubLabel("New Color Unlocked")
        case 12:
            Tile.unlockPowerup(.ClearColor)
            newPowerup = true
            newSubLabel("Clear Power-Up Unlocked")
        case 13:
            Tile.resize(6,8)
            newSubLabel("Bigger Grid Unlocked")
        case 14:
            Tile.unlockPowerup(.Star)
            newPowerup = true
            newSubLabel("Star Power-Up Unlocked")
        case 15:
            Tile.setColors(6)
            newSubLabel("New Color Unlocked")
        case 16:
            Tile.resize(6,9)
            newSubLabel("Bigger Grid Unlocked")
        case 17:
            Tile.unlockPowerup(.EnergyBoost)
            newPowerup = true
            newSubLabel("Energy Boost Unlocked")
        case 18:
            Tile.resize(7,10)
            newSubLabel("Bigger Grid Unlocked")
        case 19:
            Tile.unlockPowerup(.WildcardBomb)
            newPowerup = true
            newSubLabel("Wildcard Bomb Unlocked")
        case 20:
            Tile.resize(7,11)
            newSubLabel("Biggest Grid Unlocked")
        case Grid.maxLevel:
            modes = ["Casual", "Standard", "Timed"]
            newSubLabel("Casual Mode Unlocked")
        default:
            break
        }
    }
    
    func levelUp() {
        xp = min(max(xp-maxXP(),0),288)
        level = min(level+1,Grid.maxLevel)
        newUpgrade(level)
        deaths = 0
        if (level <= 0) {
            newLabel("Tutorial \(level+3)")
        } else {
            newLabel(level == Grid.maxLevel ? "Level \(level) (MAX)" : "Level \(level)")
        }
        reset()
        save()
    }
    
    func die() {
        xp = max(xp-Int(exp2(Double(deaths)))*864,0)
        newLabel("You Died")
        newSubLabel("Points: \(points)")
        deaths += 1
        if (Challenge.challenge != nil) {
            Challenge.challenge!.die()
        }
        reset()
        save()
    }
    
    func reset() {
        if (!gridPaused) {
            started = false
        }
        running = false
        swaps = 0
        if (!gridPaused) {
            falling = [SKShapeNode?](count: Tile.width, repeatedValue: nil)
            for i in Tile.tiles {
                for o in i {
                    if (o != nil) {
                        o!.node!.removeFromParent()
                    }
                }
            }
        } else {
            for i in Tile.tiles {
                for o in i {
                    if (o != nil) {
                        o!.node!.hidden = true
                    }
                }
            }
        }
        continued = -1
        xpBar?.clearBar()
        energyBar?.clearBar()
        xpBar = nil
        energyBar = nil
        Challenge.challenge?.check()
        clearChain()
        frames = 0
        lc = true
    }
    
    func restore() {
        if (level >= 7 && !notifications) {
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert, categories: nil))
        }
        continued = -1
        if (labelNode != nil) {
            labelNode!.removeFromParent()
        }
        if (subLabelNode != nil) {
            subLabelNode!.removeFromParent()
        }
        lastTime = NSDate().timeIntervalSince1970
        running = true
        if (!gridPaused) {
            started = false
            Tile.reset()
            energy = Grid.maxEnergy
            if (level == 0) {
                Tile.tiles[1][0] = Tile(x: 1, y: 0, type: .Wildcard, drop: false)
            } else if (newPowerup) {
                let x = Int(arc4random_uniform(UInt32(Tile.width)))
                let y = Int(arc4random_uniform(UInt32(Tile.height)))
                Tile.tiles[x][y] = Tile(x: x, y: y, type: Tile.powerupsUnlocked.last!, drop: false)
                newPowerup = false
            }
            if (level != -1) {
                for x in 0..<Tile.width {
                    for y in 0..<Tile.height {
                        if (Tile.tiles[x][y] == nil) {
                            Tile.tiles[x][y] = Tile(x: x, y: y, drop: false)
                        }
                    }
                }
            } else {
                Tile.tiles[0][0] = Tile(x: 0, y: 0, color: .Blue, type: .Normal, drop: false)
                Tile.tiles[1][0] = Tile(x: 1, y: 0, color: .Blue, type: .Normal, drop: false)
                Tile.tiles[2][0] = Tile(x: 2, y: 0, color: .Green, type: .Normal, drop: false)
                Tile.tiles[2][1] = Tile(x: 2, y: 1, color: .Blue, type: .Normal, drop: false)
            }
            save()
        } else {
            for i in Tile.tiles {
                for o in i {
                    if (o != nil) {
                        o!.node!.hidden = false
                    }
                }
            }
            gridPaused = false
        }
        Challenge.new()
        if (Challenge.challenge != nil) {
            Challenge.challenge!.check()
        }
        sc = 0
        lc = true
        update()
    }
    
    override func update(currentTime: NSTimeInterval) {
        update()
    }
    
    func update() {
        if (running) {
            var i = 0
            if (level < Grid.maxLevel && level > 0) {
                if (xpBar == nil) {
                    xpBar = Bar(current: xp, max: maxXP(), color: Tile.getColor(.Green), index: 0, text: nil)
                } else {
                    xpBar!.updateBar(xp)
                }
                i += 1
            } else {
                xpBar?.clearBar()
            }
            if (mode != 0 && (level > 0 || level == -1)) {
                if (energyBar == nil) {
                    energyBar = Bar(current: energy, max: Grid.maxEnergy, color: Tile.getColor(.Yellow), index: i, text: nil)
                } else {
                    energyBar!.updateBar(energy)
                }
            } else {
                energyBar?.clearBar()
            }
            if (xp >= maxXP() && level < Grid.maxLevel) {
                levelUp()
            } else if (mode != 0 && energy == 0) {
                die()
            }
            var x = 0
            var y = 0
            let d = NSDate().timeIntervalSince1970 - lastTime
            if (mode == 2 && freezeMoves == 0 && started && d >= 1) {
                energy = max(energy - Grid.maxEnergy/Grid.time, 0)
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
            for o in Tile.tiles {
                y = 0
                for i in o {
                    if (i != nil && running) {
                        let p = getPoint(x, y)
                        if (i!.node!.position != p && Tile.tiles[x][y]!.move == false) {
                            Tile.tiles[x][y]!.move = true
                            i!.node!.removeAllActions()
                            i!.node!.runAction(SKAction.moveTo(p, duration: shuffling ? 0.5 : distance(from: i!.node!.position, to: p)/576))
                        } else if (y - 1 >= 0 && Tile.tiles[x][y-1] == nil && level > 0) {
                            var v: Int = y
                            for v2 in 1...y {
                                if (Tile.tiles[x][y-v2] != nil) {
                                    break
                                } else {
                                    v = y-v2
                                }
                            }
                            movePoint(from: (x, y), to: (x, v), update: false)
                            i!.node!.removeAllActions()
                            i!.node!.runAction(SKAction.moveTo(getPoint(x,v), duration: shuffling ? 0.5 : distance(from: i!.node!.position, to: getPoint(x,v))/576))
                            Tile.tiles[x][v]!.move = true
                            if (running && y == Tile.height-1 && (falling[x] == nil || falling[x]!.position.y <= size.height-(CGFloat(Tile.size)/2+CGFloat(Tile.spacing)))) {
                                Tile.tiles[x][Tile.height-1] = Tile(x: x, y: Tile.height-1, drop: true)
                            }
                        } else if (Tile.tiles[x][y] != nil && Tile.tiles[x][y]!.move && i!.node!.position == p) {
                            Tile.tiles[x][y]!.move = false
                        }
                    } else if (running && y == Tile.height-1 && (falling[x] == nil || falling[x]!.position.y <= size.height-(CGFloat(Tile.size)/2+CGFloat(Tile.spacing))) && level > 0) {
                        Tile.tiles[x][Tile.height-1] = Tile(x: x, y: Tile.height-1, drop: true)
                    }
                    y += 1
                }
                x += 1
            }
        } else {
            if (continued == 0 || continued == 1) {
                frames += 1
                if (frames == 6) {
                    frames = 0
                    if (continued == 1) {
                        restore()
                        level = 0
                        levelUp()
                    } else {
                        restore()
                    }
                }
            }
        }
    }
}