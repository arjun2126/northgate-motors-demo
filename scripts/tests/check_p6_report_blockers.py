"""Offline report/access contracts only; does not modify Salesforce or rerun Apex suites."""
import json
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "force-app/main/default"
NS = {"m": "http://soap.sforce.com/2006/04/metadata"}


def text(node, name):
    return node.findtext("m:" + name, namespaces=NS)


def check():
    permissions = ET.parse(SOURCE / "permissionsets/PS_Phase6_Report_Field_Read.permissionset-meta.xml").getroot()
    fields = permissions.findall("m:fieldPermissions", NS)
    assert len(fields) == 6
    assert {text(p, "field") for p in fields} == {
        "Quote.Repeat_Purchase_Open__c", "Campaign.Consent_Purpose__c", "Campaign.Consent_Channel__c",
        "CampaignMember.Consent_Managed__c", "CampaignMember.Nurture_Eligible__c",
        "Loyalty_Member__c.Estimated_Liability_CAD__c"}
    assert all(text(p, "readable") == "true" and text(p, "editable") == "false" for p in fields)
    assert {c.tag.rsplit("}", 1)[-1] for c in permissions} <= {"description", "fieldPermissions", "label"}
    repeat = ET.parse(SOURCE / "reports/NG_PostSale/Repeat_Purchase_Contacts.report-meta.xml").getroot()
    filters = repeat.findall("m:crossFilters", NS)
    assert len(filters) == 2
    by_object = {text(f, "relatedTable"): f for f in filters}
    for obj, field, value in (("Service_Visit__c", "Status__c", "Completed"),
                              ("Quote", "Repeat_Purchase_Open__c", "true")):
        cross = by_object[obj]
        assert text(cross, "operation") == "with"
        criteria = cross.findall("m:criteriaItems", NS)
        assert len(criteria) == 1
        assert (text(criteria[0], "column"), text(criteria[0], "operator"), text(criteria[0], "value")) == (field, "equals", value)
    assert text(by_object["Quote"], "relatedTableJoinColumn") == "Buyer_Contact__c"
    formula = ET.parse(SOURCE / "objects/Quote/fields/Repeat_Purchase_Open__c.field-meta.xml").getroot()
    assert "NOT(Opportunity.IsClosed)" in text(formula, "formula")
    audit = ET.parse(SOURCE / "reports/NG_PostSale/Managed_Nurture_Membership_Audit.report-meta.xml").getroot()
    criteria = audit.findall("m:filter/m:criteriaItems", NS)
    assert len(criteria) == 1
    assert (text(criteria[0], "column"), text(criteria[0], "operator"), text(criteria[0], "value")) == (
        "Campaign.CampaignMembers$Consent_Managed__c", "equals", "true")
    loyalty = ET.parse(SOURCE / "reports/NG_Loyalty_Operations/Tier_Mix_and_Liability.report-meta.xml").getroot()
    assert any(text(c, "field") == "Loyalty_Member__c$Estimated_Liability_CAD__c"
               and text(c, "aggregateTypes") == "Sum" for c in loyalty.findall("m:columns", NS))
    manifest = ET.parse(ROOT / "manifest/p6-report-blocker-check.xml").getroot()
    selected = {text(t, "name"): [m.text for m in t.findall("m:members", NS)] for t in manifest.findall("m:types", NS)}
    assert selected == {"PermissionSet": ["PS_Phase6_Report_Field_Read"], "Report": [
        "NG_PostSale/Repeat_Purchase_Contacts", "NG_PostSale/Managed_Nurture_Membership_Audit",
        "NG_Loyalty_Operations/Tier_Mix_and_Liability"]}
    print(json.dumps({"status": "PASS", "readOnlyFieldGrants": 6, "objectOrAudienceGrants": 0,
                      "reportDefinitions": 3, "requiredFiltersAndLiabilitySum": True,
                      "scopedMetadataMembers": 4, "networkRequests": 0}, indent=2))


if __name__ == "__main__":
    check()
