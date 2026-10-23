"""Run the complete hook with synthetic environment values and command stubs."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SECRET = "synthetic secret $literal"
STUB = r'''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import sys

command = Path(sys.argv[0]).name
args = sys.argv[1:]
if command == "id":
    print(os.environ["PROVISION_TEST_UID"])
elif command == "su":
    assert args[:5] == ["-p", "-s", "/bin/sh", "www-data", "-c"], args
    shell_args = args[6:]
    if shell_args[:1] == ["--"]:
        shell_args = shell_args[1:]
    sys.exit(subprocess.run(["/bin/sh", "-c", args[5]] + shell_args).returncode)
elif command == "php":
    with open(os.environ["PROVISION_TEST_CALLS"], "a") as log:
        log.write(json.dumps(args) + "\n")
    if os.environ.get("PROVISION_TEST_FAIL") == "1":
        print("synthetic occ failure", file=sys.stderr)
        sys.exit(1)
else:
    raise SystemExit("Unexpected command: " + command)
'''


class ProvisionTest(unittest.TestCase):
    def run_hook(self, uid, fail=False):
        with tempfile.TemporaryDirectory(prefix="blue3-provision-test-") as directory:
            root = Path(directory)
            allowlist = root / "apps.allowlist"
            allowlist.write_text("[enable]\ncalendar\n[disable]\nrecommendations\n")
            source = (ROOT / "build/provision.sh").read_text()
            self.assertEqual(1, source.count('ALLOWLIST="/usr/src/blue3/apps.allowlist"'))
            hook = root / "provision.sh"
            hook.write_text(source.replace("/usr/src/blue3/apps.allowlist", str(allowlist)))
            commands = root / "bin"
            commands.mkdir()
            for name in ("id", "su", "php"):
                path = commands / name
                path.write_text(STUB)
                path.chmod(0o755)
            calls = root / "calls.jsonl"
            env = dict(
                os.environ,
                PATH=str(commands) + os.pathsep + os.environ["PATH"],
                PROVISION_TEST_UID=str(uid),
                PROVISION_TEST_CALLS=str(calls),
                PROVISION_TEST_FAIL="1" if fail else "0",
                NEXTCLOUD_ADMIN_USER="admin example",
                WHITEBOARD_JWT_SECRET=SECRET,
                WHITEBOARD_PUBLIC_URL="https://whiteboard.example.test",
            )
            result = subprocess.run(
                ["/bin/sh", str(hook)], env=env, capture_output=True, text=True, timeout=10
            )
            recorded = [json.loads(line) for line in calls.read_text().splitlines()]
            return result, recorded

    def test_occ_receives_complete_values_in_both_user_paths(self):
        expected = (
            ["app:enable", "calendar"],
            ["app:disable", "recommendations"],
            ["theming:config", "name", "Blue3 Drive"],
            ["theming:config", "slogan", "Um local seguro para seus dados!"],
            ["theming:config", "primary_color", "#29ABE2"],
            ["theming:config", "background_color", "#000c18"],
            ["user:setting", "admin example", "core", "lang", "pt_BR"],
            ["user:setting", "admin example", "core", "locale", "pt_BR"],
            ["config:app:set", "whiteboard", "jwt_secret_key", "--value=" + SECRET],
        )
        for uid in (0, 1000):
            with self.subTest(uid=uid):
                result, calls = self.run_hook(uid)
                self.assertEqual(0, result.returncode, result.stderr)
                for args in expected:
                    self.assertIn(["/var/www/html/occ"] + args, calls)

    def test_failed_occ_keeps_boot_running_without_logging_values(self):
        for uid in (0, 1000):
            with self.subTest(uid=uid):
                result, calls = self.run_hook(uid, fail=True)
                self.assertEqual(0, result.returncode, result.stderr)
                self.assertGreater(len(calls), 10)
                self.assertIn("WARN", result.stdout)
                self.assertNotIn(SECRET, result.stdout + result.stderr)
                self.assertNotIn("--value=", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
