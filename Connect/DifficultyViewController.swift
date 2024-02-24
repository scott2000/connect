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
    
    @IBAction func DifficultyPress(_ sender: Button) {
        Grid.menuSound?.play()
        Grid.active!.diff = Grid.Difficulty(rawValue: -(sender.tag+1))!
        print("Difficulty: \(Grid.active!.diff)")
    }
    
    @IBAction func dismiss(_ sender: UIButton) {
        Grid.menuSound?.play()
        dismiss(animated: false, completion: nil)
    }
    func prepare() {
        HighScoreLabel?.text = "High Score: \(MainViewController.number(n: Grid.active!.record!.points))"
        LongestChainLabel?.text = "Longest Chain: \(MainViewController.number(n: Grid.active!.record!.chain))"
        if (Grid.diffs < 2) {
            HardButton.backgroundColor = UIColor.lightGray
            HardButton.isEnabled = false
        } else {
            HardButton.backgroundColor = Tile.getColor(.Blue)
            HardButton.isEnabled = true
        }
        ModeLabel.text = MainViewController.mode
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
