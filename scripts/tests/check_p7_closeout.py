"""New closeout/roadmap coverage and read-only Git status capture; no Salesforce or prior tests."""
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'evidence/P7'


def git(*args):
    return subprocess.run(['git', *args], cwd=ROOT, text=True, capture_output=True, check=True).stdout.strip()


def main():
    phase7 = ROOT / 'docs/planning/PHASE7_FINAL_STATUS_2026-10-26.md'
    phase8 = ROOT / 'docs/planning/PHASE8_HANDOFF_2026-10-26.md'
    p7 = re.findall(r'^\| (P7-\d{2}) \|', phase7.read_text(), re.MULTILINE)
    p8 = re.findall(r'^\| (P8-\d{2}) \|', phase8.read_text(), re.MULTILINE)
    assert len(p7) == 23 and set(p7) == {'P7-' + str(i).zfill(2) for i in range(1, 24)}
    assert len(p8) == 11 and set(p8) == {'P8-' + str(i).zfill(2) for i in range(1, 12)}
    verification = json.loads((EVIDENCE / 'P7_FINAL_DEPLOYMENT_VERIFICATION.json').read_text())
    assert verification['status'] == 'PASS' and all(verification['unchangedComparisons'].values())
    assert verification['promptInactive'] and verification['promptVersionStatuses'] == ['Draft']
    assert verification['headerAndPageExist'] and not verification['pageActivatedOrAssigned']
    assert verification['newTestsRun'] == 0 and not verification['phase8Implemented']
    assert verification['territoryModelState'] == 'Planning'
    for path in [phase7, phase8, ROOT / 'evidence/P7/P7_FINAL_DEPLOYMENT.md']:
        assert all(line == line.rstrip() for line in path.read_text().splitlines()), path.name
    links = 0
    for path in [ROOT / 'README.md', ROOT / 'evidence/DEMO_SCRIPTS/README.md', phase7, phase8]:
        for link in re.findall(r'\[[^\]]*\]\(([^)]+)\)', path.read_text()):
            if link.startswith(('http://', 'https://', '#')):
                continue
            assert (path.parent / link.split('#')[0]).exists(), (path.name, link)
            links += 1
    assert 'not fully accepted' in phase7.read_text() and 'no Phase 8 code' in phase8.read_text()
    raw = subprocess.run(['git', 'status', '--porcelain=v1', '--untracked-files=all', '-z'],
                         cwd=ROOT, text=True, capture_output=True, check=True).stdout
    counts = {'trackedChanges': 0, 'trackedDeletions': 0, 'untrackedFiles': 0, 'stagedEntries': 0}
    rows = raw.split('\0')
    index = 0
    while index < len(rows):
        row = rows[index]
        index += 1
        if not row:
            continue
        status = row[:2]
        if status == '??':
            counts['untrackedFiles'] += 1
            continue
        counts['trackedChanges'] += 1
        counts['trackedDeletions'] += 'D' in status
        counts['stagedEntries'] += status[0] != ' '
        if 'R' in status or 'C' in status:
            index += 1
    head = git('rev-parse', 'HEAD')
    remote = subprocess.run(['git', 'ls-remote', 'origin', 'refs/heads/main'], cwd=ROOT,
                            text=True, capture_output=True, timeout=90)
    remote_head = remote.stdout.split()[0] if remote.returncode == 0 and remote.stdout.split() else None
    output = {'observedAtUtc': datetime.now(timezone.utc).isoformat(), 'branch': git('branch', '--show-current'),
              'head': head, 'upstream': git('rev-parse', '--abbrev-ref', '@{upstream}'),
              'cachedAheadBehind': git('rev-list', '--left-right', '--count', 'HEAD...origin/main').split(),
              'remoteName': 'origin', 'remoteMainQuery': 'git ls-remote origin refs/heads/main',
              'remoteQuerySucceeded': remote_head is not None, 'remoteMain': remote_head,
              'headMatchesLiveRemoteMain': remote_head == head if remote_head else None,
              **counts, 'cleanWorkingTree': not any(counts.values()),
              'fetchStageCommitPushPerformed': False}
    (EVIDENCE / 'P7_FINAL_GIT_STATUS.json').write_text(json.dumps(output, indent=2) + '\n')
    result = {'status': 'PASS', 'phase7BlocksCovered': len(p7), 'uniquePhase7Blocks': len(set(p7)),
              'phase8RequirementsCovered': len(p8), 'uniquePhase8Requirements': len(set(p8)),
              'deploymentVerification': 'PASS', 'newSalesforceCalls': 0, 'testsRerun': 0,
              'currentLocalLinksChecked': links,
              'phase8Implementation': False, 'git': output}
    (EVIDENCE / 'P7_FINAL_DOCUMENT_CHECK.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
