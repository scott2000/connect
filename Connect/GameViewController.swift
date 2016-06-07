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
    @IBAction func PauseGame(sender: UIButton) {
        Grid.menuSound?.play()
        Grid.active?.pause()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        let g = Grid.active!
        if (g.running) {
            g.pause()
        }
    }
    
    func prepare() {
        let g = Grid.active
        if (!g!.running) {
            g!.restore()
        }
        if (g != nil && (MainViewController.scene != g || MainViewController.cont != self)) {
            MainViewController.cont = self
            MainViewController.scene = g
            
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
