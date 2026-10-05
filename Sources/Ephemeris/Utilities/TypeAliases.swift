//
//  TypeAliases.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/6/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

/// An angle in degrees.
///
/// A readability aid: it documents the unit at the declaration site but is not a
/// distinct type, so the compiler will not catch a degrees/radians mix-up.
public typealias Degrees = Double

/// An angle in radians.
///
/// A readability aid: it documents the unit at the declaration site but is not a
/// distinct type, so the compiler will not catch a degrees/radians mix-up.
public typealias Radians = Double

/// A Julian date: the continuous count of days (with fraction) since noon UTC on
/// January 1, 4713 BC in the proleptic Julian calendar.
///
/// - Note: https://en.wikipedia.org/wiki/Julian_day
public typealias JulianDate = Double
