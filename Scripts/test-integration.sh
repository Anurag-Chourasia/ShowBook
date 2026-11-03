#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== [ShowBook] Integration Lane: Persistence Migrations & Catalog Services ==="
START_TIME=$(date +%s)

destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 11}"
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
    -only-testing:ShowBookTests/DiscoverServiceTests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "=== [ShowBook] Integration Lane Succeeded in ${ELAPSED}s (Result: $result) ==="
