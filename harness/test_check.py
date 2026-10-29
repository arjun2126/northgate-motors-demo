"""Entry-point contract checks. Help/invalid modes only; no recursive validation or org calls."""
import os
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'harness/check.sh'


class EntryPointTests(unittest.TestCase):
    def invoke(self, *args):
        return subprocess.run(['/bin/bash', str(SCRIPT), *args], cwd=ROOT.parent,
                              env=dict(os.environ, SF_TARGET_ORG='ng-dev'),
                              text=True, capture_output=True, timeout=10)

    def test_help_is_offline_even_with_forbidden_default_org(self):
        result = self.invoke('--help')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('local only', result.stdout)
        self.assertNotIn('CHECK:', result.stdout)

    def test_unknown_or_extra_arguments_stop_before_checks(self):
        for args in [('deploy',), ('full', '--target-org', 'ng-dev'),
                     ('focused', 'ng-dev'), ('focused',), ('fast', 'extra'),
                     ('--help', 'extra'), ('focused', 'portal', '--run')]:
            with self.subTest(args=args):
                result = self.invoke(*args)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertNotIn('CHECK:', result.stdout)

    def test_no_external_write_or_salesforce_execution_path(self):
        text = SCRIPT.read_text()
        # Fixed command allowlist; no sf, npm/npx, Git or remote runner invocation.
        self.assertNotRegex(text, r'(?m)^\s*(?:exec\s+)?(?:sf|sfdx|git|npm|npx|curl)\s')
        self.assertNotIn('eval ', text)
        self.assertNotIn('shell=True', text)
        self.assertNotIn('scripts/test.sh', text)
        self.assertNotIn('scripts/verify.sh', text)
        self.assertIn('PYTHONDONTWRITEBYTECODE=1', text)


if __name__ == '__main__':
    unittest.main(verbosity=2)
