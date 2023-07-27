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

final class AudioVizScene: Playground {
    var fileName: String {
        "Explorations/AudioViz"
    }

    let vertexFuncName = "audioVizVertexShader"
    let fragmentFuncName = "audioVizFragmentShader"

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let file = Bundle.main.url(forResource: "raga", withExtension: "mp3")!
            //            let file = Bundle.main.url(forResource: "who", withExtension: "mp3")!
            //            let file = Bundle.main.url(forResource: "laila", withExtension: "m4a")!
            //            let file = Bundle.main.url(forResource: "malabar", withExtension: "mp3")!
            let audio = try! AVAudioFile(forReading: file)
            let format = audio.processingFormat
            let player = AVAudioPlayerNode()
            self.engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, time in
                self?.processAudioData(buffer: buffer)
            }
            self.engine.attach(player)
            self.engine.connect(player, to: self.engine.mainMixerNode, format: format)
            player.scheduleFile(audio, at: nil)
            player.play()
        }
    }

    var ready: Bool {
        self.loudnessBuffer != nil && self.freqeuencyBuffer != nil
    }

    func processAudioData(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = buffer.frameLength

        //rms
        let rmsValue = rms(data: channelData, frameLength: UInt(frames))
        loudnessMagnitude = rmsValue

        //fft
        let fftMagnitudes =  AudioVizScene.fft(data: channelData, setup: fftSetup!)
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

    func tick(time: Float) {
    }

    func setUniforms(device: MTLDevice, encoder: MTLRenderCommandEncoder) {
        if self.device !== device {
            self.device = device
        }
        guard
            let loudnessBuffer = loudnessBuffer,
            let frequencyBuffer = freqeuencyBuffer
        else {
            return
        }
        encoder.setFragmentBuffer(loudnessBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(frequencyBuffer, offset: 0, index: 2)
    }

}
