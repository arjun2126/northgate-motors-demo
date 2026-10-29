"""Offline synthetic concurrent-worktree contracts; no application writes or Git mutations."""
import copy
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('preservation', Path(__file__).with_name('preservation.py'))
m = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(m)


def file(sha='a', identity=None):
    return {'kind': 'file', 'sha256': sha, **({'identity': identity} if identity else {})}


class PreservationTests(unittest.TestCase):
    def state(self):
        return {'files': {'harness/check.sh': file(), 'portal.html': file(), 'receipt.json': file()},
                'required': ['receipt.json'], 'presence': {'inventory.cls': True}}

    def test_unchanged_dirty_baseline_passes(self):
        before = self.state()
        self.assertEqual(m.compare(before, copy.deepcopy(before))['status'], 'PASS')

    def test_unrelated_add_change_delete_are_info_unknown(self):
        before = self.state()
        after = copy.deepcopy(before)
        after['files']['portal.html'] = file('b')
        after['files']['REGRESSION_CLOSURE/new.json'] = file('new')
        before['files']['removed.txt'] = file()
        result = m.compare(before, after)
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(len(result['informationalChanges']), 3)
        self.assertTrue(all(row['attribution'] == 'unknown' for row in result['informationalChanges']))

    def test_harness_conflict_fails(self):
        before = self.state()
        after = copy.deepcopy(before)
        after['files']['harness/check.sh'] = file('other')
        self.assertEqual(m.compare(before, after)['status'], 'FAIL')

    def test_new_undeclared_harness_file_fails(self):
        before = self.state()
        after = copy.deepcopy(before)
        after['files']['harness/unreviewed.py'] = file()
        self.assertEqual(m.compare(before, after)['status'], 'FAIL')

    def test_exact_intended_owned_change_passes(self):
        before = self.state()
        after = copy.deepcopy(before)
        after['files']['harness/check.sh'] = file('reviewed')
        result = m.compare(before, after, {'harness/check.sh': 'reviewed'})
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(result['acceptedHarnessEdits'], ['harness/check.sh'])

    def test_intended_hash_mismatch_fails(self):
        state = self.state()
        self.assertEqual(m.compare(state, state, {'harness/check.sh': 'different'})['status'], 'FAIL')

    def test_cannot_allowlist_application_edit(self):
        state = self.state()
        self.assertEqual(m.compare(state, state, {'portal.html': 'a'})['status'], 'FAIL')

    def test_required_input_change_invalidates_result(self):
        before = self.state()
        after = copy.deepcopy(before)
        after['files']['receipt.json'] = file('changed')
        result = m.compare(before, after)
        self.assertEqual(result['status'], 'FAIL')
        self.assertEqual(result['conflicts'][0]['path'], 'receipt.json')

    def test_missing_input_fails_even_if_already_missing(self):
        state = self.state()
        state['files']['receipt.json'] = {'kind': 'missing'}
        self.assertEqual(m.compare(state, state)['status'], 'FAIL')

    def test_presence_only_content_change_is_not_false_failure(self):
        before = self.state()
        before['files']['inventory.cls'] = file()
        after = copy.deepcopy(before)
        after['files']['inventory.cls'] = file('b')
        self.assertEqual(m.compare(before, after)['status'], 'PASS')
        after['presence']['inventory.cls'] = False
        self.assertEqual(m.compare(before, after)['status'], 'FAIL')

    def test_rewrite_restoring_same_bytes_still_invalidates_interval(self):
        before = self.state()
        after = copy.deepcopy(before)
        before['files']['receipt.json']['identity'] = [1, 1, 1]
        after['files']['receipt.json']['identity'] = [2, 2, 1]
        self.assertEqual(m.compare(before, after)['status'], 'FAIL')

    def test_unstable_read_or_symlink_not_accepted_as_required_input(self):
        for value in [dict(file(), unstable=True), {'kind': 'symlink'}, {'kind': 'unreadable'}]:
            with self.subTest(value=value):
                state = self.state()
                state['files']['receipt.json'] = value
                self.assertEqual(m.compare(state, state)['status'], 'FAIL')

    def test_ignored_required_input_is_captured_without_git_mutations(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / 'ignored.txt').write_text('required')
            with patch.object(m, 'inventory', return_value=set()):
                state = m.snapshot(root, ['ignored.txt'])
            self.assertEqual(state['files']['ignored.txt']['sha256'], m.hashlib.sha256(b'required').hexdigest())

    def test_mode_inputs_do_not_freeze_unselected_portal_sources(self):
        root = Path(__file__).resolve().parents[1]
        fast, _ = m.inputs(root, 'focused', 'harness')
        portal, _ = m.inputs(root, 'focused', 'portal')
        name = 'force-app/main/default/lwc/ownerPortalHome/ownerPortalHome.html'
        self.assertNotIn(name, fast)
        self.assertIn(name, portal)
        self.assertIn(m.BASE + 'raw/apex-test-run.json', fast)
        self.assertIn('scripts/tests/validate_p7_batch2.py', fast)


if __name__ == '__main__':
    unittest.main(verbosity=2)
