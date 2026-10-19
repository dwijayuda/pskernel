#!/usr/bin/env python3
"""Read-only CI evidence transport and independently recomputed source-roster checks."""
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
        print("PSC0_CORE_NATIVE_ROSTER_MATCH " + json.dumps({
            "sourceModules": len(actual), "sourceHead": source["head"],
            "nativeClosureDeclarations": len(names),
            "nativeClosureSHA256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "sourceParityClaim": False, "candidateKernelAdmitted": False
        }, sort_keys=True))
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
