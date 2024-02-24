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
    @IBAction func PauseGame(_ sender: UIButton) {
        Grid.menuSound?.play()
        Grid.active?.pause()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
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
            Grid.active!.scaleMode = .aspectFill
            
            skView.presentScene(Grid.active!)
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
