#!/usr/bin/env python3
"""Authenticate immutable old/new generated bundles; never compile or qualify them."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import pathlib
import re
import stat
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile

REPOSITORY = "dwijayuda/pskernel"
BASELINE_SOURCE = "f9e9b20f92ce2ffa4a666acaf55aa8852949f589"
BASELINE_RUN = 39622521184
BASELINE_ARTIFACT = 12358040951
BASELINE_ZIP_BYTES = 3378995
BASELINE_ZIP_SHA256 = "25abe3ecf39fb76b79d8c41afe56e673309d91c8567de93ae505082d7ccb30a2"
BASELINE_KERNEL_SHA256 = "a216453f399f38297fd6ce214d5973342c3307834ea9e8312fca1ae16c1c5afa"
REFERENCE_RUN = 39622521186
REFERENCE_JOB = 119299431737
REFERENCE_ARTIFACT = 12354733263
REFERENCE_ZIP_BYTES = 114912
REFERENCE_ZIP_SHA256 = "14ede6035b1fe3c037deeaccc53439cf9a97d72ac020e20c34729bd5717c7ac3"
ARENA_SHA256 = "98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d"
LEAN_COMMIT = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
INTEGRATION_WORKFLOW = ".github/workflows/psc1-pskernel-expr-v2-integration.yml"
PROVIDER_PREFIX = "dist/expr-v2/integration/provider/"
BUNDLE_FILES = {
    "kernel.js", "kernel.ts", "kernel.d.ts", "kernel.js.map",
    "scripts/pskernel-canonical-provider.mjs",
    "npm-runtime/canonical-admissions-wire.mjs", "package.json", "README.md",
}
DOWNLOAD_LIMIT = 256 * 1024 * 1024


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class SafeRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, message, headers, new_url):
        require(urllib.parse.urlparse(new_url).scheme == "https", "non-HTTPS artifact redirect")
        redirected = super().redirect_request(request, fp, code, message, headers, new_url)
        if urllib.parse.urlparse(request.full_url).netloc != urllib.parse.urlparse(new_url).netloc:
            redirected.remove_header("Authorization")
        return redirected


def download(path: str) -> bytes:
    token = os.environ.get("PSC1_PERF_TOKEN")
    require(bool(token), "PSC1_PERF_TOKEN is required for authenticated Actions artifacts")
    url = "https://api.github.com/repos/" + REPOSITORY + path
    opener = urllib.request.build_opener(SafeRedirect())
    for attempt in range(3):
        request = urllib.request.Request(url, headers={
            "Authorization": "Bearer " + token,
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "pskernel-artifact-paired-performance",
        })
        try:
            with opener.open(request, timeout=60) as response:
                data = response.read(DOWNLOAD_LIMIT + 1)
            require(len(data) <= DOWNLOAD_LIMIT, "artifact/API response exceeds download bound")
            return data
        except (urllib.error.URLError, TimeoutError) as error:
            if isinstance(error, urllib.error.HTTPError) and error.code not in (429, 500, 502, 503, 504):
                raise
            if attempt == 2:
                raise
            time.sleep(attempt + 1)
    raise AssertionError("unreachable download retry state")


def api(path: str) -> dict:
    value = json.loads(download(path).decode("utf-8"))
    require(isinstance(value, dict), "GitHub API did not return an object")
    return value


def run_identity(run_id: int, source: str, *, integration: bool) -> tuple[dict, list[dict]]:
    run = api("/actions/runs/" + str(run_id))
    require(run.get("id") == run_id and run.get("head_sha") == source
            and run.get("repository", {}).get("full_name") == REPOSITORY
            and run.get("head_repository", {}).get("full_name") == REPOSITORY
            and run.get("status") == "completed", "producer run source, repository or terminal status differs")
    if integration:
        require(run.get("path") == INTEGRATION_WORKFLOW and run.get("conclusion") == "success",
                "candidate/baseline integration run is not terminal success")
    response = api("/actions/runs/" + str(run_id) + "/jobs?per_page=100")
    jobs = response.get("jobs", [])
    require(isinstance(jobs, list) and response.get("total_count") == len(jobs),
            "producer job enumeration is incomplete")
    if integration:
        for name in ("native-dag-integration", "generated-dag-integration"):
            selected = [job for job in jobs if job.get("name") == name]
            require(len(selected) == 1 and selected[0].get("status") == "completed"
                    and selected[0].get("conclusion") == "success",
                    "required producer integration job did not pass: " + name)
    return run, jobs


def artifact(run_id: int, source: str, artifact_id: int | None, name: str) -> tuple[dict, bytes]:
    response = api("/actions/runs/" + str(run_id) + "/artifacts?per_page=100")
    values = response.get("artifacts", [])
    require(isinstance(values, list) and response.get("total_count") == len(values),
            "producer artifact enumeration is incomplete")
    selected = [value for value in values if value.get("name") == name
                and (artifact_id is None or value.get("id") == artifact_id)]
    require(len(selected) == 1, "missing or ambiguous immutable artifact")
    value = selected[0]
    identity = value.get("workflow_run", {})
    require(value.get("expired") is False and identity.get("id") == run_id
            and identity.get("head_sha") == source, "artifact source/run identity differs")
    expected = value.get("digest", "")
    require(isinstance(expected, str) and re.fullmatch(r"sha256:[0-9a-f]{64}", expected) is not None,
            "artifact lacks an exact SHA256 digest")
    raw = download("/actions/artifacts/" + str(value["id"]) + "/zip")
    require(len(raw) == value.get("size_in_bytes") and digest(raw) == expected[7:],
            "downloaded ZIP does not match immutable GitHub artifact metadata")
    return value, raw


def safe_members(archive: zipfile.ZipFile) -> dict[str, zipfile.ZipInfo]:
    values = {}
    for entry in archive.infolist():
        name = entry.filename
        require(not name.startswith("/") and "\\" not in name
                and ".." not in pathlib.PurePosixPath(name).parts, "unsafe ZIP member path")
        if entry.is_dir():
            continue
        require(name not in values and 0 <= entry.file_size <= DOWNLOAD_LIMIT,
                "duplicate or oversized ZIP member")
        mode = (entry.external_attr >> 16) & 0o170000
        require(mode in (0, stat.S_IFREG), "nonregular ZIP member")
        values[name] = entry
    return values


def unique_member(members: dict, suffix: str) -> str:
    matches = [name for name in members if name == suffix or name.endswith("/" + suffix)]
    require(len(matches) == 1, "missing or ambiguous ZIP member: " + suffix)
    return matches[0]


def restore_bundle(raw: bytes, archive_path: pathlib.Path, out: pathlib.Path,
                   source: str, run_id: int, *, baseline: bool) -> dict:
    archive_path.write_bytes(raw)
    with zipfile.ZipFile(archive_path) as archive:
        members = safe_members(archive)
        manifest_name = unique_member(members, PROVIDER_PREFIX + "artifacts.json")
        manifest_raw = archive.read(manifest_name)
        manifest = json.loads(manifest_raw.decode("utf-8"))
        require(manifest.get("schema") == "pskernel-core-artifacts-v1"
                and manifest.get("repository") == REPOSITORY
                and manifest.get("sourceSha") == source
                and manifest.get("workflowRun") == "https://github.com/" + REPOSITORY + "/actions/runs/" + str(run_id)
                and manifest.get("kind") == "lean-generated-js"
                and manifest.get("leanToolchain") == "leanprover/lean4:v4.35.0"
                and manifest.get("leanCommit") == LEAN_COMMIT
                and manifest.get("typescript") == "7.0.2"
                and manifest.get("checkerFuelDefault") == 4096
                and re.fullmatch(r"v22\.[0-9]+\.[0-9]+", manifest.get("node", "")) is not None,
                "generated manifest source/toolchain/resource identity differs")
        records = manifest.get("files", [])
        require(isinstance(records, list) and len(records) == len(BUNDLE_FILES),
                "incomplete generated-provider dependency manifest")
        paths = [record.get("path") for record in records]
        require(set(paths) == {PROVIDER_PREFIX + name for name in BUNDLE_FILES},
                "unexpected or missing generated-provider dependency")
        root = manifest_name[:-len("artifacts.json")]
        restored = {}
        for record in records:
            relative = record["path"][len(PROVIDER_PREFIX):]
            member = root + relative
            require(member in members, "manifest dependency missing from ZIP: " + relative)
            data = archive.read(member)
            require(bool(data) and len(data) == record.get("bytes") and digest(data) == record.get("sha256"),
                    "manifest dependency digest differs: " + relative)
            restored[relative] = data
        require(json.loads(restored["package.json"]) == {"private": True, "type": "module"},
                "provider package module/deployment scope differs")
        source_map = json.loads(restored["kernel.js.map"])
        require(source_map.get("version") == 3 and isinstance(source_map.get("sources"), list)
                and bool(source_map["sources"]) and bool(source_map.get("mappings")),
                "invalid generated source map")
        for index, name in enumerate(source_map["sources"]):
            contents = source_map.get("sourcesContent", [])
            if index < len(contents) and isinstance(contents[index], str):
                continue
            require(isinstance(name, str) and not name.startswith("/")
                    and ".." not in pathlib.PurePosixPath(name).parts
                    and source_map.get("sourceRoot", "") in ("", ".")
                    and name in restored, "source map points outside restored bundle")
        if baseline:
            require(digest(restored["kernel.js"]) == BASELINE_KERNEL_SHA256
                    and len(restored["kernel.js"]) == 9891165,
                    "qualified baseline kernel differs")
    out.mkdir(parents=True, exist_ok=True)
    for relative, data in restored.items():
        destination = out / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
    (out / "artifacts.json").write_bytes(manifest_raw)
    return {"source_sha": source, "producer_run": run_id, "manifest_sha256": digest(manifest_raw),
            "kernel_sha256": digest(restored["kernel.js"]), "files": records,
            "producer_node": manifest["node"], "producer_typescript": manifest["typescript"],
            "route": "authentic checked Lean-source PSC1/TypeScript bundle"}


def restore_reference(raw: bytes, archive_path: pathlib.Path, out: pathlib.Path) -> dict:
    archive_path.write_bytes(raw)
    with zipfile.ZipFile(archive_path) as archive:
        members = safe_members(archive)
        data = archive.read(unique_member(members, "report.json"))
    reference = json.loads(data.decode("utf-8"))
    tests, controls = reference.get("tests", []), reference.get("controls", [])
    require(reference.get("archive_sha256") == ARENA_SHA256
            and reference.get("target_lean") == {"version": "4.35.0", "githash": LEAN_COMMIT}
            and reference.get("official_reference_complete") is True
            and reference.get("total") == 193 and reference.get("excluded_cases") == []
            and reference.get("native_435_reexport") is False
            and len(tests) == 193
            and len({(row["label"], row["name"]) for row in tests}) == 193
            and all(row.get("official", {}).get("verdict") in ("accepted", "rejected") for row in tests)
            and len(controls) == 2 and {row.get("expected") for row in controls} == {"accepted", "rejected"}
            and all(row.get("expected") == row.get("verdict") for row in controls),
            "official reference is incomplete or has different provenance/controls")
    out.write_bytes(data)
    return {"source_sha": BASELINE_SOURCE, "producer_run": REFERENCE_RUN,
            "producer_job": REFERENCE_JOB, "artifact_id": REFERENCE_ARTIFACT,
            "artifact_zip_sha256": digest(raw), "report_sha256": digest(data),
            "scope": "authenticated existing official reference; no new oracle execution"}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate-run", type=int, required=True)
    parser.add_argument("--candidate-source", required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    args = parser.parse_args()
    require(args.candidate_run > 0 and re.fullmatch(r"[0-9a-f]{40}", args.candidate_source) is not None,
            "candidate must have an exact positive run ID and full source SHA")
    require(args.candidate_source != BASELINE_SOURCE, "candidate is the unchanged baseline")
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    records = {}
    for label, source, run_id, artifact_id in (
        ("baseline", BASELINE_SOURCE, BASELINE_RUN, BASELINE_ARTIFACT),
        ("candidate", args.candidate_source, args.candidate_run, None),
    ):
        run, jobs = run_identity(run_id, source, integration=True)
        value, raw = artifact(run_id, source, artifact_id, "psc1-v2-dag-generated-js")
        if label == "baseline":
            require(len(raw) == BASELINE_ZIP_BYTES and digest(raw) == BASELINE_ZIP_SHA256,
                    "baseline artifact differs from the immutable qualification receipt")
        receipt = restore_bundle(raw, out / (label + ".zip"), out / label,
                                 source, run_id, baseline=label == "baseline")
        receipt.update(artifact_id=value["id"], artifact_zip_sha256=digest(raw),
                       artifact_zip_bytes=len(raw), producer_run_attempt=run["run_attempt"],
                       required_jobs=[{"id": job["id"], "name": job["name"], "conclusion": job["conclusion"]}
                                      for job in jobs if job["name"] in
                                      ("native-dag-integration", "generated-dag-integration")])
        records[label] = receipt
    reference_run, jobs = run_identity(REFERENCE_RUN, BASELINE_SOURCE, integration=False)
    official = [job for job in jobs if job.get("id") == REFERENCE_JOB
                and job.get("name") == "official-arena-reference"]
    require(len(official) == 1 and official[0].get("status") == "completed"
            and official[0].get("conclusion") == "success", "official producer job did not pass")
    value, raw = artifact(REFERENCE_RUN, BASELINE_SOURCE, REFERENCE_ARTIFACT, "psc1-arena435-official-reference")
    require(len(raw) == REFERENCE_ZIP_BYTES and digest(raw) == REFERENCE_ZIP_SHA256,
            "official reference artifact differs from the immutable receipt")
    records["official_reference"] = restore_reference(raw, out / "official-reference.zip",
                                                       out / "official-reference.json")
    result = {"format": "psc1-paired-performance-artifacts-v1", "repository": REPOSITORY,
              "workflow_source_sha": os.environ.get("GITHUB_SHA"), **records,
              "compiler_reexecuted": False, "canonical_rechecked": False,
              "new_kernel_qualification_established": False}
    (out / "authentication.json").write_text(json.dumps(result, indent=2) + "\n")
    print("PSC1_PAIRED_ARTIFACT_AUTHENTICATION " + json.dumps(result), flush=True)


if __name__ == "__main__":
    main()
