"""Regression coverage for the Release guard's localization-prefix collision."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

GUARD = Path(__file__).with_name('check_release_developer_ui.py')

class ReleaseGuardTests(unittest.TestCase):
    def test_shared_localization_keys_are_allowed(self):
        self.check(b'\0developer.source.stub\0developer.source.live\0', True)

    def test_debug_preference_keys_are_rejected(self):
        for marker in [b'developer.source', b'developer.httpLogs']:
            with self.subTest(marker=marker):
                self.check(b'\0' + marker + b'\0', False)

    def test_compiled_out_source_filename_is_allowed(self):
        self.check(b'DeveloperSettingsView.swift:$s8ShowBook13AppLaunchViewV', True)

    def test_debug_ui_types_are_rejected(self):
        self.check(b'_$s8ShowBook21DeveloperSettingsViewV', False)

    def test_copied_fixture_resource_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            app = Path(folder)
            executable = app / 'App'
            executable.write_bytes(b'clean executable')
            fixture = app / 'DeveloperFixtures'
            fixture.mkdir()
            (fixture / 'showbook-developer-responses.json').write_text('{}')
            result = subprocess.run([sys.executable, str(GUARD), str(executable)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)

    def check(self, content, allowed):
        with tempfile.TemporaryDirectory() as folder:
            executable = Path(folder) / 'App'
            executable.write_bytes(content)
            result = subprocess.run([sys.executable, str(GUARD), str(executable)], capture_output=True)
            self.assertEqual(result.returncode == 0, allowed, result.stdout + result.stderr)

if __name__ == '__main__':
    unittest.main()
