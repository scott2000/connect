//
//  MainViewController.swift
//  Connect
//
//  Created by Scott Taylor on 6/6/16.
//  Copyright © 2016 Scott Taylor. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class MainViewController: UIViewController {
    static var scene: SKScene?
    static var mcont: UIViewController?
    static var cont: UIViewController?
    static var mode: String = "Standard"
    
    var challengeBar: Bar?
    
    @IBOutlet weak var TimedButton: Button!
    @IBOutlet weak var StandardButton: Button!
    @IBOutlet weak var MovesButton: Button!
    
    @IBOutlet weak var ResetButton: Button!
    
    @IBOutlet weak var TimedLabel: UILabel!
    @IBOutlet weak var StandardLabel: UILabel!
    @IBOutlet weak var MovesLabel: UILabel!
    
    @IBOutlet weak var ChallengeView: SKView!
    
    @IBOutlet weak var PointsLabel: UILabel!
    @IBOutlet weak var CoinsLabel: UILabel!
    
    @IBAction func ResetGame(_ sender: Button) {
        let alert = UIAlertController(title: "Reset", message: "Are you sure you want to erase all progress? This cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Erase", style: .destructive, handler: { (action) -> Void in
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
            UIApplication.shared.cancelAllLocalNotifications()
            for n in Grid.grids.keys {
                let g = Grid.grids[n]
                Grid.active = g
                g?.saveAll(grid: false)
            }
            Grid.active = nil
            Grid.grids = [:]
            self.prepare()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func ModePress(_ sender: Button) {
        Grid.menuSound?.play()
        let mode = Grid.Mode(rawValue: sender.tag) ?? .Standard
        Grid.setMode(mode: mode)
        if (mode == .Standard && Grid.level < 1) {
            MainViewController.mode = "Tutorial"
        } else {
            MainViewController.mode = "\(mode)"
        }
        print("Mode: \(MainViewController.mode)")
    }
    
    static func number(n: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: n)) ?? "0"
    }
    
    func prepare() {
        Grid.create(size: CGSize(width: 1024, height: 768))
        let blue = Tile.getColor(.Blue)
        let gray = UIColor.lightGray
        MainViewController.mcont = self
        if (Grid.modes < 3) {
            MovesButton.backgroundColor = gray
            MovesButton.isEnabled = false
            MovesLabel.text = "Locked"
        } else {
            MovesButton.backgroundColor = blue
            MovesButton.isEnabled = true
            MovesLabel.text = "Moves"
        }
        if (Grid.modes < 2) {
            TimedButton.backgroundColor = gray
            TimedButton.isEnabled = false
            TimedLabel.text = "Locked"
        } else {
            TimedButton.backgroundColor = blue
            TimedButton.isEnabled = true
            TimedLabel.text = "Timed"
        }
        if (Grid.level >= Grid.maxLevel) {
            StandardButton.setImage(UIImage(named: "Endless"), for: .normal)
            StandardLabel.text = "Endless"
        } else {
            StandardButton.setImage(UIImage(named: "Play"), for: .normal)
            if (Grid.level <= 0) {
                StandardLabel.text = "Tutorial"
            } else {
                StandardLabel.text = "Standard"
            }
            
        }
        if (Grid.level < Grid.maxLevel) {
            ResetButton.isHidden = true
        } else {
            ResetButton.isHidden = false
        }
        if (Grid.level <= 0) {
            CoinsLabel.isHidden = false
            CoinsLabel.text = "Tutorial \(Grid.level+3)"
        } else if (Grid.level >= Grid.maxLevel) {
            CoinsLabel.isHidden = true
        } else {
            CoinsLabel.isHidden = false
            CoinsLabel.text = "Level \(Grid.level)"
        }
        PointsLabel.text = "\(MainViewController.number(n: Grid.points)) \(Grid.points >= 10_000_000 ? "XP" : "Points")"
        Challenge.new()
        let scha = Challenge.challenge == nil || (!Challenge.challenge!.daily && Grid.level < Grid.maxLevel)
        if (challengeBar == nil) {
            MainViewController.scene = SKScene(size: CGSize(width: 296, height: 64))
            MainViewController.scene!.backgroundColor = UIColor.white
            if (scha && Grid.level > 0) {
                challengeBar = Bar(current: Grid.xp, max: Grid.maxXP(), position: CGPoint(x: 1, y: 24), width: 294, color: Tile.getColor(.Green), fontSize: 16, text: "\(Grid.xp)/\(Grid.maxXP()) XP")
            } else if (Challenge.challenge != nil && Grid.level > 0) {
                challengeBar = Bar(current: Challenge.challenge!.progress, max: Challenge.challenge!.total, position: CGPoint(x: 1, y: 24), width: 294, color: Challenge.challenge!.color, fontSize: 16, text: (Challenge.challenge!.daily ? "DAILY: " : "") + Challenge.challenge!.goal.text(progress: Challenge.challenge!.progress, best: Challenge.challenge!.best, total: Challenge.challenge!.total))
            } else {
                challengeBar = nil
            }
            ChallengeView?.presentScene(MainViewController.scene)
        } else if (Grid.level > 0) {
            if (scha) {
                challengeBar!.updateBar(current: Grid.xp, max: Grid.maxXP(), color: Tile.getColor(.Green), text: "\(Grid.xp)/\(Grid.maxXP()) XP", before: true)
            } else {
                challengeBar!.updateBar(current: Challenge.challenge!.progress, max: Challenge.challenge!.total, color: Challenge.challenge!.color, text: (Challenge.challenge!.daily ? "DAILY: " : "") + Challenge.challenge!.goal.text(progress: Challenge.challenge!.progress, best: Challenge.challenge!.best, total: Challenge.challenge!.total), before: true)
            }
        } else {
            challengeBar = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepare()
    }
    
    override var shouldAutorotate: Bool {
        get { false }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get { .portrait }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden: Bool {
        get { true }
    }
}
