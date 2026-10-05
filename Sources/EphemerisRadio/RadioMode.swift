//
//  RadioMode.swift
//  EphemerisRadio
//

import Foundation

/// A demodulation mode, by its rigctl name.
///
/// The constants are the modes that Hamlib, SDR++ and GQRX all understand. Other names work
/// as string literals, such as `"WFM_ST"` for GQRX's stereo FM, but not every program knows
/// every name.
public struct RadioMode: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {

    /// The mode name as sent to the radio
    public let rawValue: String

    /// Creates a mode from its rigctl name.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a mode from a string literal, such as `"WFM_ST"`.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Narrow FM: voice repeaters, APRS and most amateur satellite downlinks
    public static let fm: RadioMode = "FM"

    /// Wide FM: broadcast-style signals, and NOAA APT weather images (about 34 kHz wide)
    public static let wfm: RadioMode = "WFM"

    /// Amplitude modulation
    public static let am: RadioMode = "AM"

    /// Upper sideband: linear transponders and SSB telemetry
    public static let usb: RadioMode = "USB"

    /// Lower sideband
    public static let lsb: RadioMode = "LSB"

    /// Morse code (CW) beacons
    public static let cw: RadioMode = "CW"

    /// Whether the name can be sent safely: letters, digits and underscores only.
    var isValid: Bool {
        !rawValue.isEmpty && rawValue.unicodeScalars.allSatisfy {
            CharacterSet.alphanumerics.contains($0) || $0 == "_"
        }
    }
}
