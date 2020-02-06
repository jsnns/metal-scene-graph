//
//  GameViewController.swift
//  MeatlDeep
//
//  Created by Jacob Sansbury on 1/31/20.
//  Copyright © 2020 Jacob Sansbury. All rights reserved.
//

import Cocoa
import MetalKit

// Our macOS specific view controller
class GameViewController: NSViewController {
    
    var mtkView: MTKView!
    var render: Render!

    override func viewDidLoad() {
        super.viewDidLoad()

        mtkView = MTKView()
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mtkView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[mtkView]|", options: [], metrics: nil, views: ["mtkView" : mtkView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[mtkView]|", options: [], metrics: nil, views: ["mtkView" : mtkView]))
        
        
        let device = MTLCreateSystemDefaultDevice()!
        mtkView.device = device
        mtkView.colorPixelFormat = .bgra8Unorm
        
        render = Render(view: mtkView, device: device)
        mtkView.delegate = render
    }
}
