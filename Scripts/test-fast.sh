#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== [ShowBook] Fast Lane: Static Checks & Fast Unit Tests ==="
START_TIME=$(date +%s)

# Prevent CI from recording snapshot baselines
if [[ "${CI:-}" != "" && ( "${RECORD_SNAPSHOTS:-0}" == 1 || "${SNAPSHOT_RECORD:-0}" == 1 ) ]]; then
    echo "CI cannot record snapshots" >&2; exit 1
fi

# 1. Pinned checks, token audits, and flake quarantine
echo "--> Running pinned checks, token audits, and quarantine verification..."
python3 Scripts/verify_pins.py
python3 Scripts/check_design_tokens.py
python3 Scripts/test_dependencies.py
python3 Scripts/verify_flake_quarantine.py
python3 Scripts/verify-snapshot-baselines.py

# 2. Fast networking adapter tests
echo "--> Running deterministic networking adapter tests..."
python3 TestSupport/run-networking-tests.py

# 3. Fast unit tests on iOS Simulator
destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 11}"
result="${TEST_RESULT_PATH:-${RUNNER_TEMP:-/tmp}/ShowBookFast.xcresult}"
rm -rf "$result"

echo "--> Running fast unit tests on $destination..."
xcrun xcodebuild test -project ShowBook.xcodeproj -scheme ShowBook \
    -destination "$destination" \
    -parallel-testing-enabled NO \
    -derivedDataPath "${RUNNER_TEMP:-/tmp}/ShowBookDerived" \
    -resultBundlePath "$result" \
    -onlyUsePackageVersionsFromResolvedFile \
    -disableAutomaticPackageResolution \
    -scmProvider system CODE_SIGNING_ALLOWED=NO \
    -only-testing:ShowBookTests/BookItemViewModelTests \
    -only-testing:ShowBookTests/BookmarkSaveLifetimeTests \
    -only-testing:ShowBookTests/BookmarkButtonViewModelTests \
    -only-testing:ShowBookTests/TextFieldObserverTests \
    -only-testing:ShowBookTests/PrivacyManifestTests \
    -only-testing:ShowBookTests/LoginViewModelTests \
    -only-testing:ShowBookTests/CredentialStorageTests \
    -only-testing:ShowBookTests/SignUpViewModelTests \
    -only-testing:ShowBookTests/UserViewModelTests \
    -only-testing:ShowBookTests/IdentityActivationRecoveryTests \
    -only-testing:ShowBookTests/AuthenticationFlagTests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "=== [ShowBook] Fast Lane Succeeded in ${ELAPSED}s (Result: $result) ==="
