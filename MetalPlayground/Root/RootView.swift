//
//  RootView.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/20/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: ViewModel
    @State var isOptionsOpen = false

    let metalView: MetalSwiftView

    var body: some View {
        ZStack(alignment: .topTrailing) {
            metalView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    withAnimation {
                        if self.isOptionsOpen {
                            self.isOptionsOpen = false
                        }
                    }
            }.zIndex(0)
            if !isOptionsOpen {
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
            }
            else {
                VStack(spacing: 28) {
                    Picker(
                        selection: viewModel.sceneSelection,
                        label: Text("Scenes").font(.callout)
                    ) {
                        ForEach(SceneKind.allCases) {
                            Text("\($0.name)").tag($0)
                        }
                    }
                    Divider()
                    if viewModel.hasConfig {
                        ConfigView()
                            .environmentObject(viewModel)
                    }
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
    }
}
