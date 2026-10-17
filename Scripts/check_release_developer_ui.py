"""Fail if the Release executable contains debug-only UI or preference identifiers."""
from pathlib import Path
import sys
binary = Path(sys.argv[1]).read_bytes()
for marker in [b'Developer settings', b'developer.source', b'developer.httpLogs', b'Demo: A journey through books']:
    if marker in binary:
        raise SystemExit(f'Debug-only marker in Release: {marker.decode()}')
print('Release executable excludes developer UI, fixtures and preference keys.')
