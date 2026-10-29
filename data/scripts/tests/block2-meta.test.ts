/**
 * Block 2 metadata tests — verify the 15 new report/report-type XML files
 * exist, parse, and reference the correct source objects. No Salesforce calls.
 */
import { strict as assert } from 'node:assert';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { execFileSync } from 'node:child_process';

const ROOT = process.cwd();
const REP = resolve(ROOT, 'force-app/main/default/reports');
const RT = resolve(ROOT, 'force-app/main/default/reportTypes');

function readXml(p: string): any {
    return execFileSync('python3', ['-c', `import xml.etree.ElementTree as ET; import json; t=ET.parse('${p}').getroot(); print(json.dumps({c.tag.split('}')[-1]: c.text for c in t if c.text}))`], { encoding: 'utf8' });
}

function t1() {
    // 8 §9b reports exist
    const expected = [
        'Stale_Open_Leads',
        'Ignored_Cases',
        'Overdue_Service_Visits',
        'Aged_Inventory',
        'Revoked_Consents',
        'Stalled_Quoting_Opportunities',
        'SEED98_Defect_Accounts',
        'Duplicate_Households',
    ];
    for (const name of expected) {
        const p = resolve(REP, 'NG_05_DataQuality', `${name}.report-meta.xml`);
        assert.ok(existsSync(p), `missing: ${name}`);
    }
    console.log('  PASS block2: 8 §9b reports present');
}

function t2() {
    // 4 standalone reports (P5-10 to P5-13)
    const expected = [
        ['NG_03_Inventory', 'Inventory_Aging_60_120'],
        ['NG_04_Service', 'Service_SLA_Overdue'],
        ['NG_06_Loyalty', 'Loyalty_Tier_Distribution'],
        ['NG_05_DataQuality', 'Duplicate_Audit'],
    ];
    for (const [folder, name] of expected) {
        const p = resolve(REP, folder, `${name}.report-meta.xml`);
        assert.ok(existsSync(p), `missing: ${folder}/${name}`);
    }
    console.log('  PASS block2: 4 standalone reports present');
}

function t3() {
    // 3 custom report types
    const expected = ['VehicleTestDriveList', 'ContactLoyaltyList', 'ServiceCaseList'];
    for (const name of expected) {
        const p = resolve(RT, `${name}.reportType-meta.xml`);
        assert.ok(existsSync(p), `missing report type: ${name}`);
        const content = readFileSync(p, 'utf8');
        assert.ok(content.includes('<baseObject>'), `${name} missing baseObject`);
    }
    console.log('  PASS block2: 3 custom report types present with baseObject');
}

function t4() {
    // All 15 new files parse as valid XML
    const files = [
        'NG_05_DataQuality/Stale_Open_Leads.report-meta.xml',
        'NG_05_DataQuality/Ignored_Cases.report-meta.xml',
        'NG_05_DataQuality/Overdue_Service_Visits.report-meta.xml',
        'NG_05_DataQuality/Aged_Inventory.report-meta.xml',
        'NG_05_DataQuality/Revoked_Consents.report-meta.xml',
        'NG_05_DataQuality/Stalled_Quoting_Opportunities.report-meta.xml',
        'NG_05_DataQuality/SEED98_Defect_Accounts.report-meta.xml',
        'NG_05_DataQuality/Duplicate_Households.report-meta.xml',
        'NG_03_Inventory/Inventory_Aging_60_120.report-meta.xml',
        'NG_04_Service/Service_SLA_Overdue.report-meta.xml',
        'NG_06_Loyalty/Loyalty_Tier_Distribution.report-meta.xml',
        'NG_05_DataQuality/Duplicate_Audit.report-meta.xml',
    ];
    for (const f of files) {
        const p = resolve(REP, f);
        const out = execFileSync('python3', ['-c', `import xml.etree.ElementTree as ET; ET.parse('${p}')`], { encoding: 'utf8' });
    }
    const rts = ['VehicleTestDriveList', 'ContactLoyaltyList', 'ServiceCaseList'];
    for (const r of rts) {
        const p = resolve(RT, `${r}.reportType-meta.xml`);
        execFileSync('python3', ['-c', `import xml.etree.ElementTree as ET; ET.parse('${p}')`], { encoding: 'utf8' });
    }
    console.log('  PASS block2: all 15 new XML files parse cleanly');
}

function t5() {
    // VehicleTestDriveList uses Vehicle__c as base with Test_Drive__c section
    const p = resolve(RT, 'VehicleTestDriveList.reportType-meta.xml');
    const content = readFileSync(p, 'utf8');
    assert.ok(content.includes('<baseObject>Vehicle__c</baseObject>'), 'VehicleTestDrive base must be Vehicle__c');
    assert.ok(content.includes('Test_Drive__c'), 'VehicleTestDrive must reference Test_Drive__c');
    console.log('  PASS block2: VehicleTestDriveList structure correct');
}

function t6() {
    // ContactLoyaltyList uses Contact as base with Loyalty_Member__c section
    const p = resolve(RT, 'ContactLoyaltyList.reportType-meta.xml');
    const content = readFileSync(p, 'utf8');
    assert.ok(content.includes('<baseObject>Contact</baseObject>'), 'ContactLoyalty base must be Contact');
    assert.ok(content.includes('Loyalty_Member__c'), 'ContactLoyalty must reference Loyalty_Member__c');
    console.log('  PASS block2: ContactLoyaltyList structure correct');
}

function t7() {
    // ServiceCaseList uses Service_Visit__c as base with Case__c section
    const p = resolve(RT, 'ServiceCaseList.reportType-meta.xml');
    const content = readFileSync(p, 'utf8');
    assert.ok(content.includes('<baseObject>Service_Visit__c</baseObject>'), 'ServiceCase base must be Service_Visit__c');
    assert.ok(content.includes('Case__c'), 'ServiceCase must reference Case__c (custom lookup)');
    console.log('  PASS block2: ServiceCaseList structure correct');
}

function t8() {
    // New folders exist
    for (const f of ['NG_03_Inventory', 'NG_04_Service', 'NG_06_Loyalty']) {
        const p = resolve(REP, `${f}.reportFolder-meta.xml`);
        assert.ok(existsSync(p), `missing folder: ${f}`);
    }
    console.log('  PASS block2: 3 new report folders present');
}

t1(); t2(); t3(); t4(); t5(); t6(); t7(); t8();
console.log('[block2-meta.test] PASS — 15 new report/report-type files verified');
