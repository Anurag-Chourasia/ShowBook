#!/bin/sh
set -eu
fixture_directory="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/DeveloperFixtures"
if [ "$CONFIGURATION" = "Debug" ]; then
    mkdir -p "$fixture_directory"
    cp "$SRCROOT/Submodules/AppStubData/Sources/AppStubData/Resources/showbook-developer-responses.json" "$fixture_directory/showbook-developer-responses.json"
else
    rm -rf "$fixture_directory"
fi
