//
//  MelFilterbankBuilder.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import Foundation

/// Default implementation of `MelProcessing`.
///
/// LAW-C1: struct — filterbank construction is stateless and deterministic.
/// LAW-C7: `Sendable` via struct + no stored mutable state.
struct MelFilterbankBuilder: MelProcessing, Sendable {
    public init() {}
    
    public func makeFilterbank(bandCount: Int, binCount: Int, sampleRate: Double,
                               minimumFrequency: Double, maximumFrequency: Double?) throws -> MelFilterbank {
        
        try validateParameters(bandCount: bandCount, binCount: binCount, sampleRate: sampleRate,
                               minimumFrequency: minimumFrequency, maximumFrequency: maximumFrequency
        )
        
        let resolvedMax = maximumFrequency ?? sampleRate / Double(DSPConstants.nyquistDivisor)
        let melMin      = hzToMel(minimumFrequency)
        let melMax      = hzToMel(resolvedMax)
        let pointCount  = bandCount + DSPConstants.nyquistDivisor
        
        let melPoints = (0..<pointCount).map { idx in
            melMin + Double(idx) * (melMax - melMin)
            / Double(bandCount + DSPConstants.firstNonDCBin)
        }
        let freqPoints = melPoints.map { melToHz($0) }
        
        let binFreqs = (0..<binCount).map { bin in
            Double(bin) * sampleRate / Double(
                (binCount - DSPConstants.firstNonDCBin)
                * DSPConstants.nyquistDivisor
            )
        }
        
        var filters = [[Float]](
            repeating: [Float](repeating: DSPConstants.zeroFloat, count: binCount),
            count: bandCount
        )
        
        for band in 0..<bandCount {
            let lo  = freqPoints[band]
            let mid = freqPoints[band + DSPConstants.firstNonDCBin]
            let hi  = freqPoints[band + DSPConstants.nyquistDivisor]
            
            for bin in 0..<binCount {
                let f = binFreqs[bin]
                switch f {
                case lo...mid:
                    filters[band][bin] = Float((f - lo) / (mid - lo))
                case mid...hi:
                    filters[band][bin] = Float((hi - f) / (hi - mid))
                default:
                    filters[band][bin] = DSPConstants.zeroFloat
                }
            }
        }
        
        return MelFilterbank(
            filters: filters,
            bandCount: bandCount,
            binCount: binCount,
            sampleRate: sampleRate,
            minimumFrequency: minimumFrequency,
            maximumFrequency: resolvedMax
        )
    }
    
    // MARK: - Private validation
    
    private func validateParameters(
        bandCount: Int,
        binCount: Int,
        sampleRate: Double,
        minimumFrequency: Double,
        maximumFrequency: Double?
    ) throws {
        guard bandCount > 0 else {
            throw AudioDSPError.invalidBandCount(bandCount)
        }
        guard binCount > 1 else {
            throw AudioDSPError.invalidBinCount(binCount)
        }
        guard sampleRate > DSPConstants.zeroDouble else {
            throw AudioDSPError.invalidSampleRate(sampleRate)
        }
        
        let resolvedMax = maximumFrequency ?? sampleRate / Double(DSPConstants.nyquistDivisor)
        guard
            minimumFrequency >= DSPConstants.zeroDouble,
            resolvedMax > minimumFrequency,
            resolvedMax <= sampleRate / Double(DSPConstants.nyquistDivisor)
        else {
            throw AudioDSPError.invalidFrequencyRange(
                minimum: minimumFrequency,
                maximum: resolvedMax
            )
        }
    }
    
    // MARK: - Private Mel ↔ Hz conversion
    
    private func hzToMel(_ hz: Double) -> Double {
        DSPConstants.melScaleMultiplier
        * log10(DSPConstants.oneDouble + hz / DSPConstants.melReferenceFrequencyHz)
    }
    
    private func melToHz(_ mel: Double) -> Double {
        DSPConstants.melReferenceFrequencyHz
        * (pow(10.0, mel / DSPConstants.melScaleMultiplier) - DSPConstants.oneDouble)
    }
}
