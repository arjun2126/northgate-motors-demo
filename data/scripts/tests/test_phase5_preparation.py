"""Offline checks for evidence integrity, refusal safeguards and isolated generation."""
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('phase5', ROOT / 'data/scripts/phase5.py')
p5 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(p5)
sys.path.insert(0, str(ROOT / 'data/scripts'))
ledger_spec = importlib.util.spec_from_file_location('ledger_reconcile', ROOT / 'data/scripts/ledger-reconcile.py')
ledger = importlib.util.module_from_spec(ledger_spec)
ledger_spec.loader.exec_module(ledger)


class PreparationTest(unittest.TestCase):
    def test_original_count_conflict_cannot_pass(self):
        result = p5.reconcile(ROOT / 'data/csv')
        self.assertEqual(result['canonicalRecords'], 2085)
        self.assertEqual(result['governingFullTotal'], 2115)
        self.assertEqual(result['historicalBacklogFullTotal'], 2123)
        self.assertEqual(result['allocationAdjustment'], {'Product2': '+20', 'Delivery__c': '-28', 'net': -8})
        self.assertEqual(result['status'], 'RECONCILED_GOVERNING_2026_10_20')
        self.assertFalse(result['criteriaReduced'])

    def test_legacy_shape_and_isolation(self):
        rows = p5.legacy_rows()
        self.assertEqual([len(rows[k]) for k in ('Contact','Trade_In__c')], [24, 6])
        self.assertTrue(all(len(r['Trade_VIN__c']) == 16 and 'O' in r['Trade_VIN__c'] for r in rows['Trade_In__c']))
        emails = [r['Email'].casefold() for r in rows['Contact'] if '-EMAIL-' in r['Seed_Tag__c']]
        self.assertEqual(sorted(p5.Counter(emails).values()), [2, 2, 2])
        self.assertEqual(sum(not r['MailingPostalCode'] for r in rows['Contact']), 8)
        with self.assertRaises(ValueError):
            p5.prepare_legacy(ROOT / 'data/csv')

    def test_ledger_never_labels_updates_as_inserts(self):
        job = dict(id='750aj00001HqFv8AAF', object='Campaign', state='JobComplete',
                   createdDate='2026-10-18T05:42:04Z', systemModstamp='2026-10-18T05:43:00Z',
                   numberRecordsProcessed=5, numberRecordsFailed=0)
        rows = [{'sf__Created':'true'}] * 2 + [{'sf__Created':'false'}] * 3
        record = p5.ledger_from_job(job, rows, '2026-10-01', 3.9, '2026-10-18T05:43:01Z')
        self.assertEqual((record['inserted'], record['updated']), (2, 3))
        self.assertNotIn('completedAt', record)
        self.assertEqual(record['jobFinalModifiedAt'], job['systemModstamp'])
        with self.assertRaises(ValueError):
            p5.ledger_from_job(job, rows, '2026-10-01', None, None)
        with self.assertRaises(ValueError):
            p5.ledger_from_job(job, rows[:-1], '2026-10-01', 3.9, '2026-10-18T05:43:01Z')

    def test_snapshot_refusals(self):
        now = datetime.now(timezone.utc)
        snapshot = {'orgId': p5.ORG_ID, 'capturedAt': now.isoformat(),
                    'manifest': {n:p5.digest(ROOT/'data/csv'/n) for n in p5.OBJECTS.values()},
                    'records': {o: [] for o in p5.OBJECTS}}
        self.assertTrue(p5.reset_plan(snapshot, now)['dryRun'])
        for age in (timedelta(hours=2), timedelta(minutes=-1)):
            snapshot['capturedAt'] = (now - age).isoformat()
            with self.assertRaises(ValueError): p5.reset_plan(snapshot, now)
        snapshot['capturedAt'] = now.isoformat(); snapshot['orgId'] = 'other'
        with self.assertRaises(ValueError): p5.reset_plan(snapshot, now)

    def test_reset_scope_order_and_foreign_records(self):
        now = datetime.now(timezone.utc)
        snapshot = {'orgId':p5.ORG_ID, 'capturedAt':now.isoformat(),
                    'manifest':{n:p5.digest(ROOT/'data/csv'/n) for n in p5.OBJECTS.values()},
                    'records':{o:[] for o in p5.OBJECTS}}
        order = [r['object'] for r in p5.reset_plan(snapshot,now)['childFirst']]
        for child,parent in [('QuoteLineItem','Quote'),('Quote','Opportunity'),('Contact','Account'),
                             ('Service_Visit__c','Case'),('Loyalty_Transaction__c','Loyalty_Member__c')]:
            self.assertLess(order.index(child),order.index(parent))
        snapshot['records']['Lead']=[{'Id':'00Q000000000001AAA','Seed_Tag__c':'UAT-P2-KEEP'}]
        with self.assertRaises(ValueError): p5.reset_plan(snapshot,now)
        snapshot['records']['Lead']=[]
        snapshot['externalReferences']=[{'object':'Quote','reason':'Historical child'}]
        with self.assertRaises(ValueError): p5.reset_plan(snapshot,now)
        del snapshot['externalReferences']; snapshot['manifest']={'a.csv':'hash'}
        with self.assertRaises(ValueError): p5.reset_plan(snapshot,now)

    def test_burst_composition_resolution_and_teardown_scope(self):
        before={p.name:p5.digest(p) for p in (ROOT/'data/csv').glob('*.csv')}
        with tempfile.TemporaryDirectory(dir=os.environ['NG_TEST_TMP']) as directory:
            result=p5.prepare_burst(Path(directory)/'burst',datetime(2026,10,20,tzinfo=timezone.utc))
            self.assertEqual(result['prepared'],{'Lead':200,'Service_Visit__c':60,'Task':40})
            for obj,count in result['prepared'].items():
                rows=p5.read_csv(Path(directory)/'burst'/f'{obj}.csv')
                self.assertEqual(len(rows),count)
                self.assertTrue(all('CreatedDate' not in r for r in rows))
            self.assertTrue(all(r['Contact__c'].startswith('SEED-07-') for r in p5.read_csv(Path(directory)/'burst/Service_Visit__c.csv')))
        rows={'Lead':[{'Id':'00Q000000000001AAA','Seed_Tag__c':'SEED-77-BURST-LEAD-001'}],
              'Service_Visit__c':[],'Task':[]}
        plan=p5.burst_teardown(rows)
        self.assertEqual(plan['purgeIds'],['00Q000000000001AAA'])
        self.assertFalse(plan['orgWidePurge'])
        rows['Lead'][0]['Seed_Tag__c']='SEED-08-001'
        with self.assertRaises(ValueError): p5.burst_teardown(rows)
        self.assertEqual(before,{p.name:p5.digest(p) for p in (ROOT/'data/csv').glob('*.csv')})

    def test_legacy_exact_parent_map_and_csv_isolation(self):
        parents={f'SEED-98-VIN-{i:03d}':{'Opportunity__c':f'00600000000{i:04d}AAA',
                                       'Contact__c':f'00300000000{i:04d}AAA'} for i in range(1,7)}
        with tempfile.TemporaryDirectory(dir=os.environ['NG_TEST_TMP']) as directory:
            output=Path(directory)/'legacy'
            p5.prepare_legacy(output,parents)
            trades=p5.read_csv(output/'Trade_In__c.csv')
            self.assertEqual(len(trades),6)
            self.assertTrue(all(r['Opportunity__c'].startswith('006') for r in trades))
            with self.assertRaises(FileExistsError): p5.prepare_legacy(output,parents)
            with self.assertRaises(ValueError): p5.prepare_legacy(Path(directory)/'unmapped')

    def test_authoritative_ledger_partial_and_unknown_results(self):
        job={'id':'750aj00001HqFv8AAF','object':'Campaign','operation':'upsert','state':'JobComplete',
             'createdDate':'2026-10-18T05:42:30Z','systemModstamp':'2026-10-18T05:42:33Z',
             'numberRecordsProcessed':5,'numberRecordsFailed':2}
        body='sf__Id,sf__Created,Seed_Tag__c\n701000000000001AAA,true,SEED-19-001\n701000000000002AAA,true,SEED-19-002\n701000000000003AAA,true,SEED-19-003\n'
        result=ledger.reconcile_job(job,body,{'Campaign':{'SEED-19-001','SEED-19-002','SEED-19-003'}},set())
        self.assertEqual((result['inserted'],result['failed'],result['successful']),(3,2,3))
        self.assertIsNone(result['historicalStorageUsedMb'])
        unknown=ledger.reconcile_job(job,None,{},set())
        self.assertIsNone(unknown['inserted']); self.assertFalse(unknown['resultCountReconciled'])
        with self.assertRaises(ValueError): ledger.reconcile_job(job,body.splitlines()[0]+'\n',{},set())

    def test_drift_alarm(self):
        self.assertTrue(p5.expected_count(12, 12)['passed'])
        self.assertFalse(p5.expected_count(11, 12)['passed'])

    def test_full_acceptance_cannot_pass_missing_legacy_or_ledger(self):
        def query(soql):
            if soql.startswith('SELECT Seed_Tag__c FROM '):
                obj = soql.split()[3]
                return [{'Seed_Tag__c':r['Seed_Tag__c']} for r in p5.read_csv(ROOT / 'data/csv' / p5.OBJECTS[obj])]
            if soql.startswith('SELECT Id FROM OpportunityLineItem'):
                return [{'Id':str(i)} for i in range(100)]
            if soql.startswith('SELECT Id FROM Opportunity'):
                return [{'Id':'006000000000001AAA'}]
            if 'GROUP BY VIN__c' in soql or soql.startswith('SELECT Email'):
                return []
            if soql.startswith('SELECT Seed_Version__c'):
                return [{'Notes__c':'Loader-written batch row.'}]
            return [{'n':0}]
        with patch.object(p5, 'identity'), patch.object(p5, 'query', side_effect=query), patch.object(p5, 'get', return_value={'DataStorageMB':{'Max':5,'Remaining':1}}):
            result = p5.verify()
        self.assertFalse(result['passed'])
        self.assertFalse(result['checks']['legacyRequired']['passed'])
        self.assertFalse(result['checks']['ledgerCountsAndEvidence']['passed'])
        self.assertTrue(result['originalBacklogRetained'])

    def test_generator_determinism_without_touching_canonical(self):
        before = {p.name:p5.digest(p) for p in (ROOT / 'data/csv').glob('*.csv')}
        version = p5.digest(ROOT / 'data/SEED_VERSION.txt')
        with tempfile.TemporaryDirectory(dir=os.environ['NG_TEST_TMP']) as directory:
            outputs = []
            for name in ('first','second'):
                output = Path(directory) / name
                env = dict(os.environ, NG_GENERATOR_OUTPUT_DIR=str(output), ANCHOR_DATE='2026-10-01')
                subprocess.run(['npm','exec','--offline','--package=tsx','--','tsx','data/scripts/generate.ts'],
                               cwd=ROOT, env=env, check=True, capture_output=True)
                outputs.append({p.name:p5.digest(p) for p in output.glob('*.csv')})
            self.assertEqual(outputs[0], outputs[1])
            self.assertEqual(len(outputs[0]), 30)
            candidate=Path(directory)/'first'
            visits=p5.read_csv(candidate/'19-servicevisits.csv')
            self.assertEqual(sum(r['Status__c']=='Scheduled' and r['Scheduled_Start__c']<'2026-10-01' for r in visits),12)
            vehicles=p5.read_csv(candidate/'06-vehicles.csv')
            anchor=datetime(2026,10,1)
            ages=[(anchor-datetime.fromisoformat(r['Acquisition_Date__c'])).days for r in vehicles]
            self.assertEqual(sum(n>120 for n in ages),12)
            self.assertEqual(sum(n>60 for n in ages),15)
            for name,allowed in [('19-servicevisits.csv',{'Scheduled_Start__c'}),
                                 ('06-vehicles.csv',{'Acquisition_Date__c'})]:
                old=p5.read_csv(ROOT/'data/csv'/name); new=p5.read_csv(candidate/name)
                self.assertEqual(len(old),len(new))
                for a,b in zip(old,new):
                    self.assertEqual({k:v for k,v in a.items() if k not in allowed},
                                     {k:v for k,v in b.items() if k not in allowed})
        self.assertEqual(before, {p.name:p5.digest(p) for p in (ROOT / 'data/csv').glob('*.csv')})
        self.assertEqual(version, p5.digest(ROOT / 'data/SEED_VERSION.txt'))


if __name__ == '__main__':
    unittest.main()
