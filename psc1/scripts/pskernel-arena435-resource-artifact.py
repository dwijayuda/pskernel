#!/usr/bin/env python3
"""Restore one authenticated diagnostic runtime; never qualify a new source."""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import zipfile

SOURCE = "369bee5801bd5e4476837684fad3f7e1ca8c422c"
PRODUCER = "ab61efebac4e0b09cc3bf57c09380ae53ac2cf7f"
RUN = 39607734805
ARTIFACT = 12350649771
ZIP_SHA256 = "9ae05c3d0cd949f74a1a4c8a3a833b3fd755f1cb917897ab59552c9ce3aa90cc"
ZIP_BYTES = 14770339
ARENA_SHA256 = "98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d"
LEAN = {"version": "4.35.0", "githash": "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"}
FILES = ("kernel.js", "kernel.ts", "kernel.d.ts", "kernel.js.map")


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def restore(args: argparse.Namespace) -> None:
    raw = args.archive.read_bytes()
    require(len(raw) == ZIP_BYTES and digest(raw) == ZIP_SHA256,
            "immutable diagnostic artifact bytes differ")
    source = args.source.resolve(strict=True)
    require((source / "lean-toolchain").read_text().strip() == "leanprover/lean4:v4.35.0",
            "pinned checkout uses a different Lean toolchain")
    with zipfile.ZipFile(args.archive) as archive:
        names = [entry.filename for entry in archive.infolist() if not entry.is_dir()]
        require(len(names) == len(set(names)), "duplicate archive member names")
        require(all(not name.startswith("/") and ".." not in pathlib.PurePosixPath(name).parts
                    for name in names), "unexpected archive paths")

        def read(suffix: str) -> bytes:
            selected = [name for name in names if name == suffix or name.endswith("/" + suffix)]
            require(len(selected) == 1, "missing or ambiguous artifact member: " + suffix)
            return archive.read(selected[0])

        identity_lines = read("arena435-source-identities.txt").decode("utf-8").splitlines()
        require(len(identity_lines) == 2 and all("=" in line for line in identity_lines),
                "source identity record differs")
        identities = dict(line.split("=", 1) for line in identity_lines)
        require(identities == {"kernel_source_sha": SOURCE, "workflow_source_sha": PRODUCER},
                "artifact source identity differs")
        entries = {}
        for line in read("arena435-profile-artifacts.sha256").decode("utf-8").splitlines():
            expected, separator, path = line.partition("  ")
            require(separator == "  " and len(expected) == 64
                    and all(char in "0123456789abcdef" for char in expected),
                    "invalid compiler artifact digest record")
            require(path not in entries, "duplicate compiler artifact digest")
            entries[path] = expected
        require(set(entries) == {"dist/arena435-profile/" + name for name in FILES},
                "compiler artifact set differs")
        files = {}
        for name in FILES:
            data = read("kernel-source/psc1/dist/arena435-profile/" + name)
            require(data and digest(data) == entries["dist/arena435-profile/" + name],
                    "compiler artifact digest differs: " + name)
            files[name] = data

        baseline_bytes = read("arena435-authentic-profiles/report.json")
        baseline = json.loads(baseline_bytes)
        require(baseline.get("format") == "psc1-authentic-arena-diagnostics-v1"
                and baseline.get("source_sha") == SOURCE
                and baseline.get("workflow_source_sha") == PRODUCER
                and baseline.get("kernel_sha256") == digest(files["kernel.js"])
                and baseline.get("archive_sha256") == ARENA_SHA256
                and baseline.get("target_lean") == LEAN
                and baseline.get("kernel_fuel") == 4096
                and baseline.get("host_wall_seconds_per_case") == 60
                and baseline.get("node_old_space_limit_mib") == 2048
                and baseline.get("runtime_path_empty") is True
                and baseline.get("diagnostics_complete") is True
                and baseline.get("kernel_qualified") is False,
                "baseline source, toolchain, runtime or diagnostic contract differs")
        require(baseline.get("replay_sha256") ==
                digest((source / "scripts/pskernel-arena-replay.mjs").read_bytes()),
                "pinned replay differs from producer")
        require(len(baseline.get("cases", [])) == 4, "baseline is not the four authentic profiles")
        resource = json.loads(read("arena435-resource-profiles/report.json"))
        require(resource.get("source_sha") == SOURCE
                and resource.get("kernel_sha256") == digest(files["kernel.js"])
                and resource.get("archive_sha256") == ARENA_SHA256
                and resource.get("baseline_report_sha256") == digest(baseline_bytes)
                and resource.get("resource_policy_sha256") ==
                digest((source / "packages/pskernel-core/src/Ps/KernelCore/Checker/ResourcePolicy.lean").read_bytes()),
                "resource policy or producer report differs")

    args.out.mkdir(parents=True, exist_ok=True)
    for name, data in files.items():
        (args.out / name).write_bytes(data)
    args.baseline.parent.mkdir(parents=True, exist_ok=True)
    args.baseline.write_bytes(baseline_bytes)
    receipt = {
        "format": "psc1-authenticated-resource-artifact-replay-v1",
        "source_sha": SOURCE, "producer_source_sha": PRODUCER,
        "producer_run": RUN, "artifact_id": ARTIFACT,
        "artifact_zip_sha256": ZIP_SHA256, "artifact_zip_bytes": ZIP_BYTES,
        "lean": LEAN, "producer_typescript": "7.0.2",
        "producer_generated_route": "complete checked canonical .ps closure",
        "files": [{"name": name, "bytes": len(data), "sha256": digest(data)}
                  for name, data in files.items()],
        "baseline_report_sha256": digest(baseline_bytes),
        "source_artifact_diagnostic_incomplete": resource.get("diagnostics_complete") is not True,
        "compiler_reexecuted_in_this_run": False,
        "canonical_rechecked_in_this_run": False,
        "kernel_qualified": False,
        "note": "Artifact authentication establishes executable identity only. Fresh controls and resource replay follow."
    }
    args.receipt.parent.mkdir(parents=True, exist_ok=True)
    args.receipt.write_text(json.dumps(receipt, indent=2) + "\n")
    print("PSC1_AUTHENTICATED_RESOURCE_RUNTIME " + json.dumps(receipt), flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("archive", "source", "out", "baseline", "receipt"):
        parser.add_argument("--" + name, type=pathlib.Path, required=True)
    restore(parser.parse_args())


if __name__ == "__main__":
    main()
