//
//  TimeSource.swift
//  EphemerisRadio
//

import Foundation

/// The current time and a way to wait. Real by default; tests substitute a manual clock so a
/// whole pass can be simulated in milliseconds.
struct TimeSource: Sendable {
    let now: @Sendable () -> Date
    let sleep: @Sendable (TimeInterval) async throws -> Void

    static let system = TimeSource(
        now: { Date() },
        sleep: { seconds in try await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000)) }
    )
}
