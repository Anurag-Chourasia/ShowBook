#!/bin/bash
set -euo pipefail
simulator_id="$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(x["udid"] for k,v in d["devices"].items() if k.endswith("iOS-27-0") for x in v if x["name"]=="iPhone 18 Pro"))')"
simulator_state="$(xcrun simctl list devices -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(x["state"] for v in d["devices"].values() for x in v if x["udid"]==sys.argv[1]))' "$simulator_id")"
if [ "$simulator_state" != Booted ]; then xcrun simctl boot "$simulator_id"; fi
xcrun simctl bootstatus "$simulator_id" -b
xcodebuild -project ShowBook.xcodeproj -scheme ShowBook \
  -destination "platform=iOS Simulator,id=$simulator_id" -destination-timeout 120 \
  -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  -derivedDataPath "$1" -only-testing:ShowBookTests \
  -onlyUsePackageVersionsFromResolvedFile -disableAutomaticPackageResolution \
  -scmProvider system SDKROOT=iphonesimulator CODE_SIGNING_ALLOWED=NO test
