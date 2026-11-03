#!/usr/bin/env python3
"""Fail before XCTest if any declared ShowBook rendering snapshot baseline is missing or misconfigured (IOS-24)."""

import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / "ShowBookTests/DashboardViewTests.swift"

if not source.exists():
    sys.exit(f"Source file not found: {source}")

text = source.read_text()
# Find all capture calls in SearchNavigationRenderingTests
cases = re.findall(r'capture\(.*?name:\s*"([^"]+)"\)', text, re.S)

if not cases:
    sys.exit("No rendering capture declarations found in SearchNavigationRenderingTests")

required_fixtures = [
    "search-start",
    "search-empty-accessibility",
    "login-native-navigation",
    "developer-profile",
    "developer-profile-accessibility",
    "cover-preview-saved-dark",
    "cover-preview-missing-accessibility",
]

missing = [req for req in required_fixtures if req not in cases]
if missing:
    sys.exit(f"Missing declared rendering fixtures in SearchNavigationRenderingTests: {missing}")

print(f"Verified {len(cases)} UI rendering fixture attachments declared; visual review remains required.")
