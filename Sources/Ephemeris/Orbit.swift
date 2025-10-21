//
//  Orbit.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/23/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

/// Represents an orbital path using Keplerian orbital elements.
///
/// `Orbit` encapsulates the six classical orbital elements that describe
/// the shape, size, and orientation of a satellite's orbit around Earth.
/// It conforms to the `Orbitable` protocol and provides methods to calculate
/// satellite positions at any given time.
///
/// ## Example Usage
/// ```swift
/// let tleString = """
/// ISS (ZARYA)
/// 1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
/// 2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
/// """
/// let tle = try TwoLineElement(from: tleString)
/// let orbit = Orbit(from: tle)
/// let position = try orbit.calculatePosition(at: Date())
/// print("Latitude: \(position.latitude)°")
/// ```
///
/// - Note: Orbital calculations are based on Keplerian orbital mechanics and use
///         WGS84 physical constants for accuracy.
public struct Orbit: Orbitable {
    
    // MARK: - Size of Orbit
    
    /// Describes half of the size of the orbit path from Perigee to Apogee.
    /// Denoted by ( a ) in (km)
    public let semimajorAxis: Double
    
    // MARK: - Shape of Orbit
    
    /// Describes the shape of the orbital path.
    /// Denoted by ( e ) with a value between 0 and 1.
    public let eccentricity: Double
    
    // MARK: - Orientation of Orbit
    
    /// The "tilt" in degrees from the vectors perpendicular to the orbital and equatorial planes
    /// Denoted by ( i ) and is in degrees 0–180°
    public let inclination: Degrees
    
    /// The "swivel" of the orbital plane in degrees in reference to the vernal equinox to the 'node' that corresponds
    /// with the object passing the equator in a northerly direction.
    /// Denoted by ( Ω ) in degrees
    public let rightAscensionOfAscendingNode: Degrees
    
    /// Describes the orientation of perigee on the orbital plane with reference to the right ascension of the ascending node
    /// Denoted by ( ω ) in degrees
    public let argumentOfPerigee: Degrees
    
    // MARK: - Position of Craft
    
    /// The true angle between the position of the craft relative to perigee along the orbital path.
    /// Denoted as (ν or θ)
    /// Range between 0–360°
    ///
    /// - Note: This is a computed property that calculates the true anomaly from the mean anomaly
    /// using the eccentric anomaly as an intermediate step. If the calculation cannot be performed
    /// (e.g., due to singularities), it returns the mean anomaly as a fallback.
    public var trueAnomaly: Degrees {
        return calculateTrueAnomalyFromMean()
    }
    
    /// The position of the craft with respect to the mean motion.
    /// Denoted as (M)
    ///
    /// https://www.youtube.com/watch?v=cf9Jh44kL20
    ///
    /// - Note: Calculated as
    ///     n = mean motion
    ///     t = time in motion
    ///     M = Current mean anomaly
    ///     M(Δt) = n(Δt) + M
    public let meanAnomaly: Degrees
    
    /// The average speed an object moves throughout an orbit.
    /// Denoted as (n)
    ///
    /// https://www.youtube.com/watch?v=cf9Jh44kL20
    ///
    /// - Note: Calculated as
    ///     M = Gravitational Constant of Earth (3.986004418e^5 km^3/ s^2)
    ///     a = Semimajor axis
    ///     Mean Motion (n) = sqrt( M / a^3 )
    public let meanMotion: Double
    
    // MARK: - Private
    private let twoLineElement: TwoLineElement
    
    // MARK: - Initializers
    
    /// Creates an orbit from Two-Line Element (TLE) data.
    ///
    /// This initializer extracts orbital elements from a parsed TLE and calculates
    /// the semi-major axis from the mean motion value.
    ///
    /// - Parameter twoLineElement: A parsed Two-Line Element containing orbital data
    ///
    /// ## Example
    /// ```swift
    /// let tle = try TwoLineElement(from: tleString)
    /// let orbit = Orbit(from: tle)
    /// ```
    public init(from twoLineElement: TwoLineElement) {
        self.semimajorAxis = Orbit.calculateSemimajorAxis(meanMotion: twoLineElement.meanMotion)
        self.eccentricity = twoLineElement.eccentricity
        self.inclination = twoLineElement.inclination
        self.rightAscensionOfAscendingNode = twoLineElement.rightAscension
        self.argumentOfPerigee = twoLineElement.argumentOfPerigee
        self.meanMotion = twoLineElement.meanMotion
        self.meanAnomaly = twoLineElement.meanAnomaly
        self.twoLineElement = twoLineElement
    }
    
    // MARK: - Functions
    
    /// Represents a geographic position with latitude, longitude, and altitude.
    ///
    /// This structure holds the calculated position of a satellite at a specific time,
    /// expressed in geographic coordinates relative to Earth's surface.
    public struct Position {
        /// Latitude in degrees (-90 to 90), where positive values indicate north
        public let latitude: Double
        /// Longitude in degrees (-180 to 180), where positive values indicate east
        public let longitude: Double
        /// Altitude in kilometers above Earth's surface
        public let altitude: Double
        
        /// Creates a position with the specified coordinates.
        ///
        /// - Parameters:
        ///   - latitude: Latitude in degrees (-90 to 90)
        ///   - longitude: Longitude in degrees (-180 to 180)
        ///   - altitude: Altitude in kilometers above Earth's surface
        public init(latitude: Double, longitude: Double, altitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
            self.altitude = altitude
        }
    }
    
    /// Represents a single point along a satellite's ground track.
    ///
    /// A ground track shows the path traced by the satellite's sub-satellite point
    /// (the point on Earth's surface directly below the satellite) over time.
    /// This is useful for visualizing satellite coverage, planning observations,
    /// and understanding orbital mechanics.
    ///
    /// ## Example Usage
    /// ```swift
    /// let groundTrack = try orbit.groundTrack(from: start, to: end, stepSeconds: 60)
    /// for point in groundTrack {
    ///     print("\(point.time): \(point.latitudeDeg)°N, \(point.longitudeDeg)°E")
    /// }
    /// ```
    public struct GroundTrackPoint {
        /// The time of this ground track point
        public let time: Date
        
        /// Geodetic latitude in degrees (-90 to 90)
        public let latitudeDeg: Double
        
        /// Geodetic longitude in degrees (-180 to 180)
        public let longitudeDeg: Double
        
        /// Creates a ground track point.
        ///
        /// - Parameters:
        ///   - time: The time of this point
        ///   - latitudeDeg: Geodetic latitude in degrees
        ///   - longitudeDeg: Geodetic longitude in degrees
        public init(time: Date, latitudeDeg: Double, longitudeDeg: Double) {
            self.time = time
            self.latitudeDeg = latitudeDeg
            self.longitudeDeg = longitudeDeg
        }
    }
    
    /// Represents a single point along a satellite's sky track as seen from an observer.
    ///
    /// A sky track shows the path traced by the satellite across the observer's sky
    /// in horizontal coordinates (azimuth and elevation). This is useful for planning
    /// observations, pointing antennas, and visualizing satellite passes.
    ///
    /// ## Example Usage
    /// ```swift
    /// let skyTrack = try orbit.skyTrack(for: observer, from: start, to: end, stepSeconds: 10)
    /// for point in skyTrack {
    ///     print("\(point.time): Az \(point.azimuthDeg)°, El \(point.elevationDeg)°")
    /// }
    /// ```
    public struct SkyTrackPoint {
        /// The time of this sky track point
        public let time: Date
        
        /// Azimuth angle in degrees (0-360), measured clockwise from north
        public let azimuthDeg: Double
        
        /// Elevation angle in degrees (-90 to 90), angle above the horizon
        public let elevationDeg: Double
        
        /// Creates a sky track point.
        ///
        /// - Parameters:
        ///   - time: The time of this point
        ///   - azimuthDeg: Azimuth angle in degrees
        ///   - elevationDeg: Elevation angle in degrees
        public init(time: Date, azimuthDeg: Double, elevationDeg: Double) {
            self.time = time
            self.azimuthDeg = azimuthDeg
            self.elevationDeg = elevationDeg
        }
    }

    /// Calculates the ECI (Earth-Centered Inertial) position and velocity vectors.
    ///
    /// This internal method computes the satellite's state vector in the ECI frame,
    /// which is needed for topocentric calculations and other advanced operations.
    ///
    /// - Parameter date: The date and time for which to calculate the state vector
    /// - Returns: Tuple of (position vector in km, velocity vector in km/s) in ECI frame
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    ///
    /// - Note: Internal method used by calculatePosition and topocentric calculations
    func calculateECIStateVector(at date: Date) throws -> (position: Vector3D, velocity: Vector3D) {
        let julianDate = Date.julianDay(from: date)!
        
        // Calculate 3 anomalies
        let currentMeanAnomaly = self.meanAnomalyForJulianDate(julianDate: julianDate)
        let currentEccentricAnomaly = Orbit.calculateEccentricAnomaly(eccentricity: self.eccentricity, meanAnomaly: currentMeanAnomaly)
        let currentTrueAnomaly = try Orbit.calculateTrueAnomaly(eccentricity: self.eccentricity, eccentricAnomaly: currentEccentricAnomaly)
        
        // Calculate the radius and position in the orbital plane
        let orbitalRadius = self.semimajorAxis * (1.0 - self.eccentricity * cos(currentEccentricAnomaly.inRadians()))
        
        // Position in orbital plane
        let x_orb = orbitalRadius * cos(currentTrueAnomaly.inRadians())
        let y_orb = orbitalRadius * sin(currentTrueAnomaly.inRadians())
        
        // Velocity in orbital plane (using vis-viva equation)
        let µ = PhysicalConstants.Earth.µ
        let h = sqrt(µ * self.semimajorAxis * (1.0 - self.eccentricity * self.eccentricity)) // Specific angular momentum
        let vx_orb = -µ / h * sin(currentTrueAnomaly.inRadians())
        let vy_orb = µ / h * (self.eccentricity + cos(currentTrueAnomaly.inRadians()))
        
        // Transform from orbital plane to ECI frame
        let argOfPerigeeRad = self.argumentOfPerigee.inRadians()
        let inclinationRad = self.inclination.inRadians()
        let raanRad = self.rightAscensionOfAscendingNode.inRadians()
        
        let cosω = cos(argOfPerigeeRad)
        let sinω = sin(argOfPerigeeRad)
        let cosΩ = cos(raanRad)
        let sinΩ = sin(raanRad)
        let cosi = cos(inclinationRad)
        let sini = sin(inclinationRad)
        
        // Position transformation to ECI
        let x_eci = (cosΩ * cosω - sinΩ * sinω * cosi) * x_orb + (-cosΩ * sinω - sinΩ * cosω * cosi) * y_orb
        let y_eci = (sinΩ * cosω + cosΩ * sinω * cosi) * x_orb + (-sinΩ * sinω + cosΩ * cosω * cosi) * y_orb
        let z_eci = (sinω * sini) * x_orb + (cosω * sini) * y_orb
        
        // Velocity transformation to ECI
        let vx_eci = (cosΩ * cosω - sinΩ * sinω * cosi) * vx_orb + (-cosΩ * sinω - sinΩ * cosω * cosi) * vy_orb
        let vy_eci = (sinΩ * cosω + cosΩ * sinω * cosi) * vx_orb + (-sinΩ * sinω + cosΩ * cosω * cosi) * vy_orb
        let vz_eci = (sinω * sini) * vx_orb + (cosω * sini) * vy_orb
        
        return (Vector3D(x: x_eci, y: y_eci, z: z_eci), Vector3D(x: vx_eci, y: vy_eci, z: vz_eci))
    }
    
    /// Calculates the geographic position of the satellite at a specific time.
    ///
    /// This method performs a complete orbital propagation from the epoch time to the
    /// specified date, calculating the satellite's position in Earth-centered, Earth-fixed
    /// (ECEF) coordinates and converting them to latitude, longitude, and altitude.
    ///
    /// The calculation involves:
    /// 1. Computing the current mean anomaly from the mean motion
    /// 2. Solving for eccentric anomaly using Newton-Raphson iteration
    /// 3. Calculating the true anomaly
    /// 4. Transforming from orbital plane to Earth-fixed coordinates
    /// 5. Accounting for Earth's rotation (sidereal time)
    ///
    /// - Parameter date: The date and time for which to calculate the position.
    ///                   If `nil`, uses the current date and time.
    /// - Returns: A `Position` object containing latitude, longitude, and altitude
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    ///
    /// ## Example
    /// ```swift
    /// let position = try orbit.calculatePosition(at: Date())
    /// print("Satellite is at \(position.latitude)°N, \(position.longitude)°E")
    /// print("Altitude: \(position.altitude) km")
    /// ```
    ///
    /// - Note: Transform math based on https://www.csun.edu/~hcmth017/master/node20.html
    ///         Implementation inspired by ZeitSatTrack (Apache 2.0)
    public func calculatePosition(at date: Date?) throws -> Position {
        
        // Current parameters at this specific time.
        let julianDate = Date.julianDay(from: date ?? Date())!

        // Calculate 3 anomalies
        let currentMeanAnomaly = self.meanAnomalyForJulianDate(julianDate: julianDate)
        let currentEccentricAnomaly = Orbit.calculateEccentricAnomaly(eccentricity: self.eccentricity, meanAnomaly: currentMeanAnomaly)
        let currentTrueAnomaly = try Orbit.calculateTrueAnomaly(eccentricity: self.eccentricity, eccentricAnomaly: currentEccentricAnomaly)
        
        // Calculate the XYZ coordinates on the orbital plane
        let orbitalRadius = self.semimajorAxis - (self.semimajorAxis * self.eccentricity) * cos(currentEccentricAnomaly.inRadians())
        let x = orbitalRadius * cos(currentTrueAnomaly.inRadians())
        let y = orbitalRadius * sin(currentTrueAnomaly.inRadians())
        let z = 0.0
        
        // Rotate about z''' by the argument of perigee.
        let argOfPerigeeRads = self.argumentOfPerigee.inRadians()
        let xByPerigee = cos(argOfPerigeeRads) * x - sin(argOfPerigeeRads) * y
        let yByPerigee = sin(argOfPerigeeRads) * x + cos(argOfPerigeeRads) * y
        let zByPerigee = z
        
        // Rotate about x'' axis by inclination.
        let inclinationRads = self.inclination.inRadians()
        let xInclination = xByPerigee
        let yInclination = cos(inclinationRads) * yByPerigee - sin(inclinationRads) * zByPerigee
        let zInclination = sin(inclinationRads) * yByPerigee + cos(inclinationRads) * zByPerigee
        
        // Rotate about z' axis by right ascension of the ascending node.
        let raanRads = self.rightAscensionOfAscendingNode.inRadians()
        let xRaan = cos(raanRads) * xInclination - sin(raanRads) * yInclination
        let yRaan = sin(raanRads) * xInclination + cos(raanRads) * yInclination
        let zRaan = zInclination
        
        // Rotate about z axis by the rotation of the earth.
        let rotationFromGeocentric = Date.greenwichSideRealTime(from: julianDate)
        let rotationFromGeocentricRad = -rotationFromGeocentric
        let xFinal = cos(rotationFromGeocentricRad) * xRaan - sin(rotationFromGeocentricRad) * yRaan
        let yFinal = sin(rotationFromGeocentricRad) * xRaan + cos(rotationFromGeocentricRad) * yRaan
        let zFinal = zRaan
        
        // Geocoordinates
        let earthsRadius = PhysicalConstants.Earth.radius
        let latitude = 90.0 - acos(zFinal / sqrt(xFinal * xFinal + yFinal * yFinal + zFinal * zFinal)).inDegrees()
        let longitude = atan2(yFinal, xFinal).inDegrees()
        let altitude = orbitalRadius - earthsRadius

        return Position(latitude: latitude, longitude: longitude, altitude: altitude)
    }
}

// MARK: - Observer-Based Calculations

extension Orbit {
    /// Calculates topocentric (observer-relative) coordinates for the satellite.
    ///
    /// This method computes the satellite's position as seen from a specific observer
    /// location on Earth, returning azimuth, elevation, range, and range rate.
    ///
    /// - Parameters:
    ///   - date: The date and time for the calculation
    ///   - observer: The observer's location on Earth
    ///   - applyRefraction: Whether to apply atmospheric refraction correction (default: false)
    /// - Returns: Topocentric coordinates (azimuth, elevation, range, range rate)
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    ///
    /// ## Example
    /// ```swift
    /// let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
    /// let topo = try orbit.topocentric(at: Date(), for: observer)
    /// print("Az: \(topo.azimuthDeg)°, El: \(topo.elevationDeg)°")
    /// ```
    ///
    /// - Note: Coordinate transformations follow Vallado, "Fundamentals of Astrodynamics"
    public func topocentric(at date: Date, for observer: Observer, applyRefraction: Bool = false) throws -> Topocentric {
        // Get Julian date and GMST
        let julianDate = Date.julianDay(from: date)!
        let gmst = Date.greenwichSideRealTime(from: julianDate)
        
        // Calculate satellite position and velocity in ECI frame
        let (eciPosition, eciVelocity) = try calculateECIStateVector(at: date)
        
        // Transform satellite position and velocity to ECEF
        let satECEF = CoordinateTransforms.eciToECEF(eciPosition: eciPosition, gmst: gmst)
        let satVelECEF = CoordinateTransforms.eciVelocityToECEF(eciPosition: eciPosition, eciVelocity: eciVelocity, gmst: gmst)
        
        // Calculate observer position in ECEF
        let obsECEF = CoordinateTransforms.geodeticToECEF(
            latitudeDeg: observer.latitudeDeg,
            longitudeDeg: observer.longitudeDeg,
            altitudeMeters: observer.altitudeMeters
        )
        
        // Transform to ENU (local observer frame)
        let enu = CoordinateTransforms.ecefToENU(
            ecefPosition: satECEF,
            observerECEF: obsECEF,
            observerLatDeg: observer.latitudeDeg,
            observerLonDeg: observer.longitudeDeg
        )
        
        // Calculate azimuth, elevation, and range
        let (azimuth, elevation, range) = CoordinateTransforms.enuToAzEl(enu: enu)
        
        // Apply refraction correction if requested
        let correctedElevation = applyRefraction ? CoordinateTransforms.applyRefraction(elevationDeg: elevation) : elevation
        
        // Calculate range rate (rate of change of distance)
        // Project velocity onto the line-of-sight vector
        let relativePos = satECEF.subtract(obsECEF)
        let rangeRate = relativePos.dot(satVelECEF) / range
        
        return Topocentric(
            azimuthDeg: azimuth,
            elevationDeg: correctedElevation,
            rangeKm: range,
            rangeRateKmPerSec: rangeRate
        )
    }
    
    /// Predicts satellite passes over an observer's location within a time window.
    ///
    /// This method identifies all satellite passes (periods when the satellite is above
    /// the specified minimum elevation) within the given time range. For each pass, it
    /// determines the acquisition of signal (AOS), maximum elevation, and loss of signal (LOS).
    ///
    /// - Parameters:
    ///   - observer: The observer's location on Earth
    ///   - start: Start of the search window
    ///   - end: End of the search window
    ///   - minElevationDeg: Minimum elevation angle in degrees (default: 0°)
    ///   - stepSeconds: Time step for coarse search in seconds (default: 30s)
    /// - Returns: Array of PassWindow objects, one for each pass found
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    ///
    /// ## Algorithm
    /// 1. Coarse search with specified time step to detect elevation sign changes
    /// 2. Bisection search to refine AOS and LOS times to ±1 second accuracy
    /// 3. Golden-section search to find precise maximum elevation within the pass
    ///
    /// ## Example
    /// ```swift
    /// let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
    /// let now = Date()
    /// let tomorrow = now.addingTimeInterval(24 * 3600)
    /// let passes = try orbit.predictPasses(for: observer, from: now, to: tomorrow, minElevationDeg: 10)
    ///
    /// for pass in passes {
    ///     print("AOS: \(pass.aos.time) at \(pass.aos.azimuthDeg)°")
    ///     print("MAX: \(pass.max.time) at \(pass.max.elevationDeg)° elevation")
    ///     print("LOS: \(pass.los.time) at \(pass.los.azimuthDeg)°")
    ///     print("Duration: \(pass.duration) seconds")
    /// }
    /// ```
    ///
    /// - Note: Algorithm based on Vallado, "Fundamentals of Astrodynamics and Applications"
    public func predictPasses(
        for observer: Observer,
        from start: Date,
        to end: Date,
        minElevationDeg: Double = 0,
        stepSeconds: Double = 30
    ) throws -> [PassWindow] {
        var passes: [PassWindow] = []
        
        var currentTime = start
        var previousElevation: Double? = nil
        var passStartTime: Date? = nil
        
        // Coarse search for passes
        while currentTime <= end {
            let topo = try topocentric(at: currentTime, for: observer, applyRefraction: false)
            let currentElevation = topo.elevationDeg
            
            if let prevElev = previousElevation {
                // Detect AOS: crossing from below to above minimum elevation
                if prevElev < minElevationDeg && currentElevation >= minElevationDeg {
                    passStartTime = currentTime.addingTimeInterval(-stepSeconds)
                }
                
                // Detect LOS: crossing from above to below minimum elevation
                if prevElev >= minElevationDeg && currentElevation < minElevationDeg {
                    if let startTime = passStartTime {
                        // We found a complete pass, now refine it
                        let passEndTime = currentTime
                        
                        // Refine AOS time
                        let aosTime = try refineElevationCrossing(
                            observer: observer,
                            t1: startTime,
                            t2: startTime.addingTimeInterval(stepSeconds),
                            targetElevation: minElevationDeg,
                            risingEdge: true
                        )
                        
                        // Refine LOS time
                        let losTime = try refineElevationCrossing(
                            observer: observer,
                            t1: passEndTime.addingTimeInterval(-stepSeconds),
                            t2: passEndTime,
                            targetElevation: minElevationDeg,
                            risingEdge: false
                        )
                        
                        // Find maximum elevation within the pass
                        let maxResult = try findMaxElevation(
                            observer: observer,
                            t1: aosTime,
                            t2: losTime
                        )
                        
                        // Get azimuth at AOS and LOS
                        let aosAzimuth = try topocentric(at: aosTime, for: observer).azimuthDeg
                        let losAzimuth = try topocentric(at: losTime, for: observer).azimuthDeg
                        
                        let pass = PassWindow(
                            aos: PassWindow.Point(time: aosTime, azimuthDeg: aosAzimuth),
                            max: (time: maxResult.time, elevationDeg: maxResult.elevation, azimuthDeg: maxResult.azimuth),
                            los: PassWindow.Point(time: losTime, azimuthDeg: losAzimuth)
                        )
                        
                        passes.append(pass)
                        passStartTime = nil
                    }
                }
            }
            
            previousElevation = currentElevation
            currentTime = currentTime.addingTimeInterval(stepSeconds)
        }
        
        return passes
    }
    
    /// Refines the time of an elevation crossing using bisection search.
    ///
    /// - Parameters:
    ///   - observer: The observer's location
    ///   - t1: Start of search interval
    ///   - t2: End of search interval
    ///   - targetElevation: The elevation angle to find
    ///   - risingEdge: True for AOS (rising), false for LOS (falling)
    /// - Returns: The refined time of the elevation crossing
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    private func refineElevationCrossing(
        observer: Observer,
        t1: Date,
        t2: Date,
        targetElevation: Double,
        risingEdge: Bool
    ) throws -> Date {
        var left = t1
        var right = t2
        let tolerance: TimeInterval = 1.0 // 1 second accuracy
        
        while right.timeIntervalSince(left) > tolerance {
            let mid = left.addingTimeInterval(right.timeIntervalSince(left) / 2.0)
            let topo = try topocentric(at: mid, for: observer, applyRefraction: false)
            let midElevation = topo.elevationDeg
            
            if risingEdge {
                // For AOS, we want the time when elevation crosses upward
                if midElevation < targetElevation {
                    left = mid
                } else {
                    right = mid
                }
            } else {
                // For LOS, we want the time when elevation crosses downward
                if midElevation > targetElevation {
                    left = mid
                } else {
                    right = mid
                }
            }
        }
        
        return left.addingTimeInterval(right.timeIntervalSince(left) / 2.0)
    }
    
    /// Finds the maximum elevation within a pass using golden-section search.
    ///
    /// - Parameters:
    ///   - observer: The observer's location
    ///   - t1: Start of search interval (AOS time)
    ///   - t2: End of search interval (LOS time)
    /// - Returns: Tuple of (time, elevation, azimuth) at maximum
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    private func findMaxElevation(
        observer: Observer,
        t1: Date,
        t2: Date
    ) throws -> (time: Date, elevation: Double, azimuth: Double) {
        let phi = (1.0 + sqrt(5.0)) / 2.0 // Golden ratio
        let resphi = 2.0 - phi
        
        var a = t1
        var b = t2
        let tolerance: TimeInterval = 1.0 // 1 second accuracy
        
        // Initial probe points
        var c = a.addingTimeInterval(b.timeIntervalSince(a) * resphi)
        var d = a.addingTimeInterval(b.timeIntervalSince(a) * (1.0 - resphi))
        
        var topoC = try topocentric(at: c, for: observer, applyRefraction: false)
        var topoD = try topocentric(at: d, for: observer, applyRefraction: false)
        var fc = topoC.elevationDeg
        var fd = topoD.elevationDeg
        
        while b.timeIntervalSince(a) > tolerance {
            if fc > fd {
                b = d
                d = c
                fd = fc
                topoD = topoC
                c = a.addingTimeInterval(b.timeIntervalSince(a) * resphi)
                topoC = try topocentric(at: c, for: observer, applyRefraction: false)
                fc = topoC.elevationDeg
            } else {
                a = c
                c = d
                fc = fd
                topoC = topoD
                d = a.addingTimeInterval(b.timeIntervalSince(a) * (1.0 - resphi))
                topoD = try topocentric(at: d, for: observer, applyRefraction: false)
                fd = topoD.elevationDeg
            }
        }
        
        // Return the point with higher elevation
        if fc > fd {
            return (time: c, elevation: topoC.elevationDeg, azimuth: topoC.azimuthDeg)
        } else {
            return (time: d, elevation: topoD.elevationDeg, azimuth: topoD.azimuthDeg)
        }
    }
    
    /// Generates a ground track (latitude/longitude trace) for the satellite over time.
    ///
    /// This method calculates the satellite's sub-satellite point (the point on Earth's
    /// surface directly below the satellite) at regular intervals across a specified
    /// time window. The resulting array of points can be used for visualization,
    /// coverage analysis, or debugging orbital propagation.
    ///
    /// - Parameters:
    ///   - start: Start time for the ground track
    ///   - end: End time for the ground track
    ///   - stepSeconds: Time step between points in seconds (default: 60)
    /// - Returns: Array of GroundTrackPoint objects representing the satellite's path
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    ///
    /// ## Algorithm
    /// For each time step from start to end:
    /// 1. Calculate the satellite's position using orbital propagation
    /// 2. Extract latitude and longitude from the position
    /// 3. Store as a GroundTrackPoint
    ///
    /// ## Example
    /// ```swift
    /// let now = Date()
    /// let oneHourLater = now.addingTimeInterval(3600)
    /// let groundTrack = try orbit.groundTrack(
    ///     from: now,
    ///     to: oneHourLater,
    ///     stepSeconds: 60
    /// )
    ///
    /// // Visualize or export the ground track
    /// for point in groundTrack {
    ///     print("\(point.time): \(point.latitudeDeg)°, \(point.longitudeDeg)°")
    /// }
    /// ```
    ///
    /// ## Use Cases
    /// - Visualizing satellite coverage on a map
    /// - Planning ground station contacts
    /// - Educational demonstrations of orbital mechanics
    /// - Validating orbital propagation accuracy
    ///
    /// - Note: For high-precision applications, use smaller step sizes (e.g., 10-30 seconds).
    ///         For overview visualizations, larger steps (60-120 seconds) may be sufficient.
    public func groundTrack(from start: Date, to end: Date, stepSeconds: Double = 60) throws -> [GroundTrackPoint] {
        var points: [GroundTrackPoint] = []
        var currentTime = start
        
        while currentTime <= end {
            let position = try calculatePosition(at: currentTime)
            let point = GroundTrackPoint(
                time: currentTime,
                latitudeDeg: position.latitude,
                longitudeDeg: position.longitude
            )
            points.append(point)
            currentTime = currentTime.addingTimeInterval(stepSeconds)
        }
        
        return points
    }
    
    /// Generates a sky track (azimuth/elevation trace) for the satellite as seen from an observer.
    ///
    /// This method calculates the satellite's position in the observer's local horizontal
    /// coordinate system (azimuth and elevation) at regular intervals across a specified
    /// time window. The resulting array of points can be used for visualization, pass
    /// planning, or antenna pointing.
    ///
    /// - Parameters:
    ///   - observer: The observer's location on Earth
    ///   - start: Start time for the sky track
    ///   - end: End time for the sky track
    ///   - stepSeconds: Time step between points in seconds (default: 60)
    /// - Returns: Array of SkyTrackPoint objects representing the satellite's path across the sky
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    ///
    /// ## Algorithm
    /// For each time step from start to end:
    /// 1. Calculate topocentric coordinates for the satellite relative to the observer
    /// 2. Extract azimuth and elevation from the topocentric coordinates
    /// 3. Store as a SkyTrackPoint
    ///
    /// ## Example
    /// ```swift
    /// let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
    /// let now = Date()
    /// let oneHourLater = now.addingTimeInterval(3600)
    /// let skyTrack = try orbit.skyTrack(
    ///     for: observer,
    ///     from: now,
    ///     to: oneHourLater,
    ///     stepSeconds: 10
    /// )
    ///
    /// // Visualize or use for antenna pointing
    /// for point in skyTrack where point.elevationDeg > 0 {
    ///     print("\(point.time): Az \(point.azimuthDeg)°, El \(point.elevationDeg)°")
    /// }
    /// ```
    ///
    /// ## Use Cases
    /// - Visualizing satellite passes on a polar plot
    /// - Generating antenna pointing commands
    /// - Planning photography or observation sessions
    /// - Validating pass prediction accuracy
    ///
    /// - Note: For smooth pass visualizations, use smaller step sizes (5-30 seconds).
    ///         Points with negative elevation indicate the satellite is below the horizon.
    public func skyTrack(for observer: Observer, from start: Date, to end: Date, stepSeconds: Double = 60) throws -> [SkyTrackPoint] {
        var points: [SkyTrackPoint] = []
        var currentTime = start
        
        while currentTime <= end {
            let topo = try topocentric(at: currentTime, for: observer, applyRefraction: false)
            let point = SkyTrackPoint(
                time: currentTime,
                azimuthDeg: topo.azimuthDeg,
                elevationDeg: topo.elevationDeg
            )
            points.append(point)
            currentTime = currentTime.addingTimeInterval(stepSeconds)
        }
        
        return points
    }
}

// MARK: - Private Functions

extension Orbit {
    private func meanAnomalyForJulianDate(julianDate: Double) -> Double {
        let epochJulianDate = Date.julianDayFromEpoch(epochYear: twoLineElement.epochYear, epochDayFraction: twoLineElement.epochDay)
        let daysSinceEpoch = julianDate - epochJulianDate
        let revolutionsSinceEpoch = self.meanMotion * daysSinceEpoch
        let meanAnomalyForJulianDate = self.meanAnomaly + revolutionsSinceEpoch * PhysicalConstants.Angle.degreesPerCircle
        let fullRevolutions = floor(meanAnomalyForJulianDate / PhysicalConstants.Angle.degreesPerCircle)
        let adjustedMeanAnomalyForJulianDate = meanAnomalyForJulianDate - PhysicalConstants.Angle.degreesPerCircle * fullRevolutions
        
        return adjustedMeanAnomalyForJulianDate
    }
    
    /// Calculates the true anomaly from the mean anomaly.
    /// Uses eccentric anomaly as an intermediate calculation step.
    /// Returns the mean anomaly as a fallback if calculation fails (e.g., singularity).
    private func calculateTrueAnomalyFromMean() -> Degrees {
        // Calculate eccentric anomaly from mean anomaly
        let eccentricAnomaly = Orbit.calculateEccentricAnomaly(
            eccentricity: self.eccentricity,
            meanAnomaly: self.meanAnomaly
        )
        
        // Try to calculate true anomaly from eccentric anomaly
        do {
            let trueAnomaly = try Orbit.calculateTrueAnomaly(
                eccentricity: self.eccentricity,
                eccentricAnomaly: eccentricAnomaly
            )
            return trueAnomaly
        } catch {
            // If calculation fails (e.g., singularity when e >= 1),
            // return mean anomaly as a safe fallback
            return self.meanAnomaly
        }
    }
}

// MARK: - Static Functions

extension Orbit {
    /// Calculates the semi-major axis from mean motion.
    ///
    /// Uses Kepler's Third Law to derive the semi-major axis (the "size" of the orbit)
    /// from the satellite's mean motion. The semi-major axis is half the distance between
    /// perigee (closest point) and apogee (farthest point).
    ///
    /// - Parameter meanMotion: Mean motion in revolutions per day
    /// - Returns: Semi-major axis in kilometers
    ///
    /// ## Formula
    /// Based on Kepler's Third Law: `a³ = µ/(n²)`
    /// - `a` = semi-major axis
    /// - `µ` = Earth's gravitational constant (398600.4418 km³/s²)
    /// - `n` = mean motion in radians/second
    ///
    /// ## Example
    /// ```swift
    /// let meanMotion = 15.5 // revolutions per day
    /// let semiMajorAxis = Orbit.calculateSemimajorAxis(meanMotion: meanMotion)
    /// print("Semi-major axis: \(semiMajorAxis) km")
    /// ```
    static func calculateSemimajorAxis(meanMotion: Double) -> Double {
        let earthsGravitationalConstant = PhysicalConstants.Earth.µ // km^3/s^2
        // Convert mean motion from revolutions/day to radians/second
        // revolutions/day * (2π radians/revolution) * (1 day/86400 seconds)
        let motionRadsPerSecond = meanMotion * 2.0 * .pi / PhysicalConstants.Time.secondsPerDay
        let semimajorAxis = pow(earthsGravitationalConstant / pow(motionRadsPerSecond, 2.0), 1.0 / 3.0)
        return semimajorAxis // km
    }
    
    /// Calculates the eccentric anomaly using Newton-Raphson iteration.
    ///
    /// The eccentric anomaly is an intermediate angular parameter that bridges the gap
    /// between mean anomaly (time-based position) and true anomaly (actual position).
    /// This method uses an iterative numerical method to solve Kepler's equation.
    ///
    /// - Parameters:
    ///   - eccentricity: Orbital eccentricity (0 for circular, approaching 1 for highly elliptical)
    ///   - meanAnomaly: Mean anomaly in degrees
    ///   - accuracy: Convergence accuracy (default: 0.00001). Iteration stops when change is less than this value
    ///   - maxIterations: Maximum number of iterations to prevent infinite loops (default: 500)
    /// - Returns: Eccentric anomaly in degrees
    ///
    /// ## Algorithm
    /// Solves Kepler's equation: `E - e·sin(E) = M` using Newton-Raphson method
    ///
    /// ## Example
    /// ```swift
    /// let E = Orbit.calculateEccentricAnomaly(eccentricity: 0.0167, meanAnomaly: 45.0)
    /// ```
    ///
    /// - Note: Reference: https://www.sciencedirect.com/topics/engineering/eccentric-anomaly
    static func calculateEccentricAnomaly(eccentricity: Double, meanAnomaly: Degrees, accuracy: Double = PhysicalConstants.Calculation.defaultAccuracy, maxIterations: Int = PhysicalConstants.Calculation.maxIterations) -> Degrees {
        // Always convert degrees to radians before doing calculations
        let meanAnomaly: Radians = meanAnomaly.inRadians()
        var eccentricAnomaly: Radians = 0.0
        
        if meanAnomaly < .pi {
            eccentricAnomaly = meanAnomaly + eccentricity / 2
        } else {
            eccentricAnomaly = meanAnomaly - eccentricity / 2
        }
        
        var ratio = 1.0
        var iteration = 0
        
        repeat {
            let f = eccentricAnomaly - eccentricity * sin(eccentricAnomaly) - meanAnomaly
            let f2 = 1 - eccentricity * cos(eccentricAnomaly)
            ratio = f / f2
            eccentricAnomaly -= ratio
            iteration += 1
        } while (ratio > accuracy && iteration <= maxIterations)
        
        return eccentricAnomaly.inDegrees()
    }
    
    /// Calculates the true anomaly from the eccentric anomaly.
    ///
    /// The true anomaly is the actual angular position of the satellite in its orbit,
    /// measured from perigee (the closest point to Earth). This method converts from
    /// eccentric anomaly to true anomaly using the relationship between orbital geometry
    /// and eccentricity.
    ///
    /// - Parameters:
    ///   - eccentricity: Orbital eccentricity (must be < 1.0)
    ///   - eccentricAnomaly: Eccentric anomaly in degrees
    /// - Returns: True anomaly in degrees (0-360°)
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    ///
    /// ## Example
    /// ```swift
    /// let trueAnomaly = try Orbit.calculateTrueAnomaly(
    ///     eccentricity: 0.0167,
    ///     eccentricAnomaly: 45.0
    /// )
    /// ```
    ///
    /// - Note: Formula uses `atan2` for proper quadrant handling
    static func calculateTrueAnomaly(eccentricity: Double, eccentricAnomaly: Degrees) throws -> Degrees {
        if eccentricity >= 1 { throw CalculationError.reachedSingularity }
        let E = eccentricAnomaly.inRadians()
        let trueAnomaly = (2.0 * atan2(sqrt(1 + eccentricity) * sin(E), sqrt(1 - eccentricity) * cos(E))).inDegrees()
        return trueAnomaly
    }
}

/// Errors that can occur during orbital calculations.
public enum CalculationError: Int, Error {
    /// Indicates that a singularity was reached in the calculation, typically when eccentricity >= 1.0
    case reachedSingularity = 1
}

extension CalculationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reachedSingularity: return NSLocalizedString("Reached Singularity in calculation", comment: "reached singularity")
        }
    }
}
