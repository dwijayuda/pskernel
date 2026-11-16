#!/usr/bin/env python3
# Copyright (c) 2026 Dwijayuda. All rights reserved.
"""Verify and retain the exact qualified PS0 V1 release inputs."""
import hashlib
import json
import subprocess
import sys
import zipfile
from pathlib import Path

SOURCE = "156524fc660dbd6db8fbc4a5845d5a2d486860c3"
RUNNER = "fabaecaed7573daf3ffcca751699fceb9079e0cb"
RUN = 43750175058
REPO = "dwijayuda/pskernel"
ASSET = "ps0-bootstrap-lean4.35.0-156524fc-linux-x86_64.zip"
INPUTS = [
    (14196538258, ASSET, 285576940, "cef1a778bf408e593e735ce51468967fb795f8a936fc434ccb39e7e8a3cdf283"),
    (14197386699, "independent-audit.zip", 655, "7b3a22fbea17139916a72c24ffc5532bbc84c259d2af3ba0fe76658a1800bc5e"),
]
EXPECTED_JOBS = "checkpoint-qualification stage-one-base stage-one-compiler-early stage-one-compiler-middle stage-one-compiler stage-one stage-two-base stage-two-compiler-early stage-two-compiler-middle stage-two-compiler stage-two independent-audit".split()

def api(path):
    return json.loads(subprocess.check_output(["gh", "api", "repos/" + REPO + "/" + path]))

def digest(data):
    return hashlib.sha256(data).hexdigest()

def main():
    run = api("actions/runs/" + str(RUN))
    assert run["status"] == "completed" and run["conclusion"] == "success"
    assert run["head_sha"] == RUNNER and run["run_attempt"] == 1
    jobs = api("actions/runs/" + str(RUN) + "/jobs?per_page=100")["jobs"]
    assert [j["name"] for j in jobs] == EXPECTED_JOBS
    assert all(j["status"] == "completed" and j["conclusion"] == "success" for j in jobs)
    retained = []
    for aid, name, size, sha in INPUTS:
        meta = api("actions/artifacts/" + str(aid))
        assert meta["id"] == aid and not meta["expired"]
        assert meta["size_in_bytes"] == size and meta["digest"] == "sha256:" + sha
        assert meta["workflow_run"]["id"] == RUN and meta["workflow_run"]["head_sha"] == RUNNER
        with open(name, "wb") as output:
            subprocess.run(["gh", "api", "repos/" + REPO + "/actions/artifacts/" + str(aid) + "/zip"], stdout=output, check=True)
        data = Path(name).read_bytes()
        assert len(data) == size and digest(data) == sha
        retained.append({"artifact_id": aid, "file": name, "bytes": size, "sha256": sha})
    with zipfile.ZipFile("independent-audit.zip") as z:
        receipt = z.read("audit.json")
    assert digest(receipt) == "a60a100c22da0a96f29489e0082ed75f24d4560722423ccc2a196850179bb217"
    Path("audit.json").write_bytes(receipt)
    audit = json.loads(receipt)
    assert audit["source"] == SOURCE and audit["status"] == "PASS"
    assert audit["modules"] == 2569 and audit["stages"] == 2
    assert audit["grammar_migration_complete"] is False and audit["verified_execution"] is False
    with zipfile.ZipFile(ASSET) as z:
        root = Path("retained-stage").resolve()
        for item in z.infolist():
            target = (root / item.filename).resolve()
            assert target.is_relative_to(root), item.filename
        z.extractall(root)
    sys.path.insert(0, str(Path("source/experiments/ps0/tests").resolve()))
    from native_compiler_prefix import verify_compiler_prefix
    prefix = verify_compiler_prefix(root / "compiler-evidence", SOURCE)
    manifest = {
        "schema": "ps0-qualified-bootstrap-release/1",
        "source": SOURCE, "runner": RUNNER, "lean_commit": audit["lean_commit"],
        "qualification_run": RUN, "qualification_url": run["html_url"],
        "jobs": [{"id": j["id"], "name": j["name"], "conclusion": j["conclusion"]} for j in jobs],
        "artifacts": retained, "audit_receipt_sha256": digest(receipt),
        "driver_sha256": prefix["driver_sha256"], "metadata_files": prefix["metadata_files"],
        "ps_sources_rehashed_at_publication": prefix["ps_sources_rehashed"],
        "audit": audit, "scope": audit["scope"],
        "grammar_migration_complete": False, "verified_execution": False,
    }
    Path("release-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    names = [ASSET, "independent-audit.zip", "audit.json", "release-manifest.json"]
    Path("SHA256SUMS").write_text("".join(digest(Path(n).read_bytes()) + "  " + n + "\n" for n in names))
    print("PS0_QUALIFIED_RELEASE_INPUTS: PASS")

if __name__ == "__main__":
    main()
