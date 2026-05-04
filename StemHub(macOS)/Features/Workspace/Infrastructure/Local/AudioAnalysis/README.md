# StemHub — Audio Analysis Module

## Overview

StemHub's audio analysis module compares two audio files (Version A and Version B)
to produce a structured `AudioComparisonResult` containing:

- An overall cosine similarity score (0–1)
- Per-segment similarity scores
- Time-stamped changed and matched regions
- Partial match detection (best contiguous similar window)

---

## Project Folder Structure

```text
StemHub/
├── Features/
│   └── Workspace/
│       └── Domain/
│           ├── Audio/                         ← Domain value types
│           │   ├── AudioComparisonResult.swift
│           │   ├── AudioFingerprintConfiguration.swift
│           │   ├── AudioSampleStream.swift
│           │   ├── AudioTimeRange.swift
│           │   ├── BasicAudioFingerprint.swift
│           │   ├── EnhancedAudioFingerprint.swift
│           │   ├── FingerprintMetadata.swift
│           │   └── SegmentTimeRange.swift
│           └── Protocols/
│               ├── AudioFingerprinting.swift
│               └── AudioSimilarityComparing.swift
├── Infrastructure/
│   └── Local/
│       └── AudioAnalysis/
│           ├── Decoding/                      ← AVFoundation decode pipeline
│           │   ├── AudioDecodingContext.swift
│           │   ├── AudioDecodingContextBuilding.swift
│           │   ├── DefaultAudioDecodingContextBuilder.swift
│           │   ├── AudioPCMFormatProviding.swift
│           │   ├── DefaultAudioPCMFormatFactory.swift
│           │   ├── AudioPCMBufferProviding.swift
│           │   ├── DefaultAudioPCMBufferFactory.swift
│           │   ├── AudioConverterBuilding.swift
│           │   ├── DefaultAudioConverterFactory.swift
│           │   ├── AudioConverterProcessing.swift
│           │   ├── DefaultAudioConverterRunner.swift
│           │   ├── AudioConversionValidating.swift
│           │   ├── DefaultAudioConversionStatusHandler.swift
│           │   ├── AudioSampleProviding.swift
│           │   ├── DefaultAudioSampleExtractor.swift
│           │   ├── AVFoundationAudioInputProviding.swift
│           │   ├── AVFoundationAudioInputProvider.swift
│           │   ├── AudioPCMDecoding.swift
│           │   └── DefaultAVFoundationAudioPCMDecoder.swift
│           ├── DSP/                           ← Signal processing
│           │   ├── AudioDSPFacade.swift
│           │   ├── DSPFacadeBuilding.swift
│           │   ├── DefaultDSPFacadeBuilder.swift
│           │   ├── FFTProcessing.swift
│           │   ├── FFTSetupProviding.swift
│           │   ├── VDSPFFTSetupProvider.swift
│           │   ├── VDSPFFTProcessor.swift
│           │   ├── ChromaProcessing.swift
│           │   ├── ChromaProcessor.swift
│           │   ├── DCTProcessing.swift
│           │   ├── DCTProcessor.swift
│           │   ├── LoudnessProcessing.swift
│           │   ├── LoudnessProcessor.swift
│           │   ├── MelProcessing.swift
│           │   ├── MelFilterbankBuilder.swift
│           │   ├── SpectralProcessing.swift
│           │   ├── SpectralFeatureExtractor.swift
│           │   └── WindowFunction.swift
│           ├── Fingerprinting/                ← Fingerprint pipeline
│           │   ├── AudioFeatureExtractorBuilding.swift
│           │   ├── AudioFeatureProcessing.swift
│           │   ├── AudioSampleStreamFactory.swift
│           │   ├── BasicAudioFeatureExtractorFactory.swift
│           │   ├── BasicFeatureExtractor.swift
│           │   ├── BasicAudioFingerprinter.swift
│           │   └── CachedAudioFingerprinter.swift
│           ├── Hashing/                       ← PCM content hashing
│           │   ├── PCMHashing.swift
│           │   ├── AVFoundationPCMHasher.swift
│           │   └── CachedPCMHasher.swift
│           ├── Comparison/                    ← Similarity comparison
│           │   ├── BasicAudioSimilarityComparer.swift
│           │   ├── EnhancedAudioSimilarityComparer.swift
│           │   └── AudioComparisonResultFormatter.swift
│           └── Detection/                     ← File type detection
│               ├── AudioFileProviding.swift
│               ├── MIDIFileProviding.swift
│               ├── UniformTypeMediaFileDetector.swift
│               └── UniformTypeContentTypeResolver.swift
└── Composition/
    └── WorkspaceDependencyContainer.swift      ← DI composition root
```

---

## Comparison Pipeline

### Step 1 — Load Version A and Version B

Both files are opened by `DefaultAudioDecodingContextBuilder`, which:

1. Validates the target sample rate (must be > 0).
2. Calls `.standardizedFileURL` on the input URL (LAW-I3).
3. Opens `AVAudioFile` and reads `processingFormat`.
4. Creates a mono Float32 output format via `DefaultAudioPCMFormatFactory`.
5. Creates an `AVAudioConverter` via `DefaultAudioConverterFactory`.
6. Computes input/output frame capacities and the maximum output frame count.

### Step 2 — Decode

`DefaultAVFoundationAudioPCMDecoder` runs a synchronous decode loop:

1. Allocates an output buffer (`DefaultAudioPCMBufferFactory`).
2. Runs one conversion step (`DefaultAudioConverterRunner`).
3. Validates the output status (`DefaultAudioConversionStatusHandler`).
4. Extracts `[Float]` samples (`DefaultAudioSampleExtractor`).
5. Calls `processChunk` with each extracted chunk.
6. Calls `Task.checkCancellation()` on every iteration.

### Step 3 — Stream samples to fingerprinter

`BasicAudioFingerprinter` runs two concurrent tasks via `withThrowingTaskGroup`:

| Task | Work | Priority |
|------|------|----------|
| Decode task | Calls `decoder.decodeMonoFloat32Samples`, yields `[Float]` chunks to `AudioSampleStream.continuation` | `.utility` |
| Fingerprint task | Iterates `AudioSampleStream.stream`, calls `extractor.consume(_:)` per chunk, calls `extractor.makeFingerprint(fileName:)` when done | `.utility` |

Both tasks call `Task.checkCancellation()` as their first statement (LAW-C4)
and on every async iteration (LAW-C5).

### Step 4 — Feature extraction

`BasicFeatureExtractor` accumulates one feature vector per frame:

| Index | Feature | Description |
|-------|---------|-------------|
| 0 | RMS energy | `sqrt(mean(x²))` |
| 1 | Mean absolute value | `mean(|x|)` |
| 2 | Zero-crossing rate | Sign-change count / frame length |
| 3 | First-difference energy | `mean(|xₙ - xₙ₋₁|)` |
| 4 | Crest factor | `peak / max(RMS, ε)` |
| 5 | Onset strength | `max(0, RMS - previousRMS)` |

Frame features are aggregated into `segmentCount` segments by averaging,
then L2-normalised to produce the final feature vector.

### Step 5 — Fingerprint caching

`CachedAudioFingerprinter` wraps `BasicAudioFingerprinter`:

- Derives a cache key from the file's inode + volume identifier (LAW-K2).
- Returns a cached fingerprint immediately on a hit.
- On a miss, delegates to `BasicAudioFingerprinter` and stores the result.

### Step 6 — Compare

`BasicAudioSimilarityComparer` computes the cosine similarity between the
two feature vectors. The result is a `Double` in [0, 1].

For enhanced comparison, `EnhancedAudioSimilarityComparer`:

1. Validates fingerprint compatibility (layout version, frame size, hop size,
   feature dimensions).
2. Computes whole-file cosine similarity.
3. Aligns segments using O(M×N) DTW with cosine distance as the local cost.
4. Computes per-segment cosine similarity for each aligned pair.
5. Groups contiguous segments into changed/matched `AudioTimeRange` values.
6. Detects the best sliding window of segments for a partial match.

### Step 7 — Format results

`AudioComparisonResultFormatter` (caseless enum, pure static methods) formats
an `AudioComparisonResult` into:

- A human-readable summary paragraph (`summary(for:decimalPlaces:)`).
- A segment-by-segment table with progress bars (`segmentTable(for:timeRanges:)`).

### Step 8 — Display

Results flow back to the presentation layer through `@MainActor`-isolated
ViewModels. All fingerprinting and comparison work runs off the main actor
in cooperative thread pool workers.

---

## Concurrency Model

```text
Main Actor (UI thread)
│
├── ViewModel (@MainActor)
│   │ calls async function
│   ▼
│   nonisolated async fingerprint(for:)
│
│   ├── Task (priority: .utility) — Decode
│   │   AVFoundationAudioPCMDecoder (synchronous)
│   │   yields [Float] → AudioSampleStream.continuation
│
│   └── Task (priority: .utility) — Fingerprint
│       consumes AudioSampleStream.stream
│       mutates BasicFeatureExtractor (local var, not shared)
│       returns BasicAudioFingerprint
│
└── result returned to ViewModel → @Published properties updated on MainActor
```

All async functions that cross concurrency boundaries are `nonisolated`.
No `DispatchQueue` usage — all concurrency uses Swift Structured Concurrency.
`BasicFeatureExtractor` is a value-type struct mutated in a single task — no
locking, actors, or synchronisation required on the extractor itself.

---

## How to Add a New Comparison Strategy

1. Create a new file conforming to `AudioSimilarityComparing`:

   ```swift
   struct MyNewComparer: AudioSimilarityComparing {
       typealias Fingerprint = BasicAudioFingerprint

       nonisolated func similarity(between lhs: BasicAudioFingerprint,
                                   and rhs: BasicAudioFingerprint) throws -> Double {
           // Your comparison logic here.
       }
   }
   ```

2. Place the file in `Infrastructure/Local/AudioAnalysis/Comparison/`.
3. Wire it in `WorkspaceDependencyContainer` if it is needed at the composition root, or inject it directly into the ViewModel or use case that needs it.
4. No existing types need to be modified.

---

## Architecture Laws Quick Reference

| Law | Description |
|-----|-------------|
| LAW-C1 | Async work lives in Sendable structs with nonisolated async methods |
| LAW-C3 | Protocols with async requirements are Sendable |
| LAW-C4 | Task.checkCancellation() is the first statement in every Task closure |
| LAW-C5 | Every async function checks cancellation before expensive work |
| LAW-C6 | Dependencies captured as let locals before async closures |
| LAW-D1 | No singletons, no static stored properties, no global state |
| LAW-D2 | Default init params only for leaf types |
| LAW-D3 | Protocol suffixes: Hashing, Strategy, Resolving, Scanning, Caching, Building, Processing, Providing |
| LAW-H1 | SHA-256 via CryptoKit only |
| LAW-H2 | `.hexString` via CryptoKit.Digest extension only |
| LAW-I3 | Always call `.standardizedFileURL` before use |
| LAW-K1 | Cache layer is a pure decorator, zero domain logic |
| LAW-K2 | Cache keys from inode + volume, never raw path string |
| LAW-N1 | One primary type per file |
| LAW-N2 | Private helpers are private |

---

## Summary of All Changes vs Original

| File | Change | Law(s) Fixed |
|------|--------|--------------|
| `AudioSampleStream.swift` | Replaced decoded-data struct fields with `stream`/`continuation` pair | LAW-E1 (compile error) |
| `AudioSampleStreamFactory.swift` | Fixed to return `AudioSampleStream(stream:continuation:)` | LAW-E1 (compile error) |
| `AudioFingerprintConfiguration.swift` | `static var basic` → `static func makeBasic()` | LAW-D1 |
| `LoudnessAnalysing.swift` | Split into `LoudnessProcessing.swift` + `LoudnessProcessor.swift` | LAW-N1 |
| `VDSPFFTProcessor` | Converted from `final class` to `struct` | LAW-C1 |
| `BasicAudioFingerprinter.swift` | Removed invalid `await` on sync `mutating` methods | Compile error fix |
| `CachedAudioFingerprinter.swift` | Removed default `cache` parameter; cache now injected | LAW-D2 |
| `CachedPCMHasher.swift` | Removed default `cache` parameter; cache now injected | LAW-D2 |
| `WorkspaceDependencyContainer.swift` | Fixed `AVFoundationPCMHasher()` and `BasicAudioFingerprinter()` with proper arg injection; injected caches explicitly | LAW-D2, compile errors |
| `FFTAnalysing` → `FFTProcessing` | Protocol rename + `Sendable` | LAW-D3, LAW-C3 |
| `LoudnessAnalysing` → `LoudnessProcessing` | Protocol rename + `Sendable` | LAW-D3, LAW-C3 |
| `SpectralAnalysing` → `SpectralProcessing` | Protocol rename + `Sendable` | LAW-D3, LAW-C3 |
| `MelFiltering` → `MelProcessing` | Protocol rename + `Sendable` | LAW-D3, LAW-C3 |
| `DCTTransforming` → `DCTProcessing` | Protocol rename + `Sendable` | LAW-D3, LAW-C3 |
| `ChromaExtracting` → `ChromaProcessing` | Protocol rename + `Sendable` | LAW-D3, LAW-C3 |
| `AudioConverterMaking` → `AudioConverterBuilding` | Protocol rename | LAW-D3 |
| `AudioConverterRunning` → `AudioConverterProcessing` | Protocol rename | LAW-D3 |
| `AudioConversionStatusHandling` → `AudioConversionValidating` | Protocol rename | LAW-D3 |
| `AudioPCMBufferMaking` → `AudioPCMBufferProviding` | Protocol rename | LAW-D3 |
| `AudioPCMFormatMaking` → `AudioPCMFormatProviding` | Protocol rename | LAW-D3 |
| `AudioSampleExtracting` → `AudioSampleProviding` | Protocol rename | LAW-D3 |
| `AudioFeatureExtractorMaking` → `AudioFeatureExtractorBuilding` | Protocol rename | LAW-D3 |
| `AudioFeatureExtracting` → `AudioFeatureProcessing` | Protocol rename | LAW-D3 |
| `AudioFileDetecting` → `AudioFileProviding` | Protocol rename + own file | LAW-D3, LAW-N1 |
| `MIDIFileDetecting` → `MIDIFileProviding` | Protocol rename + own file | LAW-D3, LAW-N1 |
| `AudioComparisonResultFormatter` | `struct` → caseless `enum` | LAW-D1 |
| `AudioDSPFacade` | Added `Sendable`, updated property names to match renamed protocols | LAW-C7 |
| `DefaultDSPFacadeBuilder` | Updated to use renamed protocols + `Sendable` | LAW-D3 |
| `DefaultAudioDecodingContextBuilder` | Added `.standardizedFileURL` call | LAW-I3 |
| All DSP protocol files | Added `Sendable` marking | LAW-C3 |
