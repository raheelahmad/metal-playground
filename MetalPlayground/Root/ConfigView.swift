//
//  ConfigView.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/22/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import SwiftUI

struct ConfigView: NSViewRepresentable {
    @EnvironmentObject var viewModel: ViewModel

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.subviews.forEach { $0.removeFromSuperview() }
        if let view = viewModel.scene.view {
            nsView.addSubview(view)
            nsView.translatesAutoresizingMaskIntoConstraints = false
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: nsView.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: nsView.trailingAnchor),
                view.topAnchor.constraint(equalTo: nsView.topAnchor),
                view.bottomAnchor.constraint(equalTo: nsView.bottomAnchor),
            ])
        }
    }
}

