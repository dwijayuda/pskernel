"""Bind the retained kernel suite to the production validator/decoder proofs.

This is qualification tooling; it never checks a declaration on behalf of the
kernel and never changes the generated runtime's resource policy.
"""
import hashlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys

SPECS = [
    ("PsKernelExprV2ReplayMetadataProofs", 4, "replay.lean"),
    ("PsKernelExprV2SemanticPrefixProofs", 8, "prefix.lean"),
    ("PsKernelExprV2DecodedNodeProofs", 2, "node.lean"),
    ("PsKernelExprV2DecodedBridgeProofs", 12, "bridge.lean"),
    ("PsKernelExprV2ArenaModelBridgeProofs", 7, "arena-model-bridge.lean"),
]
PINS = {'psc1/test/PsKernelExprV2ReplayMetadataProofs.lean': 'bcf3abfdb5d2cee6513ff7db81000fcf8dd6accb16bf9b4761280f08acd20e46', 'psc1/test/PsKernelExprV2SemanticPrefixProofs.lean': '358dedf8b06be615d2f86ea3738d91b19966469f72dc33c77047e1af7136ea6e', 'psc1/test/PsKernelExprV2DecodedNodeProofs.lean': '0720db5abc1922656c47d1f2b251efa9f4b23fafc8d12932dbaec0a822a25d27', 'psc1/test/PsKernelExprV2DecodedBridgeProofs.lean': 'c97baa13eea76cd5ef5076a4277f517a1748014ee3a49d06f4b5ef68765085b3', 'psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Builder.lean': '2a990e8a1b23ed0f77ef3eb97e2ab53a151b15c846abdea6543bf3591faebae5', 'psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Decode.lean': 'efa439588f6b4b80eb6ab25c8311fa221d74971f7e8ad572abd4a6aa57b77d5e', 'psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Node.lean': '2257f156a0b713802ada3b0397b92db747cea44477b767224a9eec494d3e895d', 'psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Paged.lean': '831715847d992c39f7414c70bc3e06b466032ff6d44556dc552a264c2f5c865f', 'psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Validation.lean': '8cd60dd58013caef61b398e08ab3797343efac60a82b01f2906f76da06439089', 'psc1/test/PsKernelExprV2MetadataProofs.lean': '5c5e14cbdf9aa890640d3dfeb69dcda651aab7cbbfb9da527e500e48daaf1d20', 'psc1/test/PsKernelExprV2PagedModelProofs.lean': 'a6b4784e751e1f9fe1cafa8188cefbe413a987bf1e7114f23d5defd7a9040be8', 'psc1/test/PsKernelExprV2ArenaModelBridgeProofs.lean': '2699f6a6bd9d8d0d793a8eb2d398293f43255d79bd8f5c84d1033be393d72af3', 'psc1/test/PsKernelOrdinaryOccurrenceProofs.lean': 'd5140dd507ff7c456d89d7ba08e625d0b72e345e28ae024ab6dc85872104d351'}
PRODUCTION_TREE = "62d48691ff7d9680878cf668862017d1061f2ebd"
RETAINED_LAYERS = [
    "constructor-native-receipt.json", "fields-native-receipt.json",
    "analysis-native-receipt.json", "loop-native-receipt.json",
    "ordinary-admission-native-receipt.json", "deferred-transform-native-receipt.json",
    "retained-native-receipt.json", "layout-boundary-native-receipt.json",
    "empty-semantic-cache-native-receipt.json",
]
SCRIPT = "psc1/scripts/pskernel-validator-qualification.py"
WORKFLOW = ".github/workflows/psc1-pskernel-t05-header.yml"
ALLOWED = {"propext", "Classical.choice", "Quot.sound"}


def require(ok, message):
    if not ok:
        raise RuntimeError(message)


def digest(path):
    raw = path.read_bytes()
    return {"bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}


def read(path):
    return json.loads(path.read_text())


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def identity():
    return {"sourceSha": os.environ["GITHUB_SHA"],
            "runId": os.environ["GITHUB_RUN_ID"],
            "runAttempt": os.environ["GITHUB_RUN_ATTEMPT"]}


def reports(path, names):
    text = path.read_text()
    found = re.findall(r"'([^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)", text)
    require([name for name, _ in found] == names, "Ordered actual reports: " + str(path))
    require(not re.search(r"\.lean:\d+:\d+: error:", text), "Proof diagnostics: " + str(path))
    require(not any(token in text for token in ["sorryAx", "Lean.ofReduceBool", "Lean.trustCompiler"]),
            "Forbidden proof dependency: " + str(path))
    for name, used in found:
        require({a.strip() for a in used.split(",") if a.strip()} <= ALLOWED,
                "Unapproved axiom: " + name)


def authenticate(repo, out):
    out.mkdir(parents=True, exist_ok=True)
    require(subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
            == identity()["sourceSha"], "Exact checked-out source")
    require(subprocess.check_output(["git", "rev-parse", "HEAD:psc1/packages/pskernel-core/src"],
                                    cwd=repo, text=True).strip() == PRODUCTION_TREE,
            "Exact pinned candidate production tree")
    paths = list(PINS) + [SCRIPT, WORKFLOW]
    rows = []
    for name in paths:
        path = repo / name
        raw = path.read_bytes()
        require(raw == subprocess.check_output(["git", "show", "HEAD:" + name], cwd=repo),
                "Worktree/Git byte identity: " + name)
        if name in PINS:
            require(hashlib.sha256(raw).hexdigest() == PINS[name], "Retained proof/production pin: " + name)
        target = out / "sources" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw)
        rows.append({"path": name, **digest(path)})
    record = {"schema": "psc1-validator-source-v1", **identity(),
              "isolatedProofSource": "e652d02a69ebcaaeb5b4fe0b391e368efebf18e7",
              "arenaModelProofSource": "150123e5fb8e17d8fab4d737a043705727ee1bcc",
              "productionSource": "dbd9db47bd8ef184583bcd5ae3feb38f3ce612c5",
              "productionTree": PRODUCTION_TREE, "files": rows}
    write(out / "source-inventory.json", record)
    return record


def verify_sources(repo, out):
    record = read(out / "source-inventory.json")
    require(all(record[k] == v for k, v in identity().items()), "Proof inventory identity")
    require([r["path"] for r in record["files"]] == list(PINS) + [SCRIPT, WORKFLOW],
            "Exact ordered companion source inventory")
    for row in record["files"]:
        expected = {"bytes": row["bytes"], "sha256": row["sha256"]}
        require(digest(repo / row["path"]) == expected == digest(out / "sources" / row["path"]),
                "Proof input changed: " + row["path"])


def native(repo, root):
    out = root / "validator"
    authenticate(repo, out)
    require(subprocess.check_output(["lean", "--githash"], cwd=repo / "psc1", text=True).strip()
            == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc", "Pinned Lean")
    subprocess.run(["lake", "-f", "kernel-lakefile.lean", "build",
                    "Ps.KernelCore.Core.ExprV2.Decode"], cwd=repo / "psc1", check=True)
    records = []
    statuses = []
    for module, count, _ in SPECS:
        source = repo / "psc1/test" / (module + ".lean")
        names = re.findall(r"(?m)^#print axioms (\S+)\s*$", source.read_text())
        names = [name if "." in name else module + "." + name for name in names]
        require(len(names) == len(set(names)) == count, "Fixed proof inventory: " + module)
        command = ["lake", "-f", "kernel-lakefile.lean", "env", "lean", "--root=test",
                   "-o", ".lake/build/lib/lean/" + module + ".olean", "test/" + module + ".lean"]
        log = out / (module + ".log")
        with log.open("w") as handle:
            status = subprocess.run(command, cwd=repo / "psc1", stdout=handle,
                                    stderr=subprocess.STDOUT).returncode
        print(log.read_text(), end="", flush=True)
        statuses.append({"module": module, "count": count, "exitCode": status})
        write(out / "proof-status.json", statuses)
        require(status == 0, "Native proof failed: " + module)
        reports(log, names)
        records.append({"module": module, "proofs": count, "names": names,
                        "source": digest(source), "log": digest(log)})
    prior_records = []
    layers = {}
    for name in RETAINED_LAYERS:
        receipt = read(root / name)
        require(all(receipt[k] == v for k, v in identity().items()) and receipt["status"] == "pass",
                "Retained receipt identity/status: " + name)
        prior_records.extend(receipt["proofs"])
        layers[name] = digest(root / name)
    prior_names = [name for row in prior_records for name in row["names"]]
    require(len(prior_records) == 31 and len(prior_names) == len(set(prior_names)) == 499,
            "All 499 retained reports, without duplicates")
    logs = list(root.glob("*.log"))
    for row in prior_records:
        source = repo / "psc1/test" / (row["module"] + ".lean")
        require(digest(source) == row["source"], "Retained proof source: " + row["module"])
        matches = [path for path in logs if digest(path) == row["log"]]
        require(len(matches) == 1, "Unique actual retained log: " + row["module"])
        reports(matches[0], row["names"])
    all_records = prior_records + records
    names = [name for row in all_records for name in row["names"]]
    require(len(all_records) == len({r["module"] for r in all_records}) == 36,
            "36 distinct native proof modules")
    require(len(names) == len(set(names)) == sum(r["proofs"] for r in all_records) == 532,
            "532 distinct actual native reports")
    verify_sources(repo, out)
    receipt = {"schema": "psc1-validator-native-v1", **identity(), "status": "pass",
               "retainedProofs": 499, "newProofs": 33, "totalProofs": 532,
               "proofModules": 36, "proofs": all_records, "retainedLayers": layers,
               "sourceInventory": digest(out / "source-inventory.json"),
               "proofStatuses": digest(out / "proof-status.json"),
               "productionTree": PRODUCTION_TREE, "productionChanges": ["psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/FullShape.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/UnarySpines.lean"],
               "metadataCorrespondenceEstablished": True, "decoderCorrespondenceEstablished": True,
               "untrustedSourceValidityAssumed": False, "replayArenaModelBridgeEstablished": True,
               "fullKernel": False, "performanceQualified": False}
    write(out / "native-receipt.json", receipt)
    print("PSC1_VALIDATOR_NATIVE532: PASS " + json.dumps(receipt, separators=(",", ":")))


def route(repo, root, native_root):
    native_out = native_root / "validator"
    verify_sources(repo, native_out)
    proof = read(native_out / "native-receipt.json")
    require(all(proof[k] == v for k, v in identity().items()) and proof["status"] == "pass",
            "Same-source native proof result")
    require((proof["retainedProofs"], proof["newProofs"], proof["totalProofs"], proof["proofModules"])
            == (499, 33, 532, 36), "Complete native inventory")
    require(proof["sourceInventory"] == digest(native_out / "source-inventory.json"),
            "Native source inventory digest")
    require(proof["proofStatuses"] == digest(native_out / "proof-status.json"), "Native command statuses")
    for name, expected in proof["retainedLayers"].items():
        require(digest(native_root / name) == expected, "Native layer byte binding")
    for module, _, _ in SPECS:
        row = next(r for r in proof["proofs"] if r["module"] == module)
        log = native_out / (module + ".log")
        require(digest(log) == row["log"], "Companion proof log byte binding")
        reports(log, row["names"])
    runtime = read(root / "empty-semantic-cache-receipt.json")
    provenance = read(root / "provenance.json")
    require(runtime["status"] == "pass" and runtime["identity"] == provenance, "Complete retained route")
    require(all(provenance[k] == v for k, v in identity().items()), "Exact runtime/proof source identity")
    require(provenance["route"] == os.environ["PSC1_T05_ROUTE"] in ["generated", "canonical"],
            "Supported complete route")
    require(provenance["fuel"] == 4096 and provenance["oldSpaceMiB"] == 2048
            and provenance["emptyPATH"] is True, "Unchanged runtime resource policy")
    require(digest(root / "detached/kernel.mjs") == provenance["kernel"], "Executed kernel binding")
    for name, expected in runtime["logs"].items():
        require(digest(root / name) == expected, "Retained runtime log unchanged")
    out = root / "validator"
    shutil.copytree(native_out, out)
    receipt = {"schema": "psc1-validator-route-v1", **identity(), "status": "pass",
               "route": provenance["route"], "nativeProofs": 532,
               "nativeReceipt": digest(out / "native-receipt.json"),
               "retainedRouteReceipt": digest(root / "empty-semantic-cache-receipt.json"),
               "kernel": provenance["kernel"], "productionChanges": ["psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/FullShape.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/UnarySpines.lean"],
               "metadataCorrespondenceEstablished": True, "decoderCorrespondenceEstablished": True,
               "replayArenaModelBridgeEstablished": True, "fullKernel": False,
               "performanceQualified": False}
    write(out / "route-receipt.json", receipt)
    print("PSC1_VALIDATOR_ROUTE532: PASS " + json.dumps(receipt, separators=(",", ":")))


if __name__ == "__main__":
    command = sys.argv[1]
    repo = pathlib.Path(sys.argv[2]).resolve()
    root = pathlib.Path(sys.argv[3]).resolve()
    if command == "native":
        native(repo, root)
    elif command == "route":
        route(repo, root, pathlib.Path(sys.argv[4]).resolve())
    else:
        raise RuntimeError("Unknown command")
