//
//  DefaultAVFoundationAudioPCMDecoder.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// Default implementation of `AudioPCMDecoding` using AVFoundation.
///
/// ## Pipeline
/// For each call to `decodeMonoFloat32Samples`:
/// 1. `AudioDecodingContextBuilding` opens the file and creates the converter.
/// 2. `AVFoundationAudioInputProvider` feeds raw input frames to the converter.
/// 3. `AudioConverterProcessing` runs one conversion step per loop iteration.
/// 4. `AudioConversionValidating` inspects the output status.
/// 5. `AudioSampleProviding` extracts `[Float]` from the output buffer.
/// 6. `processChunk` is called with each extracted chunk.
///
/// ## Thread safety
/// The method is `nonisolated` and entirely synchronous. It is safe to call
/// from any thread or async context. No shared mutable state is accessed.
struct DefaultAVFoundationAudioPCMDecoder: AudioPCMDecoding {
    
    // MARK: - Dependencies
    
    private let contextBuilder: any AudioDecodingContextBuilding
    private let bufferFactory: any AudioPCMBufferProviding
    private let converterRunner: any AudioConverterProcessing
    private let sampleExtractor: any AudioSampleProviding
    private let statusHandler: any AudioConversionValidating
    
    // MARK: - Init
    
    init(
        contextBuilder: any AudioDecodingContextBuilding,
        bufferFactory: any AudioPCMBufferProviding,
        converterRunner: any AudioConverterProcessing,
        sampleExtractor: any AudioSampleProviding,
        statusHandler: any AudioConversionValidating
    ) {
        self.contextBuilder  = contextBuilder
        self.bufferFactory   = bufferFactory
        self.converterRunner = converterRunner
        self.sampleExtractor = sampleExtractor
        self.statusHandler   = statusHandler
    }
    
    // MARK: - AudioPCMDecoding
    
    nonisolated func decodeMonoFloat32Samples(from url: URL, sampleRate: Double,
                                              maxDuration: TimeInterval?, processChunk: ([Float]) throws -> Void) throws {
        // LAW-I3: Standardize before building the context.
        let standardizedURL = url.standardizedFileURL
        
        let context = try contextBuilder.context(
            for: standardizedURL,
            sampleRate: sampleRate,
            maxDuration: maxDuration
        )
        try runDecodeLoop(context: context, processChunk: processChunk)
    }
    
    // MARK: - Private decode loop
    
    private nonisolated func runDecodeLoop( context: AudioDecodingContext,
                                            processChunk: ([Float]) throws -> Void) throws {
        let inputProvider = AVFoundationAudioInputProvider(context: context)
        var emittedFrames: Int64 = 0
        
        while emittedFrames < context.maxOutputFrames {
            // LAW-C5: Check for task cancellation on every loop iteration.
            try Task.checkCancellation()
            
            let outputBuffer = try makeOutputBuffer(for: context)
            let status = try runConversion(
                outputBuffer: outputBuffer,
                context: context,
                inputProvider: inputProvider
            )
            let emitted = try emitSamples(
                from: outputBuffer,
                context: context,
                emittedFrames: emittedFrames,
                processChunk: processChunk
            )
            emittedFrames += emitted
            
            if status == .endOfStream { break }
        }
    }
    
    private nonisolated func makeOutputBuffer(for context: AudioDecodingContext) throws -> AVAudioPCMBuffer {
        try bufferFactory.buffer(
            format: context.outputFormat,
            frameCapacity: context.outputFrameCapacity,
            fileName: context.fileName
        )
    }
    
    private nonisolated func runConversion(outputBuffer: AVAudioPCMBuffer,
                                           context: AudioDecodingContext,
                                           inputProvider: AVFoundationAudioInputProviding
    ) throws -> AVAudioConverterOutputStatus {
        let status = try converterRunner.convert(
            converter: context.converter,
            outputBuffer: outputBuffer,
            inputProvider: inputProvider
        )
        try statusHandler.validate(status, fileName: context.fileName)
        return status
    }
    
    private nonisolated func emitSamples(from outputBuffer: AVAudioPCMBuffer,
                                         context: AudioDecodingContext,
                                         emittedFrames: Int64,
                                         processChunk: ([Float]) throws -> Void
    ) throws -> Int64 {
        let samples = try sampleExtractor.samples(
            from: outputBuffer,
            emittedFrames: emittedFrames,
            maxOutputFrames: context.maxOutputFrames,
            fileName: context.fileName
        )
        guard !samples.isEmpty else { return 0 }
        try processChunk(samples)
        return Int64(samples.count)
    }
}
