//
//  DifficultyViewController.swift
//  Connect
//
//  Created by Scott Taylor on 6/6/16.
//  Copyright © 2016 Scott Taylor. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class DifficultyViewController: UIViewController {
    
    @IBOutlet weak var HardButton: Button!
    
    @IBOutlet weak var HighScoreLabel: UILabel!
    @IBOutlet weak var LongestChainLabel: UILabel!
    
    @IBOutlet weak var ModeLabel: UILabel!
    
    @IBAction func DifficultyPress(sender: Button) {
        Grid.menuSound?.play()
        Grid.active!.diff = Grid.Difficulty(rawValue: -(sender.tag+1))!
        print("Difficulty: \(Grid.active!.diff)")
    }
    
    @IBAction func dismiss(sender: UIButton) {
        Grid.menuSound?.play()
        dismissViewControllerAnimated(false, completion: nil)
    }
    func prepare() {
        HighScoreLabel?.text = "High Score: \(MainViewController.number(Grid.active!.record!.points))"
        LongestChainLabel?.text = "Longest Chain: \(MainViewController.number(Grid.active!.record!.chain))"
        if (Grid.diffs < 2) {
            HardButton.backgroundColor = UIColor.lightGrayColor()
            HardButton.enabled = false
        } else {
            HardButton.backgroundColor = Tile.getColor(.Blue)
            HardButton.enabled = true
        }
        ModeLabel.text = MainViewController.mode
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