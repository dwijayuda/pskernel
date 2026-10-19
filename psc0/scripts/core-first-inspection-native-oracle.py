#!/usr/bin/env python3
"""Run the actual pinned native commands emitted by Pscv0CoreInspection."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

PIN_VERSION = "4.35.0"
PIN_GITHASH = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
TIMEOUT_SECONDS = 45


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    require(len(sys.argv) == 2, "expected native-fixtures.json")
    manifest_path = Path(sys.argv[1]).resolve()
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    require(manifest.get("schema") == "psc0-core-inspection-native-fixtures/1",
            "wrong inspection fixture schema")
    require(manifest.get("nativeVersion") == PIN_VERSION
            and manifest.get("nativeCommit") == PIN_GITHASH,
            "fixture values were not produced by the official pin")
    fixtures = manifest["cases"]
    require(len(fixtures) == 18, "expected 18 native command fixtures")
    require(len({case["name"] for case in fixtures}) == len(fixtures),
            "duplicate native fixture identity")
    output = manifest_path.parent / "native"
    output.mkdir(parents=True, exist_ok=True)
    run_dir = Path(tempfile.mkdtemp(prefix="run-", dir=output))
    report = {
        "schema": "psc0-core-inspection-native-oracle/1",
        "status": "RUNNING",
        "source_revision": os.environ.get("GITHUB_SHA"),
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "fixture_sha256": digest(manifest_path),
        "commands": [],
        "cases": [],
    }

    def invoke(tag, argv, env):
        started = time.monotonic()
        record = {"tag": tag, "argv": [str(arg) for arg in argv],
                  "returncode": None, "timed_out": False}
        report["commands"].append(record)
        stdout = b""
        stderr = b""
        try:
            result = subprocess.run(record["argv"], cwd=run_dir, env=env,
                                    capture_output=True, timeout=TIMEOUT_SECONDS,
                                    check=False)
            stdout, stderr = result.stdout, result.stderr
            record["returncode"] = result.returncode
            return result
        except subprocess.TimeoutExpired as exc:
            stdout, stderr = exc.stdout or b"", exc.stderr or b""
            record["timed_out"] = True
            raise RuntimeError(f"{tag}: exceeded {TIMEOUT_SECONDS} seconds") from exc
        finally:
            (run_dir / f"{tag}.stdout").write_bytes(stdout)
            (run_dir / f"{tag}.stderr").write_bytes(stderr)
            record["elapsed_seconds"] = round(time.monotonic() - started, 3)

    def probe(tag, argv, env):
        result = invoke(tag, argv, env)
        require(result.returncode == 0 and result.stderr == b"",
                f"{tag}: toolchain probe failed")
        lines = result.stdout.decode("utf-8").strip().splitlines()
        require(len(lines) == 1, f"{tag}: expected one probe line")
        return lines[0]

    try:
        inherited = dict(os.environ)
        launcher = shutil.which("lean")
        require(launcher is not None, "lean not found; launch through lake env")
        prefix = probe("prefix", [launcher, "--print-prefix"], inherited)
        lean = Path(prefix) / "bin" / "lean"
        require(lean.is_absolute() and lean.is_file(), "native binary missing")
        env = dict(inherited)
        env["LEAN_PATH"] = str(run_dir)
        version = probe("version", [lean, "--short-version"], env)
        githash = probe("githash", [lean, "--githash"], env)
        report.update(native_version=version, native_commit=githash,
                      lean_binary=str(lean), lean_path=env["LEAN_PATH"])
        require(version == PIN_VERSION and githash == PIN_GITHASH,
                "native toolchain identity mismatch")
        for fixture in fixtures:
            name = fixture["name"]
            require(re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", name) is not None,
                    "invalid native module name")
            source_path = run_dir / f"{name}.lean"
            object_path = run_dir / f"{name}.olean"
            source_path.write_text(fixture["source"], encoding="utf-8")
            case = {"name": name, "status": "FAIL",
                    "source_sha256": digest(source_path),
                    "expected_messages": fixture["messages"],
                    "expected_errors": fixture["errors"]}
            report["cases"].append(case)
            result = invoke(name, [lean, "--json", f"--root={run_dir}",
                                   "-o", object_path.name, source_path.name], env)
            require(result.stderr == b"", f"{name}: unexpected native stderr")
            diagnostics = [json.loads(line) for line in
                           result.stdout.decode("utf-8").splitlines() if line.strip()]
            require(all(isinstance(item, dict)
                        and item.get("severity") in ("information", "warning", "error")
                        and isinstance(item.get("data"), str) for item in diagnostics),
                    f"{name}: malformed native JSON diagnostic")
            case.update(returncode=result.returncode, diagnostics=diagnostics)
            errors = [item for item in diagnostics if item["severity"] == "error"]
            information = [item for item in diagnostics if item["severity"] == "information"]
            for item in diagnostics:
                require(Path(item.get("fileName", "")).name == source_path.name,
                        f"{name}: native diagnostic belongs to another source")
            if fixture["errors"]:
                require(result.returncode == 1 and len(errors) == 1,
                        f"{name}: expected exactly one native refusal")
                require(all(part in errors[0]["data"] for part in fixture["errors"]),
                        f"{name}: wrong native refusal owner")
                require(not list(run_dir.glob(f"{name}.olean*")),
                        f"{name}: refused source emitted an object")
            else:
                require(result.returncode == 0 and not errors,
                        f"{name}: expected native command success")
                require(not any(item.get("kind") == "hasSorry"
                                or "declaration uses `sorry`" in item["data"]
                                for item in diagnostics),
                        f"{name}: accepted source contains a proof hole")
                require(object_path.is_file() and object_path.stat().st_size > 0,
                        f"{name}: native compilation produced no object")
                expected = fixture["messages"]
                require(len(information) == len(expected),
                        f"{name}: native command diagnostic count differs")
                for item, wanted in zip(information, expected):
                    data = item["data"]
                    exact = wanted.get("exactText")
                    require(exact is None or data == exact,
                            f"{name}: native exact message differs: {data!r}")
                    require(all(part in data for part in wanted.get("fragments", [])),
                            f"{name}: native message lost selected content")
                    require(not any(part in data for part in wanted.get("absent", [])),
                            f"{name}: native message violates the selected boundary")
            case["status"] = "PASS"
            print(f"CORE-INSPECTION native PASS {name}", flush=True)
        report["successful_compilations"] = sum(not item["errors"] for item in fixtures)
        report["expected_refusals"] = sum(bool(item["errors"]) for item in fixtures)
        report["status"] = "PASS"
    except Exception as exc:
        report["status"] = "FAIL"
        report["failure"] = f"{type(exc).__name__}: {exc}"
        print("CORE-INSPECTION native FAIL: " + report["failure"], file=sys.stderr, flush=True)
    finally:
        report["finished_utc"] = datetime.now(timezone.utc).isoformat()
        report["artifacts"] = [
            {"path": str(path.relative_to(run_dir)), "bytes": path.stat().st_size,
             "sha256": digest(path)}
            for path in sorted(run_dir.rglob("*")) if path.is_file()]
        payload = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
        (run_dir / "report.json").write_text(payload, encoding="utf-8")
        (output / "report.json").write_text(payload, encoding="utf-8")
    if report["status"] != "PASS":
        return 1
    print("PSCV0_CORE_INSPECTION_NATIVE: PASS " +
          str(report["successful_compilations"]) + " native sources and " +
          str(report["expected_refusals"]) + " owned native refusals", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
