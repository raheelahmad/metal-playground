//
//  MetalSwiftUIView.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/22/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import SwiftUI

struct MetalSwiftView: NSViewRepresentable {
    @Environment(ViewModel.self) var viewModel

    init() {
    }

    func makeNSView(context: Context) -> MetalView {
        MetalView()
    }

    func makeCoordinator() -> ViewModel {
        viewModel
    }

    func updateNSView(_ nsView: MetalView, context: Context) {
        nsView.delegate = context.coordinator.renderer
        nsView.renderer = context.coordinator.renderer
        context.coordinator.update(view: nsView)
    }
}
