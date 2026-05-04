//
//  DefaultDSPFacadeBuilder.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Accelerate
import Foundation

/// Default production implementation of `DSPFacadeBuilding`.
///
/// Wires the complete vDSP-backed DSP stack:
///   `VDSPFFTSetupProvider` → `VDSPFFTProcessor` → `AudioDSPFacade`
///   with `MelFilterbankBuilder`, `DCTProcessor`, `ChromaProcessor`,
///   `SpectralFeatureExtractor`, and `LoudnessProcessor`.
///
/// LAW-C1: struct — stateless factory, no identity semantics required.
/// LAW-D2: All concrete leaf types constructed here are genuinely leaf types
///   (no injectable dependencies of their own). This is the composition root
///   for the DSP layer — construction here is intentional and correct.
struct DefaultDSPFacadeBuilder: DSPFacadeBuilding, Sendable {
    
    func build(frameSize: Int, targetSampleRate: Double,
               melBands: Int, silenceThreshold: Float) throws -> (facade: AudioDSPFacade, filterbank: MelFilterbank) {
        
        // 1. Create the FFT setup (manages the C pointer lifecycle).
        let log2Length    = vDSP_Length(log2(Double(frameSize)))
        let setupProvider = try VDSPFFTSetupProvider(log2Length: log2Length)
        
        // 2. Create the FFT processor that uses the setup.
        let fftProcessor = try VDSPFFTProcessor(
            setupProvider: setupProvider,
            windowFunction: .hann,
            sampleRate: targetSampleRate
        )
        
        // 3. Assemble the facade with all DSP capabilities.
        let facade = AudioDSPFacade(
            fftProcessor:      fftProcessor,
            melBuilder:        MelFilterbankBuilder(),
            dctProcessor:      DCTProcessor(),
            chromaProcessor:   ChromaProcessor(),
            spectralProcessor: SpectralFeatureExtractor(),
            loudnessProcessor: LoudnessProcessor(silenceThreshold: silenceThreshold)
        )
        
        // 4. Pre-compute the mel filterbank for the given parameters.
        let binCount   = frameSize / 2 + 1
        let filterbank = try facade.makeMelFilterbank(
            bandCount: melBands,
            binCount: binCount,
            sampleRate: targetSampleRate,
            minimumFrequency: DSPConstants.defaultMinimumFrequencyHz,
            maximumFrequency: nil
        )
        
        return (facade, filterbank)
    }
}
