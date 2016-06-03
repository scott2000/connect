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
    static var cont: UIViewController?
    static var mode = "Standard"
    
    var challengeBar: Bar?
    
    @IBOutlet weak var TimedButton: Button!
    @IBOutlet weak var StandardButton: Button!
    @IBOutlet weak var MovesButton: Button!
    
    @IBOutlet weak var ChallengeView: SKView!
    
    @IBOutlet weak var PointsLabel: UILabel!
    @IBOutlet weak var CoinsLabel: UILabel!
    
    @IBOutlet weak var ModeLabel: UILabel!
    
    @IBAction func ModePress(sender: Button) {
        switch (sender.tag) {
        case 0:
            GameViewController.mode = "Timed"
        case 2:
            GameViewController.mode = "Moves"
        default:
            GameViewController.mode = "Standard"
        }
        Tile.grid!.mode = sender.tag
        print("Mode: \(sender.tag)")
    }
    
    @IBAction func DifficultyPress(sender: Button) {
        Tile.grid!.diff = -(sender.tag+1)
        print("Difficulty: \(-(sender.tag+1))")
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        print("DISAPPEAR")
        if (title == "Game") {
            let skView = self.view as! SKView
            skView.presentScene(nil)
            let g = Tile.scene as! Grid
            if (g.running) {
                g.pause()
            }
        } else if (title == "Main") {
            GameViewController.scene?.removeAllChildren()
            GameViewController.scene = nil
            ChallengeView!.presentScene(nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("LOAD")
        if (Tile.scene == nil) {
            print("NEWGRID")
            Tile.scene = Grid(size: CGSize(width: 1024, height: 768))
        }
        let g = Tile.scene as! Grid
        if (title == "Game") {
            GameViewController.cont = self
            GameViewController.scene = g
            
            if (!g.running) {
                g.restore()
            }
            
            let skView = self.view as! SKView
            
            // Configure the view.
            skView.showsFPS = false
            skView.showsNodeCount = false
            skView.showsDrawCount = false
    
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
    
            /* Set the scale mode to scale to fit the window */
            Tile.scene!.scaleMode = .AspectFill
            
            skView.presentScene(Tile.scene!)
        } else if (ChallengeView != nil && Challenge.challenge != nil) {
            GameViewController.scene = SKScene(size: CGSize(width: 296, height: 64))
            GameViewController.scene!.backgroundColor = UIColor.whiteColor()
            challengeBar = Bar(current: Challenge.challenge!.progress, max: Challenge.challenge!.total, position: CGPoint(x: 1, y: 24), width: 294, color: Challenge.challenge!.color, fontSize: 16, text: (Challenge.challenge!.daily ? "DAILY: " : "") + Challenge.challenge!.goal.text(Challenge.challenge!.progress, best: Challenge.challenge!.best, total: Challenge.challenge!.total))
            ChallengeView.presentScene(GameViewController.scene!)
        }
        if (g.modes.count < 3 && MovesButton != nil) {
            MovesButton.enabled = false
        }
        if (g.modes.count < 2 && TimedButton != nil) {
            TimedButton.enabled = false
        }
        if (CoinsLabel != nil) {
            CoinsLabel.text = "Level: \(g.level)"
        }
        if (PointsLabel != nil) {
            PointsLabel.text = "XP: \(g.points)"
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
        print("MEMWARNING")
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
