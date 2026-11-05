"""Reject Release-only leaks without matching longer shared localization keys."""
from pathlib import Path
import re
import sys

binary = Path(sys.argv[1]).read_bytes()
# Preference keys are complete tokens. Localization keys such as
# developer.source.stub belong to the shared string API and are valid in Release.
for marker in [b'Developer settings', b'developer.source', b'developer.httpLogs', b'Demo: A journey through books']:
    pattern = re.escape(marker) + rb'(?![A-Za-z0-9_.])'
    if re.search(pattern, binary):
        raise SystemExit(f'Debug-only marker in Release: {marker.decode()}')
for marker in [b'DeveloperSettingsView', b'DeveloperStubProtocol']:
    if marker in binary:
        raise SystemExit(f'Debug-only type in Release: {marker.decode()}')
print('Release executable excludes developer UI, fixtures and preference keys.')
