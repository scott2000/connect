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
    
    @IBAction func dismissAnimated(_ sender: UIButton) {
        Grid.menuSound?.play()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func main(_ sender: UIButton) {
        Grid.menuSound?.play()
        MainViewController.mcont?.dismiss(animated: true, completion: nil)
    }
    
    func prepare() {
        MainLabel.text = Grid.display.main
        SubLabel.text = Grid.display.sub
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
