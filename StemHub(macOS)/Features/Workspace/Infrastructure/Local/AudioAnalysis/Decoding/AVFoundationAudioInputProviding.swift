//
//  AVFoundationAudioInputProviding.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 27.04.2026.
//

import AVFoundation
import Foundation

/// The input-block interface required by
/// `AVAudioConverter.convert(to:error:inputBlock:)`.
///
/// ## Why AnyObject?
/// AVFoundation's input block closure mutates state (`reachedEndOfStream`,
/// `readError`) across multiple sequential callbacks from the same
/// `AVAudioConverter.convert` call. Only a reference type can be mutated
/// through a closure capture. This is the explicit class-based exception
/// permitted by LAW-C1.
///
/// ## Sendable
/// Deliberately NOT `Sendable`. The input provider is created immediately
/// before the decode loop and consumed entirely within the same synchronous
/// nonisolated function. It never crosses a concurrency boundary.
protocol AVFoundationAudioInputProviding: AnyObject, Sendable {

    /// The last error produced by a read attempt, or `nil` if no error occurred.
    ///
    /// Accessed from `DefaultAudioConverterRunner.convert(...)` after the
    /// converter callback returns. Must be `nonisolated` so it can be read
    /// from a `nonisolated` context without actor hopping.
    nonisolated var readError: Error? { get }

    /// Called by `AVAudioConverter` to request the next input buffer.
    ///
    /// - Parameter outStatus: Write the appropriate
    ///   `AVAudioConverterInputStatus` value before returning.
    /// - Returns: The next `AVAudioBuffer`, or `nil` when no more data
    ///   is available or an error occurred.
    nonisolated func provideInput(outStatus: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer?
}
