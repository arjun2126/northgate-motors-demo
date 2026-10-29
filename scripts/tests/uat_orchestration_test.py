"""Offline harness checks; no Salesforce calls or browser actions."""
import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace
import unittest

SPEC = importlib.util.spec_from_file_location('orchestrate', Path(__file__).resolve().parents[1] / 'uat/orchestrate.py')
m = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(m)


def reply(records, code=0):
    return SimpleNamespace(returncode=code, stderr='', stdout=json.dumps(
        {'status': code, 'result': {'records': records, 'done': True}}))


class HarnessTests(unittest.TestCase):
    def test_reuse_has_no_commands(self):
        self.assertEqual(m.plan('reuse'), [])

    def test_fixed_readonly_allowlist(self):
        for command in m.plan('live-readonly'):
            self.assertEqual(command[:3], ['sf', 'data', 'query'])
            self.assertEqual(command[command.index('--target-org') + 1], 'ng-demo')
            self.assertTrue(command[command.index('--query') + 1].startswith('SELECT '))

    def test_ui_reuses_seven_existing_suites(self):
        command = m.plan('local-ui')[0]
        self.assertEqual(command[:2], ['node', '--test'])
        self.assertEqual(len(command[2:]), 7)
        self.assertTrue(all((m.ROOT / name).is_file() for name in command[2:]))

    def test_wrong_org_stops_before_inventory(self):
        calls = []
        def runner(command):
            calls.append(command)
            return reply([{'Id': 'wrong'}])
        self.assertEqual(m.execute_batch('live-readonly', runner)['status'], 'FAIL')
        self.assertEqual(len(calls), 1)

    def test_command_error_stops_without_retry(self):
        calls = []
        def runner(command):
            calls.append(command)
            return reply([], 1)
        self.assertEqual(m.execute_batch('live-readonly', runner)['status'], 'BLOCKED')
        self.assertEqual(len(calls), 1)

    def test_malformed_json_blocked(self):
        self.assertEqual(m.execute_batch('live-readonly', lambda _: SimpleNamespace(
            returncode=0, stdout='not json', stderr=''))['status'], 'BLOCKED')

    def test_inventory_success_has_narrow_scope(self):
        values = iter([reply([{'Id': m.ORG_ID}]), reply([{'Id': '0DBaj000006bf3xGAA', 'Status': 'Live'}])])
        self.assertEqual(m.execute_batch('live-readonly', lambda _: next(values))['status'], 'PASS')

    def test_ui_missing_tap_is_not_pass(self):
        self.assertEqual(m.execute_batch('local-ui', lambda _: SimpleNamespace(
            returncode=0, stdout='', stderr=''))['status'], 'BLOCKED')

    def test_ui_pass_is_mock_only(self):
        result = m.execute_batch('local-ui', lambda _: SimpleNamespace(
            returncode=0, stdout='# fail 0\n', stderr=''))
        self.assertEqual(result['scope'], 'Mocked local UI/state only')

    def test_publish_outside_evidence_refused(self):
        with self.assertRaises(ValueError):
            m.publish(m.ROOT, Path('scripts'))

    def test_all_phases_preserve_checklist_text(self):
        text = (m.ROOT / m.REGISTER).read_text()
        rows = m.coverage(text)
        self.assertGreater(len(rows), 80)
        self.assertTrue(all(row['feature'] in text and row['remainingAcceptance'] in text for row in rows))

    def test_prior_failure_is_not_upgraded(self):
        result = m.reuse(m.ROOT)
        self.assertEqual(result['historicalUatStatus'], 'FAIL')
        self.assertEqual(result['historicalApex']['failing'], 10)


if __name__ == '__main__':
    unittest.main(verbosity=2)
