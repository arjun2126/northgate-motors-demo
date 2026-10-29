"""Read-only integrity checks for the Batch 4 content and exact metadata boundary."""
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NS = {"m": "http://soap.sforce.com/2006/04/metadata"}
SOURCE = ROOT / "force-app/main/default"


def check():
    pack = json.loads((ROOT / "docs/knowledge/P6_ARTICLE_DRAFTS.json").read_text())
    assert pack["status"] == "LocalDraft" and pack["audience"] == "Internal"
    articles = pack["articles"]
    assert len(articles) == 10 and len({a["urlName"] for a in articles}) == 10
    for article in articles:
        assert 0 < len(article["title"]) <= 255
        assert re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", article["urlName"])
        assert 0 < len(article["summary"]) <= 1000
        assert len(article["body"]) > 400 and article["caseUse"]
        assert article["category"] in pack["categories"]

    manifest = ET.parse(ROOT / "manifest/p6-batch4-check.xml").getroot()
    types = {t.findtext("m:name", namespaces=NS): [m.text for m in t.findall("m:members", NS)]
             for t in manifest.findall("m:types", NS)}
    assert not {"Flow", "Settings", "Profile", "PermissionSetGroup", "CustomMetadata"}.intersection(types)
    assert all("*" not in member for members in types.values() for member in members)
    assert types["ApexTrigger"] == ["CaseMilestoneTrigger"]
    assert types["CustomField"] == ["Case.First_Response_On__c"]
    assert "DiscountApprovalTest" not in types["ApexClass"], "Do not package unrelated dirty test source."
    for app_name in types["CustomApplication"]:
        app = ET.parse(SOURCE / f"applications/{app_name}.app-meta.xml").getroot()
        assert app.findtext("m:navType", namespaces=NS) == "Console"
        tabs = {n.text for n in app.findall("m:tabs", NS)}
        mapped = {n.text for n in app.findall("m:workspaceConfig/m:mappings/m:tab", NS)}
        assert tabs == mapped, f"Incomplete console mappings: {app_name}"
        assert not app.findall("m:profileActionOverrides", NS)
    navigation = ET.parse(SOURCE / "permissionsets/PS_Northgate_Consoles.permissionset-meta.xml").getroot()
    assert not navigation.findall("m:objectPermissions", NS)
    assert not navigation.findall("m:fieldPermissions", NS)
    sales = ET.parse(SOURCE / "applications/Northgate_Sales_Console.app-meta.xml").getroot()
    existing_sales = ET.parse(SOURCE / "applications/Northgate_Sales.app-meta.xml").getroot()
    def overrides(app):
        return {(o.findtext("m:pageOrSobjectType", namespaces=NS), o.findtext("m:actionName", namespaces=NS),
                 o.findtext("m:content", namespaces=NS)) for o in app.findall("m:actionOverrides", NS)}
    assert overrides(sales) == overrides(existing_sales), "Preserve accepted Sales entry points."
    print(json.dumps({"status": "PASS", "articleDrafts": len(articles),
                      "metadataMembers": sum(map(len, types.values())),
                      "checks": ["unique draft URLs", "content/category mapping", "exact manifest boundary",
                                 "console workspace mappings", "no console object/FLS expansion",
                                 "accepted Sales page references"]}, indent=2))


if __name__ == "__main__":
    check()
