//
//  RigControlError.swift
//  EphemerisRadio
//

import Foundation

/// Why a command to a radio or SDR could not be completed.
public enum RigControlError: Error, Equatable, Sendable {

    /// The connection could not be opened (nothing listening, host not found, refused)
    case connectionFailed(String)

    /// The connection dropped. The next command reconnects.
    case connectionClosed

    /// No reply arrived within the timeout
    case timeout

    /// The radio answered `RPRT` with a non-zero code: it understood the command but refused it
    /// (for example, a frequency outside its range). Hamlib uses negative codes; GQRX uses 1.
    case rejected(command: String, code: Int)

    /// The reply wasn't in the expected form
    case unexpectedResponse(command: String, response: String)

    /// The value can't be sent, such as a zero frequency or a mode name with spaces
    case invalidArgument(String)
}
