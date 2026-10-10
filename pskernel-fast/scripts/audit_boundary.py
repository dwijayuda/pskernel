#!/usr/bin/env python3
"""V3-only source dependency and governance fence. Not a soundness proof."""
import json
import pathlib
import re

root = pathlib.Path(__file__).resolve().parents[1]
policy = json.loads((root / "ARCHITECTURE_POLICY.json").read_text(encoding="utf-8"))
assert policy["schema"] == "pskernel-fast-architecture-policy/v3"
assert policy["design"]["legacyImplementationCompatibilityRequired"] is False
assert policy["design"]["legacyProofPreservationRequired"] is False
assert policy["design"]["oneProductionSemanticAuthority"] is True
assert policy["target"]["commit"] == "c29b6dda4f7c20e3eeaa717c4e565663c5cfa364"

prefixes = tuple(policy["source"]["forbiddenRuntimeImportPrefixes"])
lean_files = list((root / "src" / "PSKernelFast").rglob("*.lean"))
if not lean_files:
    raise SystemExit("No V3 independent source files found")
for path in lean_files:
    source = path.read_text(encoding="utf-8")
    for line in source.splitlines():
        if line.startswith("import "):
            for module in line.removeprefix("import ").split():
                if module.startswith(prefixes):
                    raise SystemExit(f"Legacy implementation imported in {path}: {module}")
    if re.search(r"(?m)^\\s*(?:sorry|axiom)\\b", source):
        raise SystemExit(f"Unsafe top-level proof placeholder in V3 kernel source: {path}")
print(f"V3 architecture fence PASS: {len(lean_files)} independent Lean source files")
