//
//  RootView.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/20/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import SwiftUI

struct RootView: View {
    @StateObject var viewModel: ViewModel
    @State var isOptionsOpen = false

    let metalView: MetalSwiftView

    init(renderer: Renderer) {
        let hostedView = MetalView()
        hostedView.delegate = renderer
        hostedView.renderer = renderer
        renderer.setup(hostedView)
        _viewModel = .init(wrappedValue: ViewModel(view: hostedView, renderer: renderer))
        metalView = MetalSwiftView(metalView: hostedView)
    }

    private var sidebar: some View {
        List {
            ForEach(PlaygroundGroup.allCases) { sceneGroup in
                DisclosureGroup {
                    ForEach(sceneGroup.scenes) { sceneKind in
                        HStack {
                            Text(sceneKind.name)
                                .tag(sceneKind)
                                .foregroundColor(viewModel.sceneKind == sceneKind ? .primary : .secondary)
                                .bold(viewModel.sceneKind == sceneKind)
                        }
                        .onTapGesture {
                            viewModel.sceneKind = sceneKind
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } label: {
                    Text(sceneGroup.rawValue)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180)
    }

    @ViewBuilder
    private var options: some View {
        if !viewModel.hasConfig {
            EmptyView()
        } else if !isOptionsOpen {
            Text("Options")
                .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(14)
                .padding()
                .onTapGesture {
                    withAnimation {
                        self.isOptionsOpen.toggle()
                    }
                }.zIndex(1)
        } else {
            VStack(spacing: 28) {
                ConfigView()
                    .environmentObject(viewModel)
            }
            .frame(maxWidth: 210)
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .padding()
            .transition(.move(edge: .trailing))
            .zIndex(2)
            .opacity(0.96)
        }
    }

    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            ZStack(alignment: .topTrailing) {
                metalView
                    .onTapGesture {
                        withAnimation {
                            if self.isOptionsOpen {
                                self.isOptionsOpen = false
                            }
                        }
                    }
                    .zIndex(0)

                options
            }
        }
    }
}
