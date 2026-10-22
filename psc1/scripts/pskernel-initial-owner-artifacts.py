#!/usr/bin/env python3
"""Authenticate the exact generated bundles for the initial-session whole-call benchmark."""
from __future__ import annotations

import argparse
import hashlib
import io
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
BASELINE_SOURCE = "0420aa896b04197aebd14444c1d2c4a36a41df9e"
BASELINE_RUN = 39664059278
BASELINE_ARTIFACT = 12378492499
BASELINE_ZIP_BYTES = 3391050
BASELINE_ZIP_SHA256 = "356db99fec59ff5528dabe797e181ffa48a05b1a9365afb8c177e799fbe6a70f"
BASELINE_KERNEL_SHA256 = "2d97cd7cb352bcccff0ef97676cff44bea0b8701fffe53c5a550a14ac07842c3"
BASELINE_KERNEL_BYTES = 9930508
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
            "User-Agent": "pskernel-initial-owner-artifacts",
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


def run_identity(run_id: int, source: str, *, initial_owner: bool) -> tuple[dict, list[dict]]:
    run = api("/actions/runs/" + str(run_id))
    require(run.get("id") == run_id and run.get("head_sha") == source
            and run.get("repository", {}).get("full_name") == REPOSITORY
            and run.get("head_repository", {}).get("full_name") == REPOSITORY
            and run.get("status") == "completed"
            and run.get("conclusion") == "success"
            and run.get("path") == INTEGRATION_WORKFLOW,
            "producer integration source, repository or terminal success differs")
    response = api("/actions/runs/" + str(run_id) + "/jobs?per_page=100")
    jobs = response.get("jobs", [])
    require(isinstance(jobs, list) and response.get("total_count") == len(jobs),
            "producer job enumeration is incomplete")
    selected_jobs = {}
    for name in ("native-dag-integration", "generated-dag-integration"):
        selected = [job for job in jobs if job.get("name") == name]
        require(len(selected) == 1 and selected[0].get("status") == "completed"
                and selected[0].get("conclusion") == "success",
                "required producer integration job did not pass: " + name)
        selected_jobs[name] = selected[0]
    if initial_owner:
        required_steps = {
            "native-dag-integration": (
                "Check authoritative new-prefix mutual and nested owners",
                "Check local metadata and cache-scope theorems",
            ),
            "generated-dag-integration": (
                "Check generated mutual and nested prefix owners in detached Node",
            ),
        }
        for name, expected in required_steps.items():
            steps = selected_jobs[name].get("steps", [])
            for step_name in expected:
                matching = [step for step in steps if step.get("name") == step_name]
                require(len(matching) == 1 and matching[0].get("status") == "completed"
                        and matching[0].get("conclusion") == "success",
                        "candidate initial-owner producer step did not pass: " + step_name)
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
                   source: str, run_id: int, run_attempt: int, *, baseline: bool) -> dict:
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
                and manifest.get("runAttempt") == str(run_attempt)
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
                    and len(restored["kernel.js"]) == BASELINE_KERNEL_BYTES,
                    "qualified baseline kernel differs")
        else:
            session_log_name = unique_member(members, "psc1-generated-prefix-js.log")
            session_lines = archive.read(session_log_name).decode("utf-8").splitlines()
            require("PSC1_V2_SESSION_OWNERS_JS: PASS kinds=8 direct=7 privateIDs=5 forks=2"
                    in session_lines, "candidate lacks exact prior-session ownership qualification")
    require(not out.exists() or not any(out.iterdir()), "runtime destination is not empty")
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


def inspect_native_measurements(out: pathlib.Path, label: str, source: str,
                                run_id: int, run_attempt: int) -> dict:
    value, raw = artifact(run_id, source, None, "psc1-v2-dag-native")
    with zipfile.ZipFile(io.BytesIO(raw)) as archive:
        members = safe_members(archive)
        manifest_raw = archive.read(unique_member(members, "dist/expr-v2/native-artifacts.json"))
        manifest = json.loads(manifest_raw.decode("utf-8"))
        require(manifest.get("schema") == "pskernel-core-artifacts-v1"
                and manifest.get("repository") == REPOSITORY
                and manifest.get("sourceSha") == source
                and manifest.get("workflowRun") == "https://github.com/" + REPOSITORY + "/actions/runs/" + str(run_id)
                and manifest.get("runAttempt") == str(run_attempt)
                and manifest.get("kind") == "native"
                and manifest.get("leanCommit") == LEAN_COMMIT
                and manifest.get("checkerFuelDefault") == 4096,
                "native measurement source/toolchain identity differs")
        log_raw = archive.read(unique_member(members, "psc1-dag-native-bench.log"))
        memory_raw = archive.read(unique_member(members, "psc1-dag-native-bench.memory"))
    records = [line for line in log_raw.decode("utf-8").splitlines()
               if line.startswith("PSC1_DAG_NATIVE_") or line == "PSC1_V2_DAG_NATIVE_BENCH: PASS"]
    timed = [line for line in records if line.startswith((
        "PSC1_DAG_NATIVE_SAMPLE ", "PSC1_DAG_NATIVE_WHNF_SAMPLE ", "PSC1_DAG_NATIVE_DEFEQ_SAMPLE "))]
    require(len(records) == 337 and len(timed) == 150
            and all("all_correct=true" in line for line in timed)
            and records[-1] == "PSC1_V2_DAG_NATIVE_BENCH: PASS",
            "native benchmark records are incomplete")
    destination = out / (label + "-native-measurements")
    destination.mkdir()
    (destination / "artifacts.json").write_bytes(manifest_raw)
    (destination / "benchmark.log").write_bytes(log_raw)
    (destination / "benchmark.memory").write_bytes(memory_raw)
    receipt = {"label": label, "source_sha": source, "producer_run": run_id,
               "artifact_id": value["id"], "artifact_zip_bytes": len(raw),
               "artifact_zip_sha256": digest(raw), "log_sha256": digest(log_raw),
               "log_bytes": len(log_raw), "records": len(records), "timed_records": len(timed),
               "outer_memory": memory_raw.decode("utf-8").strip(),
               "outer_memory_sha256": digest(memory_raw), "no_benchmark_reexecution": True}
    print("PSC1_NATIVE_BENCHMARK_ARCHIVE " + json.dumps(receipt, sort_keys=True), flush=True)
    for index, record in enumerate(records):
        print("PSC1_NATIVE_BENCHMARK_RECORD " + json.dumps({
            "label": label, "source": source, "index": index, "record": record}, sort_keys=True))
    return receipt


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate-run", type=int, required=True)
    parser.add_argument("--candidate-source", required=True)
    parser.add_argument("--candidate-artifact", type=int, required=True)
    parser.add_argument("--candidate-zip-bytes", type=int, required=True)
    parser.add_argument("--candidate-zip-sha256", required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    args = parser.parse_args()
    require(args.candidate_run > 0 and args.candidate_artifact > 0
            and 0 < args.candidate_zip_bytes <= DOWNLOAD_LIMIT
            and re.fullmatch(r"[0-9a-f]{40}", args.candidate_source) is not None
            and re.fullmatch(r"[0-9a-f]{64}", args.candidate_zip_sha256) is not None,
            "candidate requires exact source, run, artifact, ZIP bytes and SHA256")
    require(args.candidate_source != BASELINE_SOURCE, "candidate is the unchanged baseline")
    out = args.out.resolve()
    require(not out.exists() or not any(out.iterdir()), "authentication destination is not empty")
    out.mkdir(parents=True, exist_ok=True)
    records = {}
    for label, source, run_id, artifact_id, expected_bytes, expected_sha256 in (
        ("baseline", BASELINE_SOURCE, BASELINE_RUN, BASELINE_ARTIFACT,
         BASELINE_ZIP_BYTES, BASELINE_ZIP_SHA256),
        ("candidate", args.candidate_source, args.candidate_run, args.candidate_artifact,
         args.candidate_zip_bytes, args.candidate_zip_sha256),
    ):
        run, jobs = run_identity(run_id, source, initial_owner=label == "candidate")
        value, raw = artifact(run_id, source, artifact_id, "psc1-v2-dag-generated-js")
        require(len(raw) == expected_bytes and digest(raw) == expected_sha256,
                label + " artifact differs from the immutable qualification receipt")
        receipt = restore_bundle(raw, out / (label + ".zip"), out / label,
                                 source, run_id, run["run_attempt"], baseline=label == "baseline")
        receipt.update(artifact_id=value["id"], artifact_zip_sha256=digest(raw),
                       artifact_zip_bytes=len(raw), producer_run_attempt=run["run_attempt"],
                       required_jobs=[{"id": job["id"], "name": job["name"], "conclusion": job["conclusion"]}
                                      for job in jobs if job["name"] in
                                      ("native-dag-integration", "generated-dag-integration")])
        receipt["native_measurements"] = inspect_native_measurements(
            out, label, source, run_id, run["run_attempt"])
        records[label] = receipt
    result = {"format": "psc1-initial-owner-artifacts-v1", "repository": REPOSITORY,
              "workflow_source_sha": os.environ.get("GITHUB_SHA"), **records,
              "compiler_reexecuted": False, "canonical_rechecked": False,
              "new_kernel_qualification_established": False,
              "purpose": "Authenticate producer evidence before 32 fresh whole-call benchmark workers"}
    (out / "authentication.json").write_text(json.dumps(result, indent=2) + "\n")
    print("PSC1_INITIAL_OWNER_ARTIFACT_AUTHENTICATION " + json.dumps(result), flush=True)


if __name__ == "__main__":
    main()
