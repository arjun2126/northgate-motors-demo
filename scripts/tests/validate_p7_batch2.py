"""Run the fixed Batch 2 check-only scope and affected Apex regression tests; never deploy."""
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TESTS = [
    'P7TriggerArchitectureTest', 'InventoryReconciliationJobTest',
    'LeadRoutingHandlerTest', 'LeadConvertGuardTest', 'LeadEnrichRooftopServiceTest', 'LeadRoundRobinTest',
    'VehicleReservationGuardTest', 'VehicleReservationEventPublisherTest', 'InventoryGalleryControllerTest',
    'TestDriveBookingGuardTest', 'TestDriveFollowUpTest', 'OpportunityCalculatorControllerTest',
    'VinDecoderServiceTest', 'PaymentCalculatorServiceTest', 'OpportunityStageStampTest',
    'QuotePricingServiceTest', 'QuoteBuilderControllerTest', 'QuoteSummaryControllerTest',
    'QuoteTradeInGuardTest', 'QuoteTriggerEnforcementTest', 'DiscountApprovalTest',
    'FinanceApplicationControllerTest', 'FinancingStatusServiceTest', 'FinancingApprovalTest',
    'FinancingFlsEnforcementTest', 'DeliveryCompletionGuardTest', 'DeliveryCloseServiceTest',
    'ServiceVisitCapacityGuardTest', 'ServiceIntakeCaseServiceTest', 'LoyaltyAccrualServiceTest',
    'RedemptionServiceTest', 'ConsentGateServiceTest', 'CaseMilestoneServiceTest',
]


def main():
    for name in TESTS:
        assert (ROOT / 'force-app/main/default/classes' / (name + '.cls')).is_file(), name
    target = subprocess.run(['sf', 'data', 'query', '--target-org', 'ng-demo', '--query',
                             'SELECT Id FROM Organization', '--json'], text=True, capture_output=True, check=True)
    assert json.loads(target.stdout)['result']['records'][0]['Id'] == '00Daj00001Ae3iWEAR'
    command = ['sf', 'project', 'deploy', 'start', '--dry-run', '--target-org', 'ng-demo',
               '--manifest', 'manifest/p7-batch2-check.xml',
               '--pre-destructive-changes', 'manifest/p7-batch2-destructive.xml',
               '--test-level', 'RunSpecifiedTests', '--tests', *TESTS, '--wait', '10', '--json']
    process = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
    # Keep raw CLI fields while removing private machine paths from local evidence.
    raw = json.loads(process.stdout.replace(str(ROOT) + '/', '').replace(str(ROOT), '.'))
    raw.get('result', {}).pop('createdByName', None)
    job_id = raw.get('result', {}).get('id')
    if job_id:
        (ROOT / 'evidence/P7' / ('BATCH2_CHECK_ONLY_' + job_id + '.json')).write_text(json.dumps(raw, indent=2) + '\n')
    (ROOT / 'evidence/P7/BATCH2_CHECK_ONLY.json').write_text(json.dumps(raw, indent=2) + '\n')
    (ROOT / 'evidence/P7/BATCH2_CHECK_ONLY_COMMAND.json').write_text(json.dumps(command, indent=2) + '\n')
    result = raw.get('result', {})
    print(json.dumps({'exitCode': process.returncode, 'id': result.get('id'),
                      'status': result.get('status'), 'checkOnly': result.get('checkOnly'),
                      'numberComponentsDeployed': result.get('numberComponentsDeployed'),
                      'numberComponentsTotal': result.get('numberComponentsTotal'),
                      'numberComponentErrors': result.get('numberComponentErrors'),
                      'numberTestsCompleted': result.get('numberTestsCompleted'),
                      'numberTestsTotal': result.get('numberTestsTotal'),
                      'numberTestErrors': result.get('numberTestErrors'),
                      'componentFailures': result.get('details', {}).get('componentFailures', []),
                      'testFailures': result.get('details', {}).get('runTestResult', {}).get('failures', []),
                      'warnings': raw.get('warnings', [])}, indent=2))
    raise SystemExit(process.returncode)


if __name__ == '__main__':
    main()
