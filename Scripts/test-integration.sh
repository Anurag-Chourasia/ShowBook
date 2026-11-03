#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== [ShowBook] Integration Lane: Persistence Migrations & Catalog Services ==="
START_TIME=$(date +%s)

# Prevent CI from recording snapshot baselines
if [[ "${CI:-}" != "" && ( "${RECORD_SNAPSHOTS:-0}" == 1 || "${SNAPSHOT_RECORD:-0}" == 1 ) ]]; then
    echo "CI cannot record snapshots" >&2; exit 1
fi
python3 Scripts/verify-snapshot-baselines.py

destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 11,OS=27.0}"
result="${TEST_RESULT_PATH:-${RUNNER_TEMP:-/tmp}/ShowBookIntegration.xcresult}"
rm -rf "$result"

echo "--> Running integration tests on $destination..."
xcrun xcodebuild test -project ShowBook.xcodeproj -scheme ShowBook \
    -destination "$destination" \
    -parallel-testing-enabled NO \
    -derivedDataPath "${RUNNER_TEMP:-/tmp}/ShowBookDerived" \
    -resultBundlePath "$result" \
    -onlyUsePackageVersionsFromResolvedFile \
    -disableAutomaticPackageResolution \
    -scmProvider system CODE_SIGNING_ALLOWED=NO \
    -only-testing:ShowBookTests/BookmarkViewModelTests \
    -only-testing:ShowBookTests/PersistenceRelationshipTests \
    -only-testing:ShowBookTests/BookmarkUUIDMigrationTests \
    -only-testing:ShowBookTests/RiskBasedIsolationAndConcurrencyTests \
    -only-testing:ShowBookTests/DiscoverServiceTests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "=== [ShowBook] Integration Lane Succeeded in ${ELAPSED}s (Result: $result) ==="
