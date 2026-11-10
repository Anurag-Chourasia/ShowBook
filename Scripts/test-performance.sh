#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== [ShowBook] Performance Lane: Throughput & Latency Baselines ==="
START_TIME=$(date +%s)

destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 11,OS=27.0}"
result="${TEST_RESULT_PATH:-${RUNNER_TEMP:-/tmp}/ShowBookPerformance.xcresult}"
rm -rf "$result"

echo "--> Running performance benchmarks on $destination..."
xcrun xcodebuild test -project ShowBook.xcodeproj -scheme ShowBook \
    -destination "$destination" \
    -parallel-testing-enabled NO \
    -derivedDataPath "${RUNNER_TEMP:-/tmp}/ShowBookDerived" \
    -resultBundlePath "$result" \
    -onlyUsePackageVersionsFromResolvedFile \
    -disableAutomaticPackageResolution \
    -scmProvider system CODE_SIGNING_ALLOWED=NO \
    -only-testing:ShowBookTests/PerformanceTests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "=== [ShowBook] Performance Lane Succeeded in ${ELAPSED}s (Result: $result) ==="
