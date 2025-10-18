---
title: "Fix typo: 'perpandicular' should be 'perpendicular'"
labels: ["documentation", "typo", "good-first-issue"]
---

## Description

The word "perpendicular" is misspelled as "perpandicular" in documentation comments across multiple files.

## Affected Locations

1. **Orbit.swift** line 27:
```swift
/// The "tilt" in degrees from the vectors perpandicular to the orbital and equatorial planes
```

2. **Orbitable.swift** line 23:
```swift
/// The "tilt" in degrees from the vectors perpandicular to the orbital and equatorial planes
```

## Correction

Change:
```swift
/// The "tilt" in degrees from the vectors perpandicular to the orbital and equatorial planes
```

To:
```swift
/// The "tilt" in degrees from the vectors perpendicular to the orbital and equatorial planes
```

## Impact

- **Documentation Quality:** Typo in public API documentation
- **Professionalism:** Spelling error visible to all users
- **Consistency:** Same typo in multiple locations

## Priority

**Low** - Documentation typo only, no functional impact

## Acceptance Criteria

- [ ] "perpandicular" changed to "perpendicular" in Orbit.swift
- [ ] "perpandicular" changed to "perpendicular" in Orbitable.swift
- [ ] Verified no other instances of this typo in codebase
- [ ] Code still compiles and tests pass

## Implementation

This is a simple find-and-replace:

```bash
# Search for the typo
grep -r "perpandicular" Ephemeris/

# Replace in files
sed -i '' 's/perpandicular/perpendicular/g' Ephemeris/Orbit.swift
sed -i '' 's/perpandicular/perpendicular/g' Ephemeris/Orbitable.swift
```

Or manually edit the two files.

## Good First Issue

This is an excellent first contribution for new contributors:
- Simple change
- Clear solution
- Low risk
- Good introduction to contribution process
