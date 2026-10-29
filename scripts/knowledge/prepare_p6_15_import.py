"""Build a local-only REST Composite request; never connect to Salesforce or write files."""
import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
API = "/services/data/v68.0/sobjects/"
CATEGORIES = {"Service", "Buying", "Financing", "Ownership", "Safety"}


def build_request(pack):
    if (pack.get("status") != "LocalDraft" or pack.get("language") != "en_US"
            or pack.get("audience") != "Internal" or pack.get("categoryGroup") != "Northgate_Knowledge"
            or set(pack.get("categories", [])) != CATEGORIES or len(pack.get("articles", [])) != 10):
        raise ValueError("Expected the ten internal en_US Northgate local drafts and approved category mapping.")
    requests, urls = [], set()
    for number, article in enumerate(pack["articles"], 1):
        slug = article["urlName"]
        if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", slug) or len(slug) > 255 or slug in urls:
            raise ValueError("Article URL names must be valid and unique; never overwrite existing articles.")
        urls.add(slug)
        if not 0 < len(article["title"]) <= 255 or not 0 < len(article["summary"]) <= 1000:
            raise ValueError("Article Title or Summary exceeds the current schema limit.")
        body = "".join("<p>" + html.escape(part) + "</p>" for part in article["body"].split("\n\n"))
        if not article["body"].strip() or len(body) > 32768 or article["category"] not in CATEGORIES:
            raise ValueError("Invalid body or category; do not generate a partial import.")
        reference = f"article{number:02d}"
        requests.append({"method": "POST", "url": API + "Knowledge__kav", "referenceId": reference,
                         "body": {"Title": article["title"], "UrlName": slug, "Summary": article["summary"],
                                  "Language": "en_US", "Body__c": body,
                                  "IsVisibleInPkb": False, "IsVisibleInCsp": False, "IsVisibleInPrm": False}})
        requests.append({"method": "POST", "url": API + "Knowledge__DataCategorySelection",
                         "referenceId": f"category{number:02d}",
                         "body": {"ParentId": "@{" + reference + ".id}",
                                  "DataCategoryGroupName": "Northgate_Knowledge",
                                  "DataCategoryName": article["category"]}})
    return {"allOrNone": True, "compositeRequest": requests}


if __name__ == "__main__":
    pack = json.loads((ROOT / "docs/knowledge/P6_ARTICLE_DRAFTS.json").read_text())
    print(json.dumps(build_request(pack), indent=2))
