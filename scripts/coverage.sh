#!/bin/bash

# Code Coverage Report Generator for Ephemeris
# This script generates code coverage reports for local development

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Ephemeris Code Coverage Report Generator ===${NC}\n"

# Clean previous coverage data
echo -e "${YELLOW}Cleaning previous coverage data...${NC}"
rm -rf .build/debug/codecov
rm -rf coverage
mkdir -p coverage

# Run tests with coverage enabled
echo -e "${BLUE}Running tests with code coverage enabled...${NC}"
swift test --enable-code-coverage

# Find the test binary and profdata file
echo -e "${YELLOW}Locating coverage data...${NC}"

# The test binary location (use ls -d instead of find for macOS bundles)
TEST_BINARY=$(ls -d .build/debug/*.xctest 2>/dev/null | head -1)

if [ -z "$TEST_BINARY" ]; then
    echo -e "${RED}Error: Could not find test binary${NC}"
    echo "Expected to find *.xctest bundle in .build/debug/"
    exit 1
fi

# Find the actual executable inside the test bundle
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - test binary is in Contents/MacOS/
    TEST_EXECUTABLE="$TEST_BINARY/Contents/MacOS/EphemerisPackageTests"
else
    # Linux
    TEST_EXECUTABLE="$TEST_BINARY"
fi

if [ ! -f "$TEST_EXECUTABLE" ]; then
    echo -e "${RED}Error: Test executable not found at $TEST_EXECUTABLE${NC}"
    exit 1
fi

# Find the profdata file
PROFDATA=$(find .build/debug/codecov -name "*.profdata" 2>/dev/null | head -1)

if [ -z "$PROFDATA" ]; then
    echo -e "${RED}Error: Could not find .profdata file${NC}"
    echo "Expected to find .profdata in .build/debug/codecov/"
    exit 1
fi

echo -e "${GREEN}Found test binary: $TEST_EXECUTABLE${NC}"
echo -e "${GREEN}Found profdata: $PROFDATA${NC}\n"

# Generate text coverage report
echo -e "${BLUE}Generating coverage summary...${NC}"
xcrun llvm-cov report \
    "$TEST_EXECUTABLE" \
    -instr-profile="$PROFDATA" \
    -ignore-filename-regex='Tests/' \
    -use-color

# Generate HTML coverage report
echo -e "\n${BLUE}Generating HTML coverage report...${NC}"
xcrun llvm-cov show \
    "$TEST_EXECUTABLE" \
    -instr-profile="$PROFDATA" \
    -ignore-filename-regex='Tests/' \
    -format=html \
    -output-dir=coverage \
    -Xdemangler c++filt

# Success message
echo -e "\n${GREEN}✓ Coverage report generated successfully!${NC}"
echo -e "${BLUE}View the report at: ${NC}coverage/index.html"
echo -e "${BLUE}Open it with: ${NC}open coverage/index.html\n"
