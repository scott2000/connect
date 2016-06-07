//
//  PauseViewController.swift
//  Connect
//
//  Created by Scott Taylor on 6/6/16.
//  Copyright © 2016 Scott Taylor. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class PauseViewController: UIViewController {
    @IBOutlet weak var MainLabel: UILabel!
    @IBOutlet weak var SubLabel: UILabel!
    
    @IBAction func dismissAnimated(sender: UIButton) {
        Grid.menuSound?.play()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func main(sender: UIButton) {
        Grid.menuSound?.play()
        MainViewController.mcont?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func prepare() {
        MainLabel.text = Grid.display.main
        SubLabel.text = Grid.display.sub
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
