---
title: "Add async/await support for long-running calculations"
labels: ["enhancement", "modernization", "async-await"]
---

## Description

The Ephemeris framework performs orbital calculations that could potentially take time, especially when calculating positions for multiple satellites or time ranges. Adding async/await support would enable better integration with modern Swift applications and prevent blocking the main thread.

## Current Behavior

All calculations are synchronous:

```swift
// Blocks the calling thread
let orbit = Orbit(tle: tle)
let position = orbit.position(at: date)
```

**Impact:**
- Can block main thread in UI applications
- No cancellation support
- Difficult to parallelize multiple calculations
- Not compatible with Swift's modern concurrency model

## Expected Behavior

Provide async variants of computationally expensive methods:

```swift
// Async version
let orbit = try await Orbit(tle: tle)
let position = try await orbit.position(at: date)

// Can be cancelled with Task
let task = Task {
    try await orbit.calculateTrajectory(over: dateRange)
}
task.cancel()
```

## Use Cases

### 1. UI Applications

```swift
// Demo app - Calculate without blocking UI
Task {
    do {
        let position = try await orbit.position(at: Date())
        await MainActor.run {
            updateUI(with: position)
        }
    } catch {
        showError(error)
    }
}
```

### 2. Batch Processing

```swift
// Calculate positions for multiple satellites in parallel
await withTaskGroup(of: (String, Position).self) { group in
    for satellite in satellites {
        group.addTask {
            let position = try await satellite.orbit.position(at: date)
            return (satellite.name, position)
        }
    }
    
    for await result in group {
        positions[result.0] = result.1
    }
}
```

### 3. Real-time Tracking

```swift
// Update position every second
for await tick in Timer.publish(every: 1.0).values {
    let position = try await orbit.position(at: tick)
    updateMap(with: position)
}
```

## Proposed Solution

### Phase 1: Add Async Variants (Non-Breaking)

Keep existing synchronous methods, add async variants:

```swift
public struct Orbit {
    // Existing synchronous method (keep for compatibility)
    public func position(at date: Date) -> (x: Double, y: Double, z: Double) {
        calculatePositionSync(date)
    }
    
    // New async method
    public func position(at date: Date) async -> (x: Double, y: Double, z: Double) {
        await Task {
            calculatePositionSync(date)
        }.value
    }
    
    // Async with throws
    public func position(at date: Date) async throws -> (x: Double, y: Double, z: Double) {
        try await Task {
            try calculatePosition(date)
        }.value
    }
}
```

### Phase 2: Add Cancellation Support

```swift
public struct Orbit {
    /// Calculate position with cancellation support
    public func position(at date: Date) async throws -> (x: Double, y: Double, z: Double) {
        try Task.checkCancellation()
        
        let meanAnomaly = await calculateMeanAnomaly(at: date)
        try Task.checkCancellation()
        
        let trueAnomaly = await calculateTrueAnomaly(from: meanAnomaly)
        try Task.checkCancellation()
        
        return await calculateCartesian(from: trueAnomaly)
    }
}
```

### Phase 3: AsyncSequence for Trajectories

```swift
public struct Orbit {
    /// Calculate positions over a time range
    public func trajectory(
        from start: Date,
        to end: Date,
        interval: TimeInterval
    ) -> AsyncStream<(date: Date, position: (x: Double, y: Double, z: Double))> {
        AsyncStream { continuation in
            Task {
                var current = start
                while current <= end {
                    try Task.checkCancellation()
                    
                    let position = await self.position(at: current)
                    continuation.yield((current, position))
                    
                    current = current.addingTimeInterval(interval)
                }
                continuation.finish()
            }
        }
    }
}
```

## Actor-Based API (Advanced)

For more complex scenarios:

```swift
@globalActor
public actor OrbitCalculator {
    public static let shared = OrbitCalculator()
    
    private var cache: [String: Orbit] = [:]
    
    public func orbit(for tle: TwoLineElement) async throws -> Orbit {
        let key = tle.catalogNumber.description
        
        if let cached = cache[key] {
            return cached
        }
        
        let orbit = try Orbit(tle: tle)
        cache[key] = orbit
        return orbit
    }
}

// Usage
let orbit = try await OrbitCalculator.shared.orbit(for: tle)
```

## Performance Considerations

### When to Use Async

Use async for:
- ✅ Batch calculations (many positions)
- ✅ Long time ranges (trajectories)
- ✅ Multiple satellites in parallel
- ✅ UI-driven calculations

Don't bother for:
- ❌ Single position calculation (~1ms)
- ❌ Simple property access
- ❌ Non-blocking operations

### Benchmarking

```swift
func testSyncVsAsync() async {
    let orbit = Orbit(...)
    
    // Sync
    measure {
        _ = orbit.position(at: Date())
    }
    
    // Async overhead
    await measure {
        _ = await orbit.position(at: Date())
    }
}
```

## Migration Strategy

### Non-Breaking Addition

```swift
extension Orbit {
    // New async API alongside existing sync API
    @available(iOS 15.0, macOS 12.0, *)
    public func position(at date: Date) async throws -> (x: Double, y: Double, z: Double) {
        // Implementation
    }
}
```

### Documentation

```swift
/// Calculate satellite position (synchronous).
///
/// For non-blocking calculation in UI applications, use the async variant:
/// ```swift
/// let position = try await orbit.position(at: date)
/// ```
///
/// - SeeAlso: `position(at:) async throws`
public func position(at date: Date) -> (x: Double, y: Double, z: Double) {
    // Implementation
}
```

## Testing Async Code

```swift
class OrbitAsyncTests: XCTestCase {
    func testAsyncPositionCalculation() async throws {
        let orbit = Orbit(...)
        let position = try await orbit.position(at: Date())
        
        XCTAssertGreaterThan(position.x, 0)
    }
    
    func testCancellation() async throws {
        let orbit = Orbit(...)
        
        let task = Task {
            try await orbit.trajectory(
                from: Date(),
                to: Date().addingTimeInterval(3600),
                interval: 1.0
            )
        }
        
        // Cancel after a short time
        try await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()
        
        // Verify task was cancelled
        let result = await task.result
        switch result {
        case .failure(let error):
            XCTAssert(error is CancellationError)
        case .success:
            XCTFail("Task should have been cancelled")
        }
    }
}
```

## Additional Context

- Priority: **Low** - Modernization, not critical
- Effort: **4-6 hours** for basic async support
- Requirement: iOS 15.0+, macOS 12.0+
- Related to: Modern Swift features
- **Note:** Calculations are typically fast (~1ms), so benefit is mainly for batch operations

## Benefits

1. **Main Thread:** Prevent blocking UI
2. **Cancellation:** Can cancel long-running tasks
3. **Parallelization:** Easy parallel calculations
4. **Modern API:** Matches Swift evolution
5. **Integration:** Better SwiftUI/UIKit integration

## Acceptance Criteria

- [ ] Async variants added for computationally expensive methods
- [ ] Synchronous methods kept for backward compatibility
- [ ] Cancellation support implemented
- [ ] AsyncSequence for trajectory calculations
- [ ] Tests added for async code paths
- [ ] Tests verify cancellation works
- [ ] Documentation explains when to use async
- [ ] Performance benchmarks show overhead is acceptable
- [ ] Minimum OS versions documented
- [ ] Example usage in demo app
