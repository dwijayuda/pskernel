#!/usr/bin/env python3
"""Read-only CI evidence transport and independently recomputed source-roster checks."""
import collections
import hashlib
import importlib.util
import json
import pathlib
import re
import sys

def main():
    mode, value = sys.argv[1:]
    path = pathlib.Path(value)
    if mode == "bootstrap-source":
        raw = path.read_bytes()
        text = raw.decode("utf-8")
        print("PSC0_CORE_BOOTSTRAP_ASSET " + json.dumps({
            "bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest(),
            "gitBlobSHA1": hashlib.sha1(
                b"blob " + str(len(raw)).encode("ascii") + b"\0" + raw).hexdigest()
        }, sort_keys=True))
        # Only the small independently admitted bootstrap source is transported.
        # Larger raw audit/candidate files remain complete Actions artifacts.
        for start in range(0, len(text), 2048):
            print("PSC0_CORE_BOOTSTRAP_SOURCE " + json.dumps(text[start:start + 2048]))
    elif mode == "native-closure":
        report = json.loads(path.read_text(encoding="utf-8"))
        script = pathlib.Path(__file__).with_name("core-first-source-audit.py")
        spec = importlib.util.spec_from_file_location("core_source_audit", script)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        source = module.audit(pathlib.Path(__file__).resolve().parents[2])
        expected = set(source["portableCompiler"]["modules"])
        actual = {item["display"] for item in report["sourceModules"]}
        if actual != expected or len(report["sourceModules"]) != len(actual):
            raise ValueError("native source module owners disagree with source imports: " +
                             repr({"missing": sorted(expected - actual),
                                   "extra": sorted(actual - expected)}))
        names = {json.dumps(item["name"]["parts"], sort_keys=True)
                 for item in report["closureDeclarations"]}
        if len(names) != report["closureDeclarationCount"]:
            raise ValueError("native closure declaration roster is duplicate or incomplete")
        for item in report["closureDeclarations"]:
            for dependency in item["dependencies"]:
                if json.dumps(dependency["parts"], sort_keys=True) not in names:
                    raise ValueError("native closure has an open dependency edge")
        # Preserve concrete raw assumption paths without treating a graph path
        # as an erasure proof or authorizing executable Classical.choice.
        key = lambda name: json.dumps(name["parts"], sort_keys=True)
        entries = {key(item["name"]): item for item in report["closureDeclarations"]}
        reverse = collections.defaultdict(list)
        for parent_key, item in entries.items():
            for dependency in item["dependencies"]:
                child_key = key(dependency)
                edge_kinds = [
                    field for field in ("typeDependencies", "valueDependencies",
                                        "familyOrRuleDependencies")
                    if any(key(node) == child_key for node in item[field])]
                reverse[child_key].append((parent_key, edge_kinds))
        witnesses = {key(item["root"]): item for item in report["rootWitnesses"]}
        assumption_paths = []
        for axiom in report["axioms"]:
            initial = key(axiom["name"])
            queue = collections.deque([initial])
            previous = {initial: None}
            while queue:
                child = queue.popleft()
                for parent, kinds in reverse[child]:
                    if parent not in previous:
                        previous[parent] = (child, kinds)
                        queue.append(parent)
            affected = sorted(set(previous).intersection(witnesses),
                              key=lambda node: entries[node]["name"]["display"])
            samples = []
            for root_key in affected[:8]:
                chain = []
                node = root_key
                while True:
                    item = entries[node]
                    hop = {"name": item["name"], "kind": item["kind"]}
                    following = previous[node]
                    if following is not None:
                        hop["dependencyEdges"] = following[1]
                    chain.append(hop)
                    if following is None:
                        break
                    node = following[0]
                samples.append({"sourceWitness": witnesses[root_key], "path": chain})
            assumption_paths.append({
                "axiom": axiom["name"], "affectedExternalRoots": len(affected),
                "sampleLimit": 8, "samples": samples})
        assumptions = {
            "schema": "psc0-core-native-assumption-paths/1",
            "nativeCommit": report["leanCommit"], "sourceHead": source["head"],
            "nativeClosureSHA256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "scope": "Raw type, value and family edges; bounded shortest path samples",
            "runtimeChoiceQualified": False, "candidateKernelAdmitted": False,
            "assumptions": assumption_paths}
        path.with_name("native-assumption-paths.json").write_text(
            json.dumps(assumptions, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        print("PSC0_CORE_NATIVE_ASSUMPTION_PATHS " +
              json.dumps(assumptions, sort_keys=True))
        print("PSC0_CORE_NATIVE_ROSTER_MATCH " + json.dumps({
            "sourceModules": len(actual), "sourceHead": source["head"],
            "nativeClosureDeclarations": len(names),
            "nativeClosureSHA256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "sourceParityClaim": False, "candidateKernelAdmitted": False
        }, sort_keys=True))
    elif mode == "bootstrap-compatibility":
        raw = path.read_bytes()
        report = json.loads(raw)
        if (len(raw) > 256000 or report.get("candidate") != "Bootstrap" or
                report.get("candidateDeclarations") != 76 or
                len(report.get("comparisons", [])) != 76):
            raise ValueError("unexpected Bootstrap comparison report scope")
        print("PSC0_CORE_BOOTSTRAP_COMPATIBILITY " +
              json.dumps(report, sort_keys=True))
    elif mode == "resources":
        observations = []
        for item in sorted(path.glob("*resource.txt")):
            fields = {}
            for line in item.read_text(encoding="utf-8").splitlines():
                match = re.match(r"^\s*(.+): (.*)$", line)
                if match:
                    fields[match.group(1)] = match.group(2)
            observations.append({"file": item.name, "gnuTime": fields})
        files = [{"file": item.name, "bytes": item.stat().st_size,
                  "sha256": hashlib.sha256(item.read_bytes()).hexdigest()}
                 for item in sorted(path.glob("Core*Candidate.lean"))]
        summary = {"schema": "psc0-core-ci-resource-observations/1",
                   "scope": "actual commands; not a complete Core release or performance claim",
                   "resources": observations, "generatedSources": files}
        path.mkdir(parents=True, exist_ok=True)
        (path / "resource-summary.json").write_text(
            json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        print("PSC0_CORE_RESOURCE_OBSERVATIONS " + json.dumps(summary, sort_keys=True))
    else:
        raise ValueError("unknown evidence mode: " + mode)

if __name__ == "__main__":
    main()
