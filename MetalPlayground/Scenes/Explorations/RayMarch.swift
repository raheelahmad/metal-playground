//
//  RayMarch.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 6/23/23.
//  Copyright © 2023 Raheel Ahmad. All rights reserved.
//

import Foundation
import MetalKit
import SwiftUI

struct RayMarch: Scene {
    var name: String { "Ray Marching" }

    var vertexFuncName: String { "rayMarchingSimpleVertex" }

    var fragmentFuncName: String { "rayMarchingSimpleFragment" }
}