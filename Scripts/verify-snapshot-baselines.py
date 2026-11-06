#!/usr/bin/env python3
"""Verify reviewed ShowBook PNG references before running visual comparisons."""
import struct
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "ShowBookTests/__Snapshots__"
scenes = ("search-start", "search-empty", "login-native-navigation", "developer-profile",
          "cover-preview-saved", "cover-preview-missing", "book-details", "developer-launch",
          "discover-list", "discover-grid")
paths = [root / "iOS-27.0" / f"{scene}-{variant}.png" for scene in scenes
         for variant in ("light", "dark", "accessibility")]
cards = ("accessible-list-dark", "accessible-phone-list-dark", "phone-grid-light",
         "phone-list-light", "tablet-grid-dark")
paths += [root / "BookItemViewModelTests" /
          f"testListGridAndAccessibleCardsRenderInBothAppearances.{card}.png" for card in cards]
for path in paths:
    if not path.is_file():
        raise SystemExit(f"Missing reviewed reference: {path}")
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n" or len(data) < 24:
        raise SystemExit(f"Invalid PNG reference: {path}")
    width, height = struct.unpack(">II", data[16:24])
    if "iOS-27.0" in str(path) and (width, height) != (414, 896):
        raise SystemExit(f"Unexpected snapshot dimensions: {path}: {width}x{height}")
print(f"Verified {len(paths)} reviewed PNG references; XCTest must compare their pixels.")
