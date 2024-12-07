//
//  ViewModel.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/20/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import SwiftUI
import Combine

@Observable
final class ViewModel {
    var sceneKind: SceneKind = .simonDevFractAndFriends {
        didSet {
            updateSceneSelection(kind: sceneKind)
        }
    }

    let renderer: Renderer

    var scene: Playground {
        sceneKind.scene
    }
    var hasConfig: Bool {
        sceneKind.scene.view != nil
    }
    @ObservationIgnored
    private var cancellables: [AnyCancellable] = []
    private var view: MetalView?

    init() {
        self.renderer = Renderer()
    }

    func update(view: MetalView) {

        view.delegate = renderer
        view.renderer = renderer
        renderer.setup(view)

        self.view = view
        view.delegate = renderer

        updateSceneSelection(kind: sceneKind)
    }


    private func updateSceneSelection(kind: SceneKind) {
        renderer.scene = scene
        view?.enableSetNeedsDisplay = !scene.isPaused
        view?.isPaused = scene.isPaused
    }
}
