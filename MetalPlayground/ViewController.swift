//
//  ViewController.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 5/11/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {
    let metalView = MetalView()
    @IBOutlet weak var metalContainerView: NSView!
    @IBOutlet weak var scenesChoiceControl: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        scenesChoiceControl.removeAllItems()
        scenesChoiceControl.addItems(withTitles: Scene.allCases.map { $0.rawValue })
        scenesChoiceControl.target = self
        scenesChoiceControl.action = #selector(selectScene(button:))

        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalContainerView.addSubview(metalView)
        NSLayoutConstraint.activate([
            metalView.leadingAnchor.constraint(equalTo: metalContainerView.leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: metalContainerView.trailingAnchor),
            metalView.topAnchor.constraint(equalTo: metalContainerView.topAnchor),
            metalView.bottomAnchor.constraint(equalTo: metalContainerView.bottomAnchor),
            ]
        )
    }

    @objc
    func selectScene(button: NSPopUpButton) {
        guard
            let title = button.selectedItem?.title,
            let scene = Scene(rawValue: title)
            else { return }
        metalView.renderer.scene = scene
    }
}
