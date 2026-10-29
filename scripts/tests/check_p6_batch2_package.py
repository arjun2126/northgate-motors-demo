"""Read-only scope, inactive-config and source-hash check for the Batch 2 manifest."""

import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "force-app/main/default"
MANIFEST = ROOT / "manifest/p6-batch2-check.xml"
NS = {"m": "http://soap.sforce.com/2006/04/metadata"}
SIMPLE = {
    "ApexClass": ("classes", ".cls", True),
    "ApexTrigger": ("triggers", ".trigger", True),
    "CustomPermission": ("customPermissions", ".customPermission-meta.xml", False),
    "PermissionSet": ("permissionsets", ".permissionset-meta.xml", False),
    "FlexiPage": ("flexipages", ".flexipage-meta.xml", False),
    "QuickAction": ("quickActions", ".quickAction-meta.xml", False),
    "CustomMetadata": ("customMetadata", ".md-meta.xml", False),
}


def inspect_package():
    files = {MANIFEST}
    members = {}
    for group in ET.parse(MANIFEST).getroot().findall("m:types", NS):
        kind = group.findtext("m:name", namespaces=NS)
        names = [item.text for item in group.findall("m:members", NS)]
        assert all(name and "*" not in name for name in names), "Explicit members required"
        members[kind] = names
        for name in names:
            if kind in SIMPLE:
                directory, suffix, companion = SIMPLE[kind]
                file = SOURCE / directory / (name + suffix)
                files.add(file)
                if companion:
                    files.add(file.with_name(file.name + "-meta.xml"))
            elif kind == "CustomField":
                object_name, field_name = name.split(".", 1)
                files.add(SOURCE / "objects" / object_name / "fields" / (field_name + ".field-meta.xml"))
            elif kind == "CustomObject":
                assert name == "Loyalty_Program__mdt", "No existing object-wide metadata allowed"
                files.update((SOURCE / "objects" / name).rglob("*.xml"))
            elif kind == "LightningComponentBundle":
                files.update(file for file in (SOURCE / "lwc" / name).iterdir() if file.is_file())
            else:
                raise AssertionError(f"Unapproved metadata type: {kind}")
    assert len(members["ApexClass"]) == 25
    assert "ExecutiveServiceMetricsPublisherTest" in members["ApexClass"]
    assert "ServiceVisitTrigger" not in members["ApexTrigger"]
    assert "Layout" not in members and "Flow" not in members
    program = ET.parse(SOURCE / "customMetadata/Loyalty_Program.Default.md-meta.xml").getroot()
    values = {value.findtext("m:field", namespaces=NS): value.findtext("m:value", namespaces=NS)
              for value in program.findall("m:values", NS)}
    assert values["Is_Active__c"] == "false", "Program must remain inactive"
    hashes = {}
    for file in sorted(files):
        assert file.is_file(), f"Missing source: {file.relative_to(ROOT)}"
        if file.suffix == ".xml":
            ET.parse(file)
        hashes[str(file.relative_to(ROOT))] = hashlib.sha256(file.read_bytes()).hexdigest()
    package_hash = hashlib.sha256(json.dumps(hashes, sort_keys=True).encode()).hexdigest()
    snapshot = ROOT / "evidence/P6/BATCH2_SOURCE_SNAPSHOT_2026-10-24.json"
    if snapshot.exists():
        assert json.loads(snapshot.read_text())["packageSha256"] == package_hash, "Selected source differs from the review snapshot"
    return {"sourceFiles": len(hashes), "programActive": False, "packageSha256": package_hash,
            "manifestSha256": hashes[str(MANIFEST.relative_to(ROOT))], "files": hashes}


if __name__ == "__main__":
    print(json.dumps(inspect_package(), indent=2, sort_keys=True))
