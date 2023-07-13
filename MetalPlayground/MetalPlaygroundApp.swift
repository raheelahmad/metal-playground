//
//  AppDelegate.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 5/11/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import Cocoa
import SwiftUI


@main
struct MetalPlaygroundApp: App {
    private let renderer = Renderer()
    var body: some Scene {
        WindowGroup {
            RootView(renderer: renderer)
                .frame(minWidth: 420)
        }
    }
}
