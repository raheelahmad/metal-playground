//
//  ViewModel.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/20/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import SwiftUI
import Combine

final class ViewModel: ObservableObject {
    private var sceneKind: SceneKind {
        didSet {
            updateSceneSelection(kind: sceneKind)
        }
    }

    lazy var sceneSelection: Binding<SceneKind> = .init(
        get: { () -> SceneKind in
            self.sceneKind
        }) { kind in
            self.sceneKind = kind
        }

    private let renderer: Renderer

    @Published var scene: Scene
    @Published var hasConfig: Bool
    private var cancellables: [AnyCancellable] = []

    init(view: MetalView, renderer: Renderer) {
        self.renderer = renderer
        view.delegate = renderer
        let sceneKind = SceneKind.allCases.first!
        self.sceneKind = sceneKind
        self.scene = sceneKind.scene
        self.hasConfig = sceneKind.scene.view != nil
        updateSceneSelection(kind: sceneKind)

    }

    private func updateSceneSelection(kind: SceneKind) {
        scene = kind.scene
        renderer.scene = scene
        self.hasConfig = sceneKind.scene.view != nil
    }
}
