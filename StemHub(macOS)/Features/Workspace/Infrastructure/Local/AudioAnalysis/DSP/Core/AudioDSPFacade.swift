//
//  AudioDSPFacade.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// A unified entry point for all DSP operations used by the fingerprinting pipeline.
///
/// `AudioDSPFacade` is a thin routing layer — it stores protocol existentials
/// for each DSP capability and forwards method calls with no added logic.
///
/// LAW-C1: struct — all stored properties are immutable `Sendable` existentials.
/// LAW-C7: `Sendable` conformance is structurally guaranteed:
///   - Each stored `any Protocol` requires the protocol to be `Sendable` (LAW-C3).
///   - No mutable state is stored.
struct AudioDSPFacade: Sendable {
    
    // MARK: - Dependencies (injected, all Sendable)
    
    private let fftProcessor:      any FFTProcessing
    private let melBuilder:        any MelProcessing
    private let dctProcessor:      any DCTProcessing
    private let chromaProcessor:   any ChromaProcessing
    private let spectralProcessor: any SpectralProcessing
    private let loudnessProcessor: any LoudnessProcessing
    
    // MARK: - Init
    
    init(
        fftProcessor:      any FFTProcessing,
        melBuilder:        any MelProcessing,
        dctProcessor:      any DCTProcessing,
        chromaProcessor:   any ChromaProcessing,
        spectralProcessor: any SpectralProcessing,
        loudnessProcessor: any LoudnessProcessing
    ) {
        self.fftProcessor      = fftProcessor
        self.melBuilder        = melBuilder
        self.dctProcessor      = dctProcessor
        self.chromaProcessor   = chromaProcessor
        self.spectralProcessor = spectralProcessor
        self.loudnessProcessor = loudnessProcessor
    }
    
    // MARK: - FFT
    
    func magnitudeSpectrum(from samples: [Float]) throws -> MagnitudeSpectrum {
        let frame = try DSPFrame(samples: samples)
        return try fftProcessor.magnitudeSpectrum(for: frame)
    }
    
    // MARK: - Mel filterbank
    
    func makeMelFilterbank(bandCount: Int, binCount: Int,
        sampleRate: Double, minimumFrequency: Double = DSPConstants.defaultMinimumFrequencyHz,
                           maximumFrequency: Double? = nil ) throws -> MelFilterbank {
        
        try melBuilder.makeFilterbank(
            bandCount: bandCount,
            binCount: binCount,
            sampleRate: sampleRate,
            minimumFrequency: minimumFrequency,
            maximumFrequency: maximumFrequency
        )
    }
    
    // MARK: - DCT
    
    func dct(values: [Float], coefficientCount: Int) throws -> DCTCoefficients {
        let melEnergies = MelEnergies(values: values, bandCount: values.count)
        return try dctProcessor.transform(melEnergies, coefficientCount: coefficientCount)
    }
    
    // MARK: - Chroma
    
    func chroma(from spectrum: MagnitudeSpectrum,
                referenceFrequency: Double = DSPConstants.defaultA4ReferenceFrequencyHz) throws -> ChromaVector {
        try chromaProcessor.chroma(
            from: spectrum,
            referenceFrequency: referenceFrequency
        )
    }
    
    // MARK: - Spectral features
    
    func spectralFeatures(current: MagnitudeSpectrum,
                          previous: MagnitudeSpectrum? = nil) throws -> SpectralFeatures {
        try spectralProcessor.extractFeatures(current: current, previous: previous)
    }
    
    // MARK: - Loudness
    
    func loudness(from samples: [Float]) throws -> LoudnessMeasurement {
        let frame = try DSPFrame(samples: samples)
        return try loudnessProcessor.analyse(frame)
    }
}
