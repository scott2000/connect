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
    
    @IBOutlet weak var MainLabel: UILabel!
    @IBOutlet weak var SubLabel: UILabel!
    
    @IBOutlet weak var TimedLabel: UILabel!
    @IBOutlet weak var StandardLabel: UILabel!
    @IBOutlet weak var MovesLabel: UILabel!
    
    @IBOutlet weak var HardButton: Button!
    
    @IBOutlet weak var ChallengeView: SKView!
    
    @IBOutlet weak var PointsLabel: UILabel!
    @IBOutlet weak var CoinsLabel: UILabel!
    
    @IBOutlet weak var ModeLabel: UILabel!
    
    @IBAction func dismissAnimated(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func dismiss(sender: UIButton) {
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func main(sender: UIButton) {
        GameViewController.mcont?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func PauseGame(sender: UIButton) {
        Grid.active?.pause()
    }
    
    @IBAction func ModePress(sender: Button) {
        let mode = Grid.Mode(rawValue: sender.tag) ?? .Standard
        Grid.setMode(mode)
        GameViewController.mode = String(mode)
        print("Mode: \(GameViewController.mode)")
    }
    
    @IBAction func DifficultyPress(sender: Button) {
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Grid.create(CGSize(width: 1024, height: 768))
        let g = Grid.active
        if (title == "Game" && g != nil && GameViewController.scene != g) {
            GameViewController.cont = self
            GameViewController.scene = g
            
            if (!g!.running) {
                g!.restore()
            }
            
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
        } else if (ChallengeView != nil || challengeBar == nil || (Challenge.challenge == nil && challengeBar != nil)) {
            GameViewController.scene = SKScene(size: CGSize(width: 296, height: 64))
            GameViewController.scene!.backgroundColor = UIColor.whiteColor()
            if (Challenge.challenge != nil) {
                challengeBar = Bar(current: Challenge.challenge!.progress, max: Challenge.challenge!.total, position: CGPoint(x: 1, y: 24), width: 294, color: Challenge.challenge!.color, fontSize: 16, text: (Challenge.challenge!.daily ? "DAILY: " : "") + Challenge.challenge!.goal.text(Challenge.challenge!.progress, best: Challenge.challenge!.best, total: Challenge.challenge!.total))
            } else {
                challengeBar = nil
            }
            ChallengeView?.presentScene(GameViewController.scene)
        } else if (ChallengeView != nil) {
            challengeBar!.updateBar(Challenge.challenge!.progress, max: Challenge.challenge!.total, color: Challenge.challenge!.color, text: (Challenge.challenge!.daily ? "DAILY: " : "") + Challenge.challenge!.goal.text(Challenge.challenge!.progress, best: Challenge.challenge!.best, total: Challenge.challenge!.total))
        }
        if (Grid.modes < 3 && MovesButton != nil) {
            MovesButton.backgroundColor = UIColor.lightGrayColor()
            MovesButton.enabled = false
            MovesLabel.text = "Locked"
        } else if (MovesButton != nil) {
            MovesButton.backgroundColor = Tile.getColor(.Blue)
            MovesButton.enabled = true
            MovesLabel.text = "Moves"
        }
        if (Grid.modes < 2 && TimedButton != nil) {
            TimedButton.backgroundColor = UIColor.lightGrayColor()
            TimedButton.enabled = false
            TimedLabel.text = "Locked"
        } else if (TimedButton != nil) {
            TimedButton.backgroundColor = Tile.getColor(.Blue)
            TimedButton.enabled = true
            TimedLabel.text = "Timed"
        }
        MainLabel?.text = Grid.display.main
        SubLabel?.text = Grid.display.sub
        if (StandardButton != nil) {
            GameViewController.mcont = self
            if (Grid.level >= 21) {
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
        }
        if (Grid.diffs < 2 && HardButton != nil) {
            HardButton.backgroundColor = UIColor.lightGrayColor()
            HardButton.enabled = false
        } else if (HardButton != nil) {
            HardButton.backgroundColor = Tile.getColor(.Blue)
            HardButton.enabled = true
        }
        if (CoinsLabel != nil) {
            if (Grid.level <= 0) {
                CoinsLabel.text = "Tutorial \(Grid.level+3)"
            } else if (Grid.level >= 21) {
                CoinsLabel.text = "Max Level"
            } else {
                CoinsLabel.text = "Level \(Grid.level)"
            }
        }
        if (PointsLabel != nil) {
            PointsLabel.text = "\(GameViewController.number(Grid.points)) Points"
        }
        if (ModeLabel != nil) {
            ModeLabel.text = GameViewController.mode
        }
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
