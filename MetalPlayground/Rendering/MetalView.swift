//
//  MetalView.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 7/6/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import MetalKit

final class MetalView: MTKView {
    var renderer: Renderer?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
    }

    override func mouseMoved(with event: NSEvent) {
        let x = Float(event.locationInWindow.x)
        let y = Float(event.locationInWindow.y)
        renderer?.mouseLocation = .init(x,y)
    }

    override func updateTrackingAreas() {
        let area = NSTrackingArea(rect: self.bounds,
                                  options: [NSTrackingArea.Options.activeAlways,
                                            NSTrackingArea.Options.mouseMoved,
                                            NSTrackingArea.Options.enabledDuringMouseDrag],
                                  owner: self,
                                  userInfo: nil)
        self.addTrackingArea(area)
    }
}
