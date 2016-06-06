//
//  Challenge.swift
//  Connect
//
//  Created by Scott Taylor on 5/26/16.
//  Copyright © 2016 Scott Taylor. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class Challenge {
    static var challenge: Challenge? = nil
    static var lastChallenge: NSDate = NSDate()
    static var bar: [Int: Bar?] = [:]
    var daily: Bool
    let goal: Goal
    let total: Int
    var best = 0
    var progress = 0
    var color: UIColor
    
    static func remove() {
        challenge = nil
        Challenge.new()
    }
    
    static func new() {
        if (Grid.level >= 7) {
            if (-lastChallenge.timeIntervalSinceNow >= 60*60*24) {
                Challenge.lastChallenge = NSDate()
                var i = 0
                var g: Goal? = nil
                switch(arc4random_uniform(Int(arc4random_uniform(2)) == 1 ? 5 : 4)) {
                case 0:
                    g = .Tiles(Tile.Color(rawValue: Int(arc4random_uniform(UInt32(Tile.maxColors))))!)
                    i = Tile.rg((180,216))
                case 1:
                    g = .Wildcards
                    i = Tile.rg((36,72))
                case 2:
                    g = .Powerups
                    i = Tile.rg((18,27))
                case 3:
                    g = .Chain
                    i = Tile.rg((16,24))
                case 5:
                    g = .Survive
                    i = Tile.rg((90,150))
                default:
                    return
                }
                challenge = Challenge(goal: g!, total: i, daily: true)
                print("Daily Challenge: \(challenge!.goal.text(challenge!.progress, best: challenge!.best, total: challenge!.total))")
            } else if (challenge == nil) {
                var i = 0
                var g: Goal? = nil
                switch(arc4random_uniform(Grid.active!.mode == .Timed ? 7 : 6)) {
                case 0:
                    g = .Tiles(Tile.Color(rawValue: Int(arc4random_uniform(UInt32(Tile.maxColors))))!)
                    i = Tile.rg((48,72))
                case 1:
                    g = .Wildcards
                    i = Tile.rg((6,12))
                case 2:
                    g = .Powerups
                    i = Tile.rg((3,5))
                case 3:
                    g = .Chain
                    i = Tile.rg((6,12))
                case 4:
                    g = .Swaps
                    i = Tile.rg((18,36))
                case 5:
                    g = .Points
                    i = Tile.rg((1000,4000))
                case 6:
                    g = .Survive
                    i = Tile.rg((60,90))
                default:
                    return
                }
                challenge = Challenge(goal: g!, total: i, daily: false)
                print("Challenge: \(challenge!.goal.text(challenge!.progress, best: challenge!.best, total: challenge!.total))")
            }
        } else if (challenge != nil) {
            lastChallenge = NSDate(timeIntervalSince1970: 0)
            challenge = nil
        }
    }

    static func save() -> String {
        if (challenge != nil) {
            return "\(Int(lastChallenge.timeIntervalSince1970)).\(challenge!.goal.save()).\(challenge!.progress).\(challenge!.best).\(challenge!.total).\(challenge!.daily ? 1 : 0)"
        } else {
            return "\(Int(lastChallenge.timeIntervalSince1970))"
        }
    }
    
    static func load(s: String) {
        if (Grid.level >= 7) {
            let a = s.componentsSeparatedByString(".")
            lastChallenge = NSDate(timeIntervalSince1970: NSTimeInterval(Int(a[0])!))
            if (a.count >= 6) {
                challenge = Challenge(goal: Goal.from(a[1]), total: Int(a[4])!, daily: Int(a[5])! == 1)
                challenge!.progress = Int(a[2])!
                challenge!.best = Int(a[3])!
            }
            new()
        } else {
            lastChallenge = NSDate(timeIntervalSince1970: 0)
        }
        if (challenge != nil) {
            print("\(challenge!.daily ? "Daily Challenge" : "Challenge"): \(challenge!.goal.text(challenge!.progress, best: challenge!.best, total: challenge!.total))")
        }
    }
    
    enum Goal {
        case Tiles(Tile.Color)
        case Wildcards
        case Powerups
        case Chain
        case Swaps
        case Survive
        case Points
        
        static func from(s: String) -> Goal {
            switch (s) {
            case "1":
                return .Wildcards
            case "2":
                return .Powerups
            case "3":
                return .Chain
            case "4":
                return .Swaps
            case "5":
                return .Survive
            case "6":
                return .Points
            default:
                if (s.hasPrefix("0")) {
                    return .Tiles(Tile.Color(rawValue: Int(s.substringFromIndex(s.startIndex.successor()))!)!)
                } else {
                    return .Chain
                }
            }
        }
        
        func save() -> String {
            switch (self) {
            case .Tiles(let c):
                return "0\(c.rawValue)"
            case .Wildcards:
                return "1"
            case .Powerups:
                return "2"
            case .Chain:
                return "3"
            case .Swaps:
                return "4"
            case .Survive:
                return "5"
            case .Points:
                return "6"
            }
        }
        
        func text(progress: Int, best: Int, total: Int) -> String {
            switch (self) {
            case .Tiles(let c):
                return "Destroy \(c)s (\(GameViewController.number(progress))/\(GameViewController.number(total)))"
            case .Wildcards:
                return "Use Wildcards (\(GameViewController.number(progress))/\(GameViewController.number(total)))"
            case .Powerups:
                return "Use Power-Ups (\(GameViewController.number(progress))/\(GameViewController.number(total)))"
            case .Chain:
                return "Chain \(GameViewController.number(total)) Tiles (Best: \(GameViewController.number(best)))"
            case .Swaps:
                return "Swap Tiles (\(GameViewController.number(progress))/\(GameViewController.number(total)))"
            case .Survive:
                return "Survive in Timed (\(GameViewController.number(progress))/\(GameViewController.number(total)))"
            case .Points:
                return "Get Points (\(GameViewController.number(progress))/\(GameViewController.number(total)))"
            }
        }
    }
    
    init(goal: Goal, total: Int, daily: Bool) {
        self.goal = goal
        self.total = total
        self.daily = daily
        if (daily) {
            switch (goal) {
            case .Tiles(let c):
                color = Tile.getColor(c)
            default:
                color = Tile.getColor(.Blue)
            }
        } else {
            color = UIColor.grayColor()
        }
        check()
    }
    
    func complete() {
        if (daily) {
            Tile.cooldown = Tile.rg((-432,-288))
            let increase = Tile.rg((2592,7776))
            print("Daily Challenge Completed: +\(increase) XP")
            Grid.xp += increase
            Grid.points += increase
            
            let notification = UILocalNotification()
            notification.alertBody = "New Daily Challenge Available"
            notification.alertAction = "open"
            notification.fireDate = NSDate(timeInterval: 60*60*24, sinceDate: Challenge.lastChallenge)
            notification.alertTitle = "New Challenge"
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        } else {
            Tile.cooldown = min(Tile.cooldown-72,-18)
            let increase = Tile.rg((864,1728))
            print("Challenge Completed: +\(increase) XP")
            Grid.xp += increase
            Grid.points += increase
        }
        Challenge.remove()
    }
    
    func check() {
        best = max(progress,best)
        if (progress >= total) {
            complete()
        } else {
            if (Grid.active != nil && Challenge.bar[Grid.active!.mode.rawValue] == nil) {
                Challenge.bar[Grid.active!.mode.rawValue] = Bar(current: progress, max: total, color: color, index: -1, text: (daily ? "DAILY: " : "") + goal.text(progress, best: best, total: total), grid: Grid.active)
            } else if (Grid.active != nil) {
                Challenge.bar[Grid.active!.mode.rawValue]!!.updateBar(progress, max: total, color: color, text: (daily ? "DAILY: " : "") + goal.text(progress, best: best, total: total))
            }
        }
    }
    
    func reset() {
        progress = 0
        check()
    }
    
    func swap() {
        switch (goal) {
        case .Swaps:
            progress += 1
            check()
        default:
            return
        }
    }
    
    func chain(length: Int) {
        switch (goal) {
        case .Chain:
            progress = max(length,best)
            check()
        default:
            return
        }
    }
    
    func survive(secs: Int) {
        switch (goal) {
        case .Survive:
            progress += secs
            check()
        default:
            return
        }
    }
    
    func die() {
        switch(goal) {
        case .Tiles(_):
            progress = max(0, progress-96)
        case .Wildcards:
            progress = max(0, progress-18)
        case .Powerups:
            progress = max(0, progress-8)
        case .Swaps:
            progress = max(0, progress-48)
        case .Survive, .Points:
            reset()
        default:
            return
        }
    }
    
    func points(points: Int) {
        switch (goal) {
        case .Points:
            progress = points
            check()
        default:
            return
        }
    }
    
    func clear(color: Tile.Color, type: Tile.SpecialType) {
        switch(goal) {
        case .Tiles(let c):
            if (c == color) {
                progress += 1
            }
        case .Wildcards:
            if (type == .Wildcard) {
                progress += 1
            }
        case .Powerups:
            if (type != .Normal && type != .Wildcard) {
                progress += 1
            }
        default:
            return
        }
    }
}