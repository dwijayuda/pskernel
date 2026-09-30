from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one replacement, found {count}")
    path.write_text(text.replace(old, new, 1))


printer = Path("psc15selfhost/packages/syntax/src/Ps/Syntax/PrintProofScript.lean")
replace_once(printer, 'psStringEq name "_"', 'name == "_"')

rust_tests = Path("psc15selfhost/test/BackendRustTests.lean")
lines = rust_tests.read_text().splitlines(keepends=True)
out = []
i = 0
sites = 0
patched = 0
while i < len(lines):
    line = lines[i]
    out.append(line)
    if "PsVerifiedIrExpr.intrinsic" not in line:
        i += 1
        continue

    sites += 1
    i += 1
    if i >= len(lines):
        raise SystemExit("BackendRustTests.lean: intrinsic at end of file")

    # Copy through the intrinsic operation expression. Its first line starts
    # with PsVerifiedIrIntrinsic; constructor arguments, if multiline, are
    # more deeply indented. The next line at the operation indentation is the
    # intrinsic type-argument list in the current IR shape.
    while i < len(lines) and "PsVerifiedIrIntrinsic." not in lines[i]:
        out.append(lines[i])
        i += 1
    if i >= len(lines):
        raise SystemExit("BackendRustTests.lean: missing intrinsic operation")

    operation_indent = len(lines[i]) - len(lines[i].lstrip(" "))
    out.append(lines[i])
    i += 1
    while i < len(lines):
        stripped = lines[i].strip()
        indent = len(lines[i]) - len(lines[i].lstrip(" "))
        if stripped and indent == operation_indent:
            break
        out.append(lines[i])
        i += 1
    if i >= len(lines):
        raise SystemExit("BackendRustTests.lean: missing intrinsic argument list")

    if lines[i].strip() != "[]":
        out.append(" " * operation_indent + "[]\n")
        patched += 1
    out.append(lines[i])
    i += 1

if sites == 0 or patched == 0:
    raise SystemExit(f"BackendRustTests.lean: unexpected migration counts sites={sites} patched={patched}")

text = "".join(out)
rust_tests.write_text(text)

# Verify every intrinsic now has an explicit type-argument list at the same
# indentation as the operation expression.
lines = text.splitlines()
verified = 0
for index, line in enumerate(lines):
    if "PsVerifiedIrExpr.intrinsic" not in line:
        continue
    op = index + 1
    while op < len(lines) and "PsVerifiedIrIntrinsic." not in lines[op]:
        op += 1
    if op >= len(lines):
        raise SystemExit("BackendRustTests.lean: verification missing operation")
    operation_indent = len(lines[op]) - len(lines[op].lstrip(" "))
    cursor = op + 1
    while cursor < len(lines):
        stripped = lines[cursor].strip()
        indent = len(lines[cursor]) - len(lines[cursor].lstrip(" "))
        if stripped and indent == operation_indent:
            break
        cursor += 1
    if cursor >= len(lines) or lines[cursor].strip() != "[]":
        raise SystemExit(
            f"BackendRustTests.lean:{index + 1}: intrinsic missing explicit type arguments"
        )
    verified += 1

if verified != sites:
    raise SystemExit(f"BackendRustTests.lean: verified={verified}, sites={sites}")

print(f"BACKEND_RUST_TEST_INTRINSIC_MIGRATION: sites={sites} patched={patched}")
