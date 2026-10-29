"""Offline checks only. No Salesforce requests, writes or Batch 4 test reruns."""
import copy
import importlib.util
import json
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("knowledge_prepare", ROOT / "scripts/knowledge/prepare_p6_15_import.py")
prepare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare)


def check():
    pack = json.loads((ROOT / "docs/knowledge/P6_ARTICLE_DRAFTS.json").read_text())
    result = prepare.build_request(pack)
    assert result["allOrNone"] is True and len(result["compositeRequest"]) == 20
    for i in range(10):
        article, category = result["compositeRequest"][2 * i:2 * i + 2]
        assert article["method"] == category["method"] == "POST"
        assert article["url"].endswith("/Knowledge__kav")
        assert category["url"].endswith("/Knowledge__DataCategorySelection")
        assert category["body"]["ParentId"] == "@{" + article["referenceId"] + ".id}"
        assert category["body"]["DataCategoryName"] == pack["articles"][i]["category"]
        assert not {"PublishStatus", "IsVisibleInApp", "KnowledgeArticleId", "Id"}.intersection(article["body"])
        assert all(article["body"][f] is False for f in ("IsVisibleInPkb", "IsVisibleInCsp", "IsVisibleInPrm"))
    unsafe = copy.deepcopy(pack)
    unsafe["articles"][0]["body"] = '<script>alert("not markup")</script>'
    escaped = prepare.build_request(unsafe)["compositeRequest"][0]["body"]["Body__c"]
    assert "<script>" not in escaped and "&lt;script&gt;" in escaped
    duplicate = copy.deepcopy(pack)
    duplicate["articles"][1]["urlName"] = duplicate["articles"][0]["urlName"]
    try:
        prepare.build_request(duplicate)
    except ValueError:
        pass
    else:
        raise AssertionError("Duplicate URLs must be rejected.")
    ns = {"m": "http://soap.sforce.com/2006/04/metadata"}
    manifest = ET.parse(ROOT / "manifest/p6-15-knowledge-prepare.xml").getroot()
    members = {t.findtext("m:name", namespaces=ns): [e.text for e in t.findall("m:members", ns)]
               for t in manifest.findall("m:types", ns)}
    assert members == {"CustomField": ["Knowledge__kav.Body__c"], "DataCategoryGroup": ["Northgate_Knowledge"],
                       "Layout": ["Knowledge__kav-NG Internal Article Layout"]}
    category_xml = ET.parse(ROOT / "force-app/main/default/datacategorygroups/Northgate_Knowledge.datacategorygroup-meta.xml").getroot()
    assert {c.findtext("m:name", namespaces=ns) for c in category_xml.findall("m:dataCategory/m:dataCategory", ns)} == prepare.CATEGORIES
    print(json.dumps({"status": "PASS", "articleCreatesPrepared": 10, "categorySelectionsPrepared": 10,
                      "metadataMembers": 3, "allOrNone": True, "externalVisibility": False,
                      "publicationRequests": 0, "networkRequests": 0}, indent=2))


if __name__ == "__main__":
    check()
