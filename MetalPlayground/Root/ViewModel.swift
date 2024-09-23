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
    var sceneKind: SceneKind {
        didSet {
            updateSceneSelection(kind: sceneKind)
        }
    }

    private let renderer: Renderer

    var scene: Playground
    var hasConfig: Bool
    @ObservationIgnored
    private var cancellables: [AnyCancellable] = []
    private let view: MetalView

    init(view: MetalView, renderer: Renderer) {
        self.renderer = renderer
        self.view = view
        view.delegate = renderer
        let sceneKind = SceneKind.raymarchingFromScratch
        self.sceneKind = sceneKind
        self.scene = sceneKind.scene
        self.hasConfig = sceneKind.scene.view != nil

        updateSceneSelection(kind: sceneKind)
    }

    private func updateSceneSelection(kind: SceneKind) {
        scene = kind.scene
        renderer.scene = scene
        self.hasConfig = sceneKind.scene.view != nil

        view.enableSetNeedsDisplay = !scene.isPaused
        view.isPaused = scene.isPaused
    }
}
