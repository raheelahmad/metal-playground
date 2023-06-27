//
//  LiveCode.swift
//  MetalPlayground
//
//  Created by Raheel Ahmad on 1/9/21.
//  Copyright © 2021 Raheel Ahmad. All rights reserved.
//

import MetalKit
import SwiftUI
import Accelerate
import AVFoundation

extension AVAudioPCMBuffer {
    /// Returns audio data as an `Array` of `Float` Arrays.
    ///
    /// If stereo:
    /// - `floatChannelData?[0]` will contain an Array of left channel samples as `Float`
    /// - `floatChannelData?[1]` will contains an Array of right channel samples as `Float`
    func toFloatChannelData() -> [[Float]]? {
        // Do we have PCM channel data?
        guard let pcmFloatChannelData = floatChannelData else {
            return nil
        }

        let channelCount = Int(format.channelCount)
        let frameLength = Int(self.frameLength)
        let stride = self.stride

        // Preallocate our Array so we're not constantly thrashing while resizing as we append.
        let zeroes: [Float] = Array(repeating: 0, count: frameLength)
        var result = Array(repeating: zeroes, count: channelCount)

        // Loop across our channels...
        for channel in 0 ..< channelCount {
            // Make sure we go through all of the frames...
            for sampleIndex in 0 ..< frameLength {
                result[channel][sampleIndex] = pcmFloatChannelData[channel][sampleIndex * stride]
            }
        }

        return result
    }
}

extension AVAudioFile {
    /// converts to a 32 bit PCM buffer
    func toAVAudioPCMBuffer() -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat,
                                            frameCapacity: AVAudioFrameCount(length)) else { return nil }

        do {
            framePosition = 0
            try read(into: buffer)
            print("Created buffer with format")

        } catch let error as NSError {
            print("Cannot read into buffer " + error.localizedDescription)
        }

        return buffer
    }

    /// converts to Swift friendly Float array
    public func toFloatChannelData() -> [[Float]]? {
        guard let pcmBuffer = toAVAudioPCMBuffer(),
              let data = pcmBuffer.toFloatChannelData() else { return nil }
        return data
    }
}
/// Returns the minimums of chunks of binSize.
func binMin(samples: [Float], binSize: Int) -> [Float] {
    var out: [Float] = .init(repeating: 0.0, count: samples.count / binSize)

    // Note: we have to use a dumb while loop to avoid swift's Range and have
    //       decent perf in debug.
    var bin = 0
    while bin < out.count {

        // Note: we could do the following but it's too slow in debug
        // out[bin] = samples[(bin * binSize) ..< ((bin + 1) * binSize)].min()!

        var v = Float.greatestFiniteMagnitude
        let start: Int = bin * binSize
        let end: Int = (bin + 1) * binSize
        var i = start
        while i < end {
            v = min(samples[i], v)
            i += 1
        }
        out[bin] = v
        bin += 1
    }
    return out
}

/// Returns the maximums of chunks of binSize.
func binMax(samples: [Float], binSize: Int) -> [Float] {
    var out: [Float] = .init(repeating: 0.0, count: samples.count / binSize)

    // Note: we have to use a dumb while loop to avoid swift's Range and have
    //       decent perf in debug.
    var bin = 0
    while bin < out.count {

        // Note: we could do the following but it's too slow in debug
        // out[bin] = samples[(bin * binSize) ..< ((bin + 1) * binSize)].max()!

        var v = -Float.greatestFiniteMagnitude
        let start: Int = bin * binSize
        let end: Int = (bin + 1) * binSize
        var i = start
        while i < end {
            v = max(samples[i], v)
            i += 1
        }
        out[bin] = v
        bin += 1
    }
    return out
}

extension MTLDevice {
    func makeBuffer(_ values: [Float]) -> MTLBuffer? {
        makeBuffer(bytes: values, length: MemoryLayout<Float>.size * values.count)
    }
}

public extension MTLRenderCommandEncoder {
    func setFragmentBytes<T>(_ value: T, index: Int) {
        var copy = value
        setFragmentBytes(&copy, length: MemoryLayout<T>.size, index: index)
    }

    func setFragmentBytes<T>(_ value: T, index: Int32) {
        var copy = value
        setFragmentBytes(&copy, length: MemoryLayout<T>.size, index: Int(index))
    }
}

extension Color {
    var components: SIMD4<Float> {

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        #if canImport(UIKit)
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        #elseif canImport(AppKit)
        NSColor(self).usingColorSpace(.deviceRGB)!.getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif

        return .init(Float(r), Float(g), Float(b), Float(a))
    }
}

public final class SampleBuffer: Sendable {
    let samples: [Float]

    /// Initialize the buffer with samples
    public init(samples: [Float]) {
        self.samples = samples
    }

    /// Number of samples
    public var count: Int {
        samples.count
    }
}

final class LiveCodeScene: Scene {
    let name = "Live Code"

    let vertexFuncName = "liveCodeVertexShader"
    let fragmentFuncName = "liveCodeFragmentShader"
    private let compileQueue = DispatchQueue.init(label: "Shader compile queue")

    private var shaderContents = ""
    var sample: SampleBuffer = .init(samples: [])

    let queue = DispatchQueue(label: "live-code")
    let engine: AVAudioEngine

    init() {
        engine = AVAudioEngine()
        _ = engine.mainMixerNode
        engine.prepare()
        do {
            try engine.start()
        } catch {
            print(error.localizedDescription)
        }
    }

    func processAudioData(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = buffer.frameLength

        //rms
        let rmsValue = rms(data: channelData, frameLength: UInt(frames))
        loudnessMagnitude = rmsValue

        //fft
        let fftMagnitudes =  Self.fft(data: channelData, setup: fftSetup!)
        frequencyVertices = fftMagnitudes
//        print(fftMagnitudes.max()!)
    }

    static func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float]{
           //output setup
           var realIn = [Float](repeating: 0, count: 1024)
           var imagIn = [Float](repeating: 0, count: 1024)
           var realOut = [Float](repeating: 0, count: 1024)
           var imagOut = [Float](repeating: 0, count: 1024)

           //fill in real input part with audio samples
           for i in 0...1023 {
               realIn[i] = data[i]
           }


           vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)

           //our results are now inside realOut and imagOut

           //package it inside a complex vector representation used in the vDSP framework
           var complex = DSPSplitComplex(realp: &realOut, imagp: &imagOut)

           //setup magnitude output
           var magnitudes = [Float](repeating: 0, count: 512)

           //calculate magnitude results
           vDSP_zvabs(&complex, 1, &magnitudes, 1, 512)

           //normalize
           var normalizedMagnitudes = [Float](repeating: 0.0, count: 512)
           var scalingFactor = Float(30.0/512)
           vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, 512)

           return normalizedMagnitudes
       }

       static func interpolate(current: Float, previous: Float) -> [Float]{
           var vals = [Float](repeating: 0, count: 11)
           vals[10] = current
           vals[5] = (current + previous)/2
           vals[2] = (vals[5] + previous)/2
           vals[1] = (vals[2] + previous)/2
           vals[8] = (vals[5] + current)/2
           vals[9] = (vals[10] + current)/2
           vals[7] = (vals[5] + vals[9])/2
           vals[6] = (vals[5] + vals[7])/2
           vals[3] = (vals[1] + vals[5])/2
           vals[4] = (vals[3] + vals[5])/2
           vals[0] = (previous + vals[1])/2

           return vals
       }

    var prevRMSValue : Float = 0.3

        //fft setup object for 1024 values going forward (time domain -> frequency domain)
    let fftSetup = vDSP_DFT_zop_CreateSetup(nil, 1024, vDSP_DFT_Direction.FORWARD)


    private func rms(data: UnsafeMutablePointer<Float>, frameLength: UInt) -> Float {
        var val : Float = 0
        vDSP_measqv(data, 1, &val, frameLength)

        var db = 10*log10f(val)
        //inverse dB to +ve range where 0(silent) -> 160(loudest)
        db = 160 + db;
        //Only take into account range from 120->160, so FSR = 40
        db = db - 120

        let dividor = Float(40/0.3)
        var adjustedVal = 0.3 + db/dividor

        //cutoff
        if (adjustedVal < 0.3) {
            adjustedVal = 0.3
        } else if (adjustedVal > 0.6) {
            adjustedVal = 0.6
        }
        return adjustedVal
    }

    func tearDown() {
    }

    private var device: MTLDevice? {
        didSet {
            if let device {
                loudnessBuffer = device.makeBuffer(bytes: &loudnessMagnitude, length: MemoryLayout<Float>.stride)
                freqeuencyBuffer = device.makeBuffer(bytes: frequencyVertices, length: frequencyVertices.count * MemoryLayout<Float>.stride, options: [])!
                    
            }
        }
    }
    private var pixelFormat: MTLPixelFormat?

    private var loudnessMagnitude: Float = 0 {
        didSet {
            loudnessBuffer = device?.makeBuffer(bytes: &loudnessMagnitude, length: MemoryLayout<Float>.stride)
        }
    }
    private var loudnessBuffer: MTLBuffer?
    private var freqeuencyBuffer : MTLBuffer!
    public var frequencyVertices : [Float] = [Float](repeating: 0, count: 361) {
        didSet{
            let sliced = Array(frequencyVertices[0..<361])
            if let device {
                freqeuencyBuffer = device.makeBuffer(bytes: sliced, length: sliced.count * MemoryLayout<Float>.stride, options: [])!
            }
        }
    }

    private var built: Built?

    func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat, built: @escaping (MTLRenderPipelineState, MTLBuffer) -> ()) {
        self.device = device
        self.pixelFormat = pixelFormat

        self.built = built

        compile()
    }

    func tick(time: Float) {
        compileQueue.async {
            self.compile()
        }
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
    }

    private func compile() {
        let fm = FileManager()
        let filename = #filePath as NSString
        let shaderPath: String = (filename.deletingPathExtension) + ".metal"
        let helpersPath = (filename.deletingLastPathComponent as NSString).deletingLastPathComponent + "/Helpers.metal"
        guard
            let shaderContentsData = fm.contents(atPath: shaderPath),
            let helpersData = fm.contents(atPath: helpersPath),
            var shaderContents = String(data: shaderContentsData, encoding: .utf8),
            let helperContents = String(data: helpersData, encoding: .utf8)
        else {
            assertionFailure()
            return
        }
        var shaderContentLines = shaderContents.split(separator: "\n")
        if let headerIndex = shaderContentLines.firstIndex(where: { $0 == "#include \"../ShaderHeaders.h\"" }) {
            shaderContentLines.remove(at: headerIndex)

            var headerLines = helperContents.split(separator: "\n")
            if let helperHeaderIndex = headerLines.firstIndex(where: { String($0) == "#include \"ShaderHeaders.h\"" }) {
                headerLines.remove(at: helperHeaderIndex)
            }
            shaderContentLines.insert(contentsOf: headerLines, at: headerIndex)
        }
        shaderContents = shaderContentLines.joined(separator: "\n")

        let oldValue = self.shaderContents
        self.shaderContents = shaderContents

        guard shaderContents != oldValue else {
            return
        }

        do {

            guard let device = self.device, let pixelFormat = self.pixelFormat else {
                fatalError()
            }


            let pipelineDesc = MTLRenderPipelineDescriptor()
            let library = try device.makeLibrary(source: shaderContents, options: nil)
            pipelineDesc.vertexFunction = library.makeFunction(name: vertexFuncName)
            pipelineDesc.fragmentFunction = library.makeFunction(name: fragmentFuncName)
            pipelineDesc.colorAttachments[0].pixelFormat = pixelFormat

            let pipeline = (try? device.makeRenderPipelineState(descriptor: pipelineDesc))!

            let vertexBuffer = device.makeBuffer(bytes: basicVertices, length: MemoryLayout<Vertex>.stride * basicVertices.count, options: [])
            DispatchQueue.main.async {
                self.built?(pipeline, vertexBuffer!)
            }
        } catch {
            print(error.localizedDescription)
        }
    }

}
