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
    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 420)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
