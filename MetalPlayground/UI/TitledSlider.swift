//
//  TitledSlider.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 9/20/20.
//  Copyright © 2020 Raheel Ahmad. All rights reserved.
//

import SwiftUI

public struct TitledSlider: View {
    let title: String
    var value: Binding<Float>
    let slider: AnyView
    let reset: (() -> ())

    static let nf: NumberFormatter = {
        let f = NumberFormatter()
        f.maximumFractionDigits = 1
        return f
    }()

    static func boundLabel(value: Float) -> some View {
        Text(nf.string(from: NSNumber(floatLiteral: Double(value)))!)
            .font(.caption).foregroundColor(.secondary)
    }

    static func valueLabel(value: Float) -> some View {
        Text(nf.string(from: NSNumber(floatLiteral: Double(value)))!)
            .bold()
    }

    init(title: String, value: Binding<Float>, in bounds: ClosedRange<Float>, step: Float? = nil, reset: @escaping (() -> ())) {
        if let step = step {
            self.slider = AnyView(
                Slider(
                    value: value,
                    in: bounds,
                    step: step,
                    minimumValueLabel: Self.boundLabel(value: Float(bounds.lowerBound)),
                    maximumValueLabel: Self.boundLabel(value: Float(bounds.upperBound)),
                    label: { EmptyView() }
                )
            )
        } else {
            self.slider = AnyView(
                Slider(
                    value: value,
                    in: bounds,
                    minimumValueLabel: Self.boundLabel(value: Float(bounds.lowerBound)),
                    maximumValueLabel: Self.boundLabel(value: Float(bounds.upperBound)),
                    label: { EmptyView() }
                )
            )
        }
        self.title = title
        self.reset = reset
        self.value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text(title)
                Spacer()
                Self.valueLabel(value: value.wrappedValue)
                Button(action: {
                    self.reset()
                }) {
                    Image("reset")
                        .resizable()
                        .foregroundColor(Color(red: 185/255.0, green: 160/255.0, blue: 176/255.0))
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 19)
                }
                .buttonStyle(PlainButtonStyle())
            }
            slider
        }
    }
}

