//
//  RootView.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/20/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import SwiftUI

struct PlaygroundListItemView: View {
    let group: PlaygroundGroup
    var viewModel: ViewModel
    @State private var isExpanded = false


    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(group.scenes) { sceneKind in
                HStack {
                    Text(sceneKind.name)
                        .foregroundColor(viewModel.sceneKind == sceneKind ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .tag(sceneKind)
                .contentShape(.rect)
                .onTapGesture {
                    viewModel.sceneKind = sceneKind
                }
            }
        } label: {
            Text(group.rawValue)
                .font(.headline)
                .foregroundStyle(.secondary)
                .contentShape(.rect)
        }.onAppear {
            isExpanded = group.scenes.contains(viewModel.sceneKind)
        }.onChange(of: viewModel.sceneKind) { (_, newValue) in
            withAnimation {
                isExpanded = group.scenes.contains(newValue)
            }
        }
    }
}

struct RootView: View {
    @State var viewModel = ViewModel()
    @State var isOptionsOpen = false
    @State var isSideBarOPen = false

    init() {
    }

    private var sidebar: some View {
        List {
            ForEach(PlaygroundGroup.allCases) { sceneGroup in
                PlaygroundListItemView(group: sceneGroup, viewModel: viewModel)
            }
        }
        .listStyle(.inset)
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
                viewModel.scene.view
                    .environment(viewModel)
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
            MetalSwiftView()
                .aspectRatio(1.0, contentMode: .fill)
                .environment(viewModel)
                .overlay(alignment: .topTrailing) {
                    options
                }
                .onTapGesture {
                    withAnimation {
                        if self.isOptionsOpen {
                            self.isOptionsOpen = false
                        }
                    }
                }
                .zIndex(0)
        }
    }
}
