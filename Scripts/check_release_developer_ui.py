"""Reject Release-only leaks without matching longer shared localization keys."""
from pathlib import Path
import re
import sys

executable = Path(sys.argv[1])
if list(executable.parent.rglob('showbook-developer-responses.json')) or (executable.parent / 'DeveloperFixtures').exists():
    raise SystemExit('Debug fixture resources found in Release app')
binary = executable.read_bytes()
# Preference keys are complete tokens. Localization keys such as
# developer.source.stub belong to the shared string API and are valid in Release.
for marker in [b'Developer settings', b'developer.source', b'developer.httpLogs', b'Demo: A journey through books']:
    pattern = re.escape(marker) + rb'(?![A-Za-z0-9_.])'
    if re.search(pattern, binary):
        raise SystemExit(f'Debug-only marker in Release: {marker.decode()}')
for marker in [b'DeveloperSettingsView', b'DeveloperStubProtocol']:
    # Coverage metadata can retain the source filename after #if DEBUG exclusion.
    # Match the actual Swift type symbol, not a filename substring.
    if re.search(rb'\$s8ShowBook[0-9]+' + marker + rb'[VC]', binary):
        raise SystemExit(f'Debug-only type in Release: {marker.decode()}')
print('Release executable excludes developer UI, fixtures and preference keys.')
