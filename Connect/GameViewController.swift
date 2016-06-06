//
//  GameViewController.swift
//  Connect
//
//  Created by Scott Taylor on 5/15/16.
//  Copyright (c) 2016 Scott Taylor. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    static var scene: SKScene?
    static var mcont: UIViewController?
    static var cont: UIViewController?
    static var mode = "Standard"
    
    var challengeBar: Bar?
    
    @IBOutlet weak var TimedButton: Button!
    @IBOutlet weak var StandardButton: Button!
    @IBOutlet weak var MovesButton: Button!
    
    @IBOutlet weak var ResetButton: Button!
    
    @IBOutlet weak var MainLabel: UILabel!
    @IBOutlet weak var SubLabel: UILabel!
    
    @IBOutlet weak var TimedLabel: UILabel!
    @IBOutlet weak var StandardLabel: UILabel!
    @IBOutlet weak var MovesLabel: UILabel!
    
    @IBOutlet weak var HardButton: Button!
    
    @IBOutlet weak var HighScoreLabel: UILabel!
    @IBOutlet weak var LongestChainLabel: UILabel!
    
    @IBOutlet weak var ChallengeView: SKView!
    
    @IBOutlet weak var PointsLabel: UILabel!
    @IBOutlet weak var CoinsLabel: UILabel!
    
    @IBOutlet weak var ModeLabel: UILabel!
    
    @IBAction func dismissAnimated(sender: UIButton) {
        Grid.menuSound?.play()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func dismiss(sender: UIButton) {
        Grid.menuSound?.play()
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func main(sender: UIButton) {
        Grid.menuSound?.play()
        GameViewController.mcont?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func ResetGame(sender: Button) {
        let alert = UIAlertController(title: "Reset", message: "Are you sure you want to erase all progress? This cannot be undone.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Erase", style: .Destructive, handler: { (action) -> Void in
            Grid.level = -2
            Grid.xp = 0
            Grid.modes = 1
            Grid.diffs = 1
            Grid.lc = true
            Grid.newPowerup = false
            Tile.resize(3, 1)
            Tile.powerupsUnlocked = []
            Challenge.challenge = nil
            Challenge.bar = [:]
            for n in Grid.grids.keys {
                let g = Grid.grids[n]
                Grid.active = g
                g?.saveAll(false)
            }
            Grid.active = nil
            Grid.grids = [:]
            self.prepare()
        }))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func PauseGame(sender: UIButton) {
        Grid.menuSound?.play()
        Grid.active?.pause()
    }
    
    @IBAction func ModePress(sender: Button) {
        Grid.menuSound?.play()
        let mode = Grid.Mode(rawValue: sender.tag) ?? .Standard
        Grid.setMode(mode)
        if (mode == .Standard && Grid.level < 1) {
            GameViewController.mode = "Tutorial"
        } else {
            GameViewController.mode = String(mode)
        }
        print("Mode: \(GameViewController.mode)")
    }
    
    @IBAction func DifficultyPress(sender: Button) {
        Grid.menuSound?.play()
        Grid.active!.diff = Grid.Difficulty(rawValue: -(sender.tag+1))!
        print("Difficulty: \(Grid.active!.diff)")
    }
    
    static func number(n: Int) -> String {
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = .DecimalStyle
        return numberFormatter.stringFromNumber(n) ?? "0"
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if (title == "Game") {
            let g = Grid.active!
            if (g.running) {
                g.pause()
            }
        }
    }
    
    func prepare() {
        Grid.create(CGSize(width: 1024, height: 768))
        let g = Grid.active
        let blue = Tile.getColor(.Blue)
        let gray = UIColor.lightGrayColor()
        switch (title!) {
        case "Main":
            GameViewController.mcont = self
            if (Grid.modes < 3) {
                MovesButton.backgroundColor = gray
                MovesButton.enabled = false
                MovesLabel.text = "Locked"
            } else {
                MovesButton.backgroundColor = blue
                MovesButton.enabled = true
                MovesLabel.text = "Moves"
            }
            if (Grid.modes < 2) {
                TimedButton.backgroundColor = gray
                TimedButton.enabled = false
                TimedLabel.text = "Locked"
            } else {
                TimedButton.backgroundColor = blue
                TimedButton.enabled = true
                TimedLabel.text = "Timed"
            }
            if (Grid.level >= Grid.maxLevel) {
                StandardButton.setImage(UIImage(named: "Endless"), forState: .Normal)
                StandardLabel.text = "Endless"
            } else {
                StandardButton.setImage(UIImage(named: "Play"), forState: .Normal)
                if (Grid.level <= 0) {
                    StandardLabel.text = "Tutorial"
                } else {
                    StandardLabel.text = "Standard"
                }
                
            }
            if (Grid.level < Grid.maxLevel) {
                ResetButton.hidden = true
            } else {
                ResetButton.hidden = false
            }
            if (Grid.level <= 0) {
                CoinsLabel.hidden = false
                CoinsLabel.text = "Tutorial \(Grid.level+3)"
            } else if (Grid.level >= Grid.maxLevel) {
                CoinsLabel.hidden = true
            } else {
                CoinsLabel.hidden = false
                CoinsLabel.text = "Level \(Grid.level)"
            }
            PointsLabel.text = "\(GameViewController.number(Grid.points)) \(Grid.points >= 10_000_000 ? "XP" : "Points")"
            if (challengeBar == nil || (Challenge.challenge == nil && challengeBar != nil)) {
                GameViewController.scene = SKScene(size: CGSize(width: 296, height: 64))
                GameViewController.scene!.backgroundColor = UIColor.whiteColor()
                if (Challenge.challenge != nil) {
                    challengeBar = Bar(current: Challenge.challenge!.progress, max: Challenge.challenge!.total, position: CGPoint(x: 1, y: 24), width: 294, color: Challenge.challenge!.color, fontSize: 16, text: (Challenge.challenge!.daily ? "DAILY: " : "") + Challenge.challenge!.goal.text(Challenge.challenge!.progress, best: Challenge.challenge!.best, total: Challenge.challenge!.total))
                } else if (Grid.level > 0) {
                    challengeBar = Bar(current: Grid.xp, max: Grid.maxXP(), position: CGPoint(x: 1, y: 24), width: 294, color: Tile.getColor(.Green), fontSize: 16, text: "\(Grid.xp)/\(Grid.maxXP()) XP")
                } else {
                    challengeBar = nil
                }
                ChallengeView?.presentScene(GameViewController.scene)
            } else {
                challengeBar!.updateBar(Challenge.challenge!.progress, max: Challenge.challenge!.total, color: Challenge.challenge!.color, text: (Challenge.challenge!.daily ? "DAILY: " : "") + Challenge.challenge!.goal.text(Challenge.challenge!.progress, best: Challenge.challenge!.best, total: Challenge.challenge!.total))
            }
        case "Difficulty":
            HighScoreLabel?.text = "High Score: \(GameViewController.number(Grid.active!.record!.points))"
            LongestChainLabel?.text = "Longest Chain: \(GameViewController.number(Grid.active!.record!.chain))"
            if (Grid.diffs < 2) {
                HardButton.backgroundColor = UIColor.lightGrayColor()
                HardButton.enabled = false
            } else {
                HardButton.backgroundColor = Tile.getColor(.Blue)
                HardButton.enabled = true
            }
            ModeLabel.text = GameViewController.mode
        case "Pause":
            MainLabel.text = Grid.display.main
            SubLabel.text = Grid.display.sub
        default:
            if (!g!.running) {
                g!.restore()
            }
            if (g != nil && GameViewController.scene != g) {
                GameViewController.cont = self
                GameViewController.scene = g
                
                let skView = self.view as! SKView
                
                // Configure the view.
                skView.showsFPS = false
                skView.showsNodeCount = false
                skView.showsDrawCount = false
                
                /* Sprite Kit applies additional optimizations to improve rendering performance */
                skView.ignoresSiblingOrder = true
                
                /* Set the scale mode to scale to fit the window */
                Grid.active!.scaleMode = .AspectFill
                
                skView.presentScene(Grid.active!)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        prepare()
    }

    override func shouldAutorotate() -> Bool {
        return false
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .Portrait
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
