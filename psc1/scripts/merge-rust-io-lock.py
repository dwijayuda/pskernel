"""Merge the generated guest and standalone host's already locked dependencies.

Only CI consumer copies are changed. Cargo --locked validates the resulting
graph against both manifests; no registry version is reselected here.
"""
import json
from pathlib import Path
import sys
import tomllib

guest_path, host_path = map(Path, sys.argv[1:])
guest = tomllib.loads(guest_path.read_text())
host = tomllib.loads(host_path.read_text())
packages = {}
for lock in (guest, host):
    assert set(lock) <= {"version", "package"} and lock["version"] == 4
    for package in lock["package"]:
        assert set(package) <= {"name", "version", "source", "checksum", "dependencies"}
        key = (package["name"], package["version"], package.get("source", ""))
        if key in packages:
            assert packages[key] == package, ("conflicting locked package", key)
        else:
            packages[key] = dict(package)
roots = [p for p in packages.values() if p["name"] == "psc1_generated" and "source" not in p]
assert len(roots) == 1
dependencies = roots[0].get("dependencies", [])
assert "psc1-typed-io" not in dependencies
roots[0]["dependencies"] = sorted([*dependencies, "psc1-typed-io"])
lines = ["# Generated CI consumer lock; existing guest and host versions preserved.", "version = 4", ""]
for key in sorted(packages):
    package = packages[key]
    lines.append("[[package]]")
    for field in ("name", "version", "source", "checksum", "dependencies"):
        if field in package:
            lines.append(field + " = " + json.dumps(package[field], ensure_ascii=True))
    lines.append("")
guest_path.write_text("\n".join(lines))
