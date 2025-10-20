# Security Policy

## Supported Versions

The following versions of Ephemeris are currently supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue in Ephemeris, please report it responsibly.

### How to Report

**Please do NOT open a public issue for security vulnerabilities.**

Instead, please report security vulnerabilities by:

1. **Email**: Send details to the project maintainer (see GitHub profile)
2. **GitHub Security Advisories**: Use the [Security Advisories](https://github.com/mvdmakesthings/Ephemeris/security/advisories) feature

### What to Include

When reporting a vulnerability, please include:

- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact
- Suggested fix (if you have one)
- Your contact information

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 1 week
- **Fix Timeline**: Depends on severity
  - Critical: Within 1 week
  - High: Within 2 weeks
  - Medium: Within 1 month
  - Low: Next release cycle

### Security Update Process

1. Vulnerability reported and confirmed
2. Fix developed and tested
3. Security advisory published
4. Patch released
5. Users notified

## Security Considerations

### TLE Data Input

- Ephemeris parses Two-Line Element (TLE) data from external sources
- Always validate TLE data from untrusted sources
- Be aware that malformed TLE data could cause parsing errors

### Best Practices for Users

1. **Validate Input**: Always validate TLE data before parsing
2. **Error Handling**: Implement proper error handling when using Ephemeris
3. **Keep Updated**: Use the latest version of Ephemeris for security fixes
4. **Dependencies**: Monitor for dependency updates (though currently Ephemeris has no external dependencies)

### Known Limitations

- TLE date parsing uses a windowing approach for 2-digit years (±50 years from current date)
- Calculations assume standard Earth parameters and may not be suitable for all use cases
- Input validation is the responsibility of the calling code

## Security Features

- **No External Dependencies**: Ephemeris has zero external dependencies, reducing supply chain risk
- **Pure Swift**: Written entirely in Swift with no unsafe code
- **Type Safety**: Leverages Swift's type system for safety
- **Error Handling**: Uses Swift error handling for robust operation

## Disclosure Policy

- Security vulnerabilities will be disclosed after a fix is available
- Credit will be given to reporters (unless they prefer to remain anonymous)
- A security advisory will be published for significant vulnerabilities

## Contact

For security-related questions or concerns, please contact the project maintainer through GitHub.

---

Thank you for helping keep Ephemeris secure! 🔒
