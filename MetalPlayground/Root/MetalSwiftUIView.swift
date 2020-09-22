//
//  MetalSwiftUIView.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/22/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import SwiftUI

final class MetalSwiftView: NSViewRepresentable {
    let metalView: MetalView

    init(metalView: MetalView) {
        self.metalView = metalView
    }

    func makeNSView(context: Context) -> MetalView {
        metalView
    }

    func updateNSView(_ nsView: MetalView, context: Context) { }
}
