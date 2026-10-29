"""Read-only live verification of the approved P6-15 import; never creates or updates records."""
import html
import json
import subprocess
from collections import Counter
from pathlib import Path

from prepare_p6_15_import import build_request

ROOT = Path(__file__).resolve().parents[2]


def query(soql):
    result = subprocess.run(["sf", "data", "query", "--target-org", "ng-demo", "--query", soql, "--json"],
                            capture_output=True, text=True, check=True)
    response = json.loads(result.stdout)
    if response.get("status") != 0 or not response["result"]["done"]:
        raise RuntimeError("Incomplete or failed read-only verification query.")
    return response["result"]["records"]


def verify():
    assert query("SELECT Id FROM Organization")[0]["Id"] == "00Daj00001Ae3iWEAR"
    pack = json.loads((ROOT / "docs/knowledge/P6_ARTICLE_DRAFTS.json").read_text())
    receipt = json.loads((ROOT / "evidence/P6/P6_15_IMPORT_RECEIPT_2026-10-25.json").read_text())["compositeResponse"]
    assert len(receipt) == 20 and all(r["httpStatusCode"] == 201 and r["body"]["success"] and not r["body"]["errors"] for r in receipt)
    article_ids = {r["body"]["id"] for r in receipt if r["referenceId"].startswith("article")}
    category_ids = {r["body"]["id"] for r in receipt if r["referenceId"].startswith("category")}
    expected = {r["body"]["UrlName"]: r["body"] for r in build_request(pack)["compositeRequest"] if r["referenceId"].startswith("article")}
    slugs = ",".join("'" + s + "'" for s in expected)
    fields = "Id,KnowledgeArticleId,UrlName,Title,Summary,Body__c,Language,PublishStatus,IsVisibleInApp,IsVisibleInPkb,IsVisibleInCsp,IsVisibleInPrm"
    rows = []
    for status in ("Draft", "Online", "Archived"):
        rows.extend(query(f"SELECT {fields} FROM Knowledge__kav WHERE PublishStatus = '{status}' AND Language = 'en_US' AND UrlName IN ({slugs})"))
    assert len(rows) == 10 and {r["Id"] for r in rows} == article_ids
    assert len({r["UrlName"] for r in rows}) == 10
    for row in rows:
        assert row["PublishStatus"] == "Draft" and row["IsVisibleInApp"] is True
        assert all(row[f] is False for f in ("IsVisibleInPkb", "IsVisibleInCsp", "IsVisibleInPrm"))
        assert all(row[f] == expected[row["UrlName"]][f] for f in ("Title", "Summary", "Language"))
        # Salesforce normalizes numeric character references in Rich Text (&#x27; becomes &#39;).
        assert html.unescape(row["Body__c"]) == html.unescape(expected[row["UrlName"]]["Body__c"])
    ids = ",".join("'" + i + "'" for i in sorted(article_ids))
    selections = query(f"SELECT Id,ParentId,DataCategoryGroupName,DataCategoryName FROM Knowledge__DataCategorySelection WHERE ParentId IN ({ids})")
    assert len(selections) == 10 and {s["Id"] for s in selections} == category_ids
    assert Counter(s["ParentId"] for s in selections) == Counter({i: 1 for i in article_ids})
    categories = {a["urlName"]: a["category"] for a in pack["articles"]}
    actual_categories = {s["ParentId"]: s["DataCategoryName"] for s in selections}
    assert all(s["DataCategoryGroupName"] == "Northgate_Knowledge" for s in selections)
    assert all(actual_categories[r["Id"]] == categories[r["UrlName"]] for r in rows)
    print(json.dumps({"status": "PASS", "verifiedArticles": 10, "verifiedCategorySelections": 10,
                      "exactTitleSummaryLanguageMatches": 10, "htmlContentMatches": 10, "draftInternalOnly": 10,
                      "onlineOrArchivedMatchingVersions": 0,
                      "articles": [{"versionId": r["Id"], "masterId": r["KnowledgeArticleId"],
                                    "urlName": r["UrlName"], "category": actual_categories[r["Id"]]}
                                   for r in sorted(rows, key=lambda r: r["Id"])]}, indent=2))


if __name__ == "__main__":
    verify()
