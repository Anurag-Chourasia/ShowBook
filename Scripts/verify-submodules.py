#!/usr/bin/env python3
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
status = subprocess.check_output(["git", "submodule", "status", "--recursive"], cwd=root, text=True)
assert status.strip(), "Submodules are missing"
assert all(line.startswith(" ") for line in status.splitlines()), "Initialize submodules at the pinned commits; modified/missing checkouts are not allowed"

for kit in ["AppStubData"]:
    submodule_path = root / "Submodules" / kit
    assert (submodule_path / "Package.swift").is_file(), "Missing " + kit
    dirty = subprocess.check_output(["git", "status", "--porcelain"], cwd=submodule_path, text=True)
    assert not dirty, "Uncommitted changes in " + kit

print("All submodules match their pinned commits")
