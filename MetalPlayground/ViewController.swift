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
    @IBOutlet weak var sceneUniformsChoiceContainerView: NSView!

    let scenes: [Scene] = allScenes.map { $0.init() }

    override func viewDidLoad() {
        super.viewDidLoad()

        scenesChoiceControl.removeAllItems()
        scenesChoiceControl.addItems(withTitles: scenes.map { $0.name })
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

        DispatchQueue.main.async {
            self.updateWithScene(self.scenes.first!)
        }
    }

    @objc
    func selectScene(button: NSPopUpButton) {
        guard
            let title = button.selectedItem?.title,
            let scene = scenes.first(where: { $0.name == title })
        else { return }
        updateWithScene(scene)
    }

    private func updateWithScene(_ scene: Scene) {
        metalView.renderer.scene = scene

        sceneUniformsChoiceContainerView.subviews.forEach { $0.removeFromSuperview() }

        if let uniformsView = scene.view  {
            uniformsView.translatesAutoresizingMaskIntoConstraints = false
            sceneUniformsChoiceContainerView.addSubview(uniformsView)
            NSLayoutConstraint.activate([
                uniformsView.leadingAnchor.constraint(equalTo: sceneUniformsChoiceContainerView.leadingAnchor),
                uniformsView.topAnchor.constraint(equalTo: sceneUniformsChoiceContainerView.topAnchor),
                uniformsView.bottomAnchor.constraint(equalTo: sceneUniformsChoiceContainerView.bottomAnchor),
            ]
            )
        }
    }
}
