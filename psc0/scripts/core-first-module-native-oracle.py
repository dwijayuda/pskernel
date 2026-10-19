#!/usr/bin/env python3
"""Pinned native module-kind and exported-body conformance oracle."""

from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import textwrap
import time

PIN_VERSION = "4.35.0"
PIN_GITHASH = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
TIMEOUT_SECONDS = 45
PSC0 = Path(__file__).resolve().parents[1]
OUTPUT = PSC0 / "dist" / "core-first" / "seams" / "module-native-oracle"
KIND_ERROR = ("cannot import non-`module` LegacyProvider from `module`",)
BODY_ERROR = ("Tactic `rfl` failed", "not definitionally equal", "coreBodyOpaque")


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source(text):
    return textwrap.dedent(text).lstrip()


def kind_client(provider, module, public_import=False):
    header = "module\n" if module else ""
    import_prefix = "public " if public_import else ""
    declaration_prefix = "public " if module else ""
    return (
        f"{header}{import_prefix}import {provider}\n\n"
        f"{declaration_prefix}def coreKindUse "
        "(A : Type) (x : A) : A := coreKindValue A x\n"
    )


def cases():
    identity = "def coreKindValue (A : Type) (x : A) : A := x\n"
    return [
        ("LegacyProvider", identity, ()),
        ("ModuleProvider", "module\n\npublic " + identity, ()),
        ("ModuleToModule", kind_client("ModuleProvider", True), ()),
        ("ModuleToLegacy", kind_client("LegacyProvider", True), KIND_ERROR),
        ("LegacyToModule", kind_client("ModuleProvider", False), ()),
        ("LegacyToLegacy", kind_client("LegacyProvider", False), ()),
        ("PublicModuleToModule", kind_client("ModuleProvider", True, True), ()),
        ("PublicModuleToLegacy", kind_client("LegacyProvider", True, True), KIND_ERROR),
        ("ModuleImportOnlyLegacy", "module\nimport LegacyProvider\n", KIND_ERROR),
        ("BodyProvider", source("""
            module

            public def coreBodyOpaque (A : Type) (x : A) : A := x
            public abbrev coreBodyExposed (A : Type) (x : A) : A := x

            public theorem coreBodySpec (A : Type) (x : A) :
                coreBodyOpaque A x = x := by
              rfl
            """), ()),
        ("BodyClientGood", source("""
            module
            public import BodyProvider

            public theorem coreBodyProof (A : Type) (x : A) :
                coreBodyExposed A x = x := by
              rfl

            public theorem coreBodyViaSpec (A : Type) (x : A) :
                coreBodyOpaque A x = x :=
              coreBodySpec A x
            """), ()),
        ("BodyClientHiddenRfl", source("""
            module
            public import BodyProvider

            public theorem coreBodyForbidden (A : Type) (x : A) :
                coreBodyOpaque A x = x := by
              rfl
            """), BODY_ERROR),
    ]


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    run_dir = Path(tempfile.mkdtemp(prefix="run-", dir=OUTPUT))
    inherited_env = dict(os.environ)
    report = {
        "schema": "psc0-core-module-native-oracle/1",
        "status": "RUNNING",
        "started_utc": utc_now(),
        "source_revision": os.environ.get("GITHUB_SHA"),
        "required_version": PIN_VERSION,
        "required_githash": PIN_GITHASH,
        "run_directory": str(run_dir),
        "commands": [],
        "cases": [],
    }
    (OUTPUT / "report.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )

    def invoke(tag, argv, cwd, env):
        stdout_path = run_dir / f"{tag}.stdout"
        stderr_path = run_dir / f"{tag}.stderr"
        record = {
            "tag": tag,
            "argv": [str(arg) for arg in argv],
            "cwd": str(cwd),
            "stdout": stdout_path.name,
            "stderr": stderr_path.name,
            "returncode": None,
            "timed_out": False,
        }
        report["commands"].append(record)
        started = time.monotonic()
        stdout = b""
        stderr = b""
        failure = None
        completed = None
        try:
            completed = subprocess.run(
                record["argv"], cwd=cwd, env=env, capture_output=True,
                timeout=TIMEOUT_SECONDS, check=False,
            )
            stdout = completed.stdout
            stderr = completed.stderr
            record["returncode"] = completed.returncode
        except subprocess.TimeoutExpired as exc:
            stdout = exc.stdout or b""
            stderr = exc.stderr or b""
            record["timed_out"] = True
            failure = f"{tag}: exceeded {TIMEOUT_SECONDS} seconds"
        except OSError as exc:
            failure = f"{tag}: could not launch compiler: {exc}"
        finally:
            stdout_path.write_bytes(stdout)
            stderr_path.write_bytes(stderr)
            record["elapsed_seconds"] = round(time.monotonic() - started, 3)
        if failure is not None:
            record["failure"] = failure
            raise RuntimeError(failure)
        return completed

    def probe(tag, argv, cwd, env):
        completed = invoke(tag, argv, cwd, env)
        require(completed.returncode == 0, f"{tag}: expected exit 0; see captured logs")
        require(completed.stderr == b"", f"{tag}: unexpected stderr")
        lines = completed.stdout.decode("utf-8").strip().splitlines()
        require(len(lines) == 1, f"{tag}: expected one output line")
        return lines[0]

    try:
        launcher = shutil.which("lean")
        require(launcher is not None, "lean not found; launch through lake env")
        # Resolve through sysroot, not through an elan symlink's argv[0].
        prefix = probe("toolchain-prefix", [launcher, "--print-prefix"],
                       Path.cwd(), inherited_env)
        lean = Path(prefix) / "bin" / "lean"
        require(lean.is_absolute() and lean.is_file(), f"native Lean binary missing: {lean}")
        env = dict(inherited_env)
        # Lean appends its builtin sysroot library after this fixture-only path.
        env["LEAN_PATH"] = str(run_dir)
        report["lean_binary"] = str(lean)
        report["lean_path"] = env["LEAN_PATH"]
        report["source_root"] = str(run_dir)
        version = probe("toolchain-version", [lean, "--short-version"], run_dir, env)
        githash = probe("toolchain-githash", [lean, "--githash"], run_dir, env)
        report["actual_version"] = version
        report["actual_githash"] = githash
        require(version == PIN_VERSION, f"wrong Lean version: {version!r}")
        require(githash == PIN_GITHASH, f"wrong Lean commit: {githash!r}")
        fixtures = cases()
        require(len(fixtures) == 12, "oracle must contain 12 compile cases")
        require(sum(not expected for _, _, expected in fixtures) == 8,
                "oracle must contain eight expected successful compilations")

        for name, contents, expected_errors in fixtures:
            input_path = run_dir / f"{name}.lean"
            output_path = run_dir / f"{name}.olean"
            input_path.write_text(contents, encoding="utf-8")
            case = {
                "name": name,
                "expectation": "refusal" if expected_errors else "acceptance",
                "expected_error_substrings": list(expected_errors),
                "source": input_path.name,
                "source_sha256": sha256(input_path),
                "command_tag": name,
                "status": "FAIL",
            }
            report["cases"].append(case)
            completed = invoke(
                name, [lean, "--json", f"--root={run_dir}", "-o",
                       output_path.name, input_path.name], run_dir, env,
            )
            case["returncode"] = completed.returncode
            case["olean_artifacts"] = sorted(
                path.name for path in run_dir.glob(f"{name}.olean*")
            )
            require(completed.stderr == b"", f"{name}: unexpected stderr")
            diagnostics = []
            for line in completed.stdout.decode("utf-8").splitlines():
                if not line.strip():
                    continue
                item = json.loads(line)
                require(
                    isinstance(item, dict)
                    and item.get("severity") in ("information", "warning", "error")
                    and isinstance(item.get("data"), str),
                    f"{name}: malformed native JSON diagnostic",
                )
                diagnostics.append(item)
            case["diagnostics"] = diagnostics
            errors = [item for item in diagnostics if item["severity"] == "error"]
            if expected_errors:
                require(completed.returncode == 1, f"{name}: refusal must exit exactly 1")
                require(len(errors) == 1,
                        f"{name}: expected one native error, received {len(errors)}")
                error = errors[0]
                filename = error.get("fileName")
                require(isinstance(filename, str) and Path(filename).name == input_path.name,
                        f"{name}: error did not originate in this fixture")
                require(all(fragment in error["data"] for fragment in expected_errors),
                        f"{name}: wrong semantic refusal; see diagnostics")
                require(not case["olean_artifacts"],
                        f"{name}: rejected source emitted an .olean artifact")
            else:
                require(completed.returncode == 0 and not errors,
                        f"{name}: expected successful native compilation")
                require(not any("declaration uses 'sorry'" in item["data"]
                                for item in diagnostics),
                        f"{name}: native compilation reported a proof hole")
                require(output_path.is_file() and output_path.stat().st_size > 0,
                        f"{name}: successful compilation emitted no .olean")
            case["status"] = "PASS"
            print(f"PASS {name}: {case['expectation']}", flush=True)

        report["status"] = "PASS"
        report["successful_compilations"] = 8
        report["expected_refusals"] = 4
    except Exception as exc:
        report["status"] = "FAIL"
        report["failure"] = f"{type(exc).__name__}: {exc}"
        print(f"PSCV0_CORE_MODULE_NATIVE_ORACLE: FAIL: {report['failure']}",
              file=sys.stderr, flush=True)
    finally:
        report["finished_utc"] = utc_now()
        report["artifacts"] = [
            {"path": str(path.relative_to(run_dir)), "bytes": path.stat().st_size,
             "sha256": sha256(path)}
            for path in sorted(run_dir.rglob("*")) if path.is_file()
        ]
        payload = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
        (run_dir / "report.json").write_text(payload, encoding="utf-8")
        (OUTPUT / "report.json").write_text(payload, encoding="utf-8")

    if report["status"] != "PASS":
        return 1
    print("PSCV0_CORE_MODULE_NATIVE_RESULT " + json.dumps({
        "schema": "psc0-core-module-native-result/1",
        "source_revision": report["source_revision"],
        "version": report["actual_version"],
        "githash": report["actual_githash"],
        "status": report["status"],
        "successful_compilations": report["successful_compilations"],
        "expected_refusals": report["expected_refusals"],
        "cases": report["cases"],
    }, sort_keys=True), flush=True)
    print("PSCV0_CORE_MODULE_NATIVE_ORACLE: 12 cases passed "
          "(8 successful compilations, 4 expected refusals)", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
