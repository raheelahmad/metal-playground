//
//  AppDelegate.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 5/11/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private let renderer = Renderer()
    private let metalView = MetalView()
    var window: NSWindow!
    var viewModel: ViewModel!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        viewModel = ViewModel(view: metalView, renderer: renderer)

        metalView.renderer = renderer

        let contentView = RootView(
            viewModel: viewModel,
            metalView: MetalSwiftView(metalView: metalView)
        )

        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
//        window.aspectRatio = NSSize(width: 1, height: 1)
        window.center()
        window.setFrameAutosaveName("Root Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

