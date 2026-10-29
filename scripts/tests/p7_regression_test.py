"""Local command-order/fail-closed checks; no Salesforce invocation or fixtures."""
import json
from types import SimpleNamespace

from p7_regression import commands, execute, sanitized


def response(payload, code=0):
    return SimpleNamespace(returncode=code, stdout=json.dumps(payload), stderr='')


def main():
    selected = commands(3.0, 'evidence/storage.txt')
    assert selected[0][:3] == ['sf', 'data', 'query']
    for command in selected[1:3]:
        assert '--dry-run' in command and command[command.index('--target-org') + 1] == 'ng-demo'
        assert not any(flag in command for flag in ['--pre-destructive-changes', '--post-destructive-changes', '--ignore-errors', '--ignore-warnings'])
    assert selected[3][:2] == ['bash', 'scripts/verify.sh']
    assert '--tests' in selected[2] and 'QuotePricingServiceTest' in selected[2]
    passed = {'status': 0, 'result': {'status': 'Succeeded', 'checkOnly': True,
              'numberComponentErrors': 0, 'numberTestErrors': 0, 'numberTestsCompleted': 235, 'numberTestsTotal': 235}}
    values = [response({'status': 0, 'result': {'records': [{'Id': '00Daj00001Ae3iWEAR'}]}}),
              response(passed), response(passed), response({'passed': True})]
    calls = []
    def successful(command):
        calls.append(command)
        return values[len(calls) - 1]
    assert execute(selected, successful)['status'] == 'PASS' and calls == selected
    for failed in range(4):
        calls = []
        def failing(command):
            calls.append(command)
            return response({'passed': False}, 1) if len(calls) - 1 == failed else values[len(calls) - 1]
        result = execute(selected, failing)
        assert result['status'] == 'FAILED' and result['failedStep'] == failed + 1 and len(calls) == failed + 1
    assert execute(selected, lambda _: response({'status': 0, 'result': {'records': [{'Id': 'wrong'}]}}))['failedStep'] == 1
    assert execute(selected, lambda _: response({'status': 0, 'result': {'records': []}}))['failedStep'] == 1
    assert execute(selected, lambda _: response([]))['failedStep'] == 1
    assert execute(selected, lambda _: response({'status': 0, 'result': None}))['failedStep'] == 1
    for bad in [{'status': 'Succeeded', 'checkOnly': False}, {'status': 'InProgress', 'checkOnly': True}]:
        calls = []
        def invalid(command):
            calls.append(command)
            return values[0] if len(calls) == 1 else response({'status': 0, 'result': bad})
        assert execute(selected, invalid)['failedStep'] == 2 and len(calls) == 2
    calls = []
    def dq_false(command):
        calls.append(command)
        return values[len(calls) - 1] if len(calls) < 4 else response({'passed': False})
    assert execute(selected, dq_false)['failedStep'] == 4
    assert sanitized({'createdByName': 'private', 'accessToken': 'secret', 'status': 0}) == {'status': 0}
    print(json.dumps({'status': 'PASS', 'checks': ['safe explicit commands', 'ordered four-step gate',
          'fail-fast at each step', 'wrong-org denial', 'non-check-only/incomplete rejection',
          'DQ false remains failure', 'sensitive field removal'], 'salesforceCalls': 0, 'apexTestsRerun': 0}, indent=2))


if __name__ == '__main__':
    main()
