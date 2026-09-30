from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one replacement, found {count}")
    path.write_text(text.replace(old, new, 1))


def migrate_intrinsic_type_arguments(path: Path) -> tuple[int, int]:
    lines = path.read_text().splitlines(keepends=True)
    out: list[str] = []
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
        while i < len(lines) and "PsVerifiedIrIntrinsic." not in lines[i]:
            out.append(lines[i])
            i += 1
        if i >= len(lines):
            raise SystemExit(f"{path}: missing intrinsic operation")

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
            raise SystemExit(f"{path}: missing intrinsic arguments")

        if lines[i].strip() != "[]":
            out.append(" " * operation_indent + "[]\n")
            patched += 1
        out.append(lines[i])
        i += 1

    if sites == 0:
        raise SystemExit(f"{path}: no intrinsic sites found")
    path.write_text("".join(out))

    verified = 0
    lines = path.read_text().splitlines()
    for index, line in enumerate(lines):
        if "PsVerifiedIrExpr.intrinsic" not in line:
            continue
        op = index + 1
        while op < len(lines) and "PsVerifiedIrIntrinsic." not in lines[op]:
            op += 1
        if op >= len(lines):
            raise SystemExit(f"{path}:{index + 1}: missing operation")
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
                f"{path}:{index + 1}: intrinsic missing explicit type arguments"
            )
        verified += 1
    if verified != sites:
        raise SystemExit(f"{path}: verified={verified}, sites={sites}")
    return sites, patched


parser = Path("psc15selfhost/packages/syntax/src/Ps/Syntax/ParseProofScript.lean")
old = '''      let smaller :
          PsTokenCursor ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseProofScriptBinderTypeWithFuel remaining;
      fun (cursor : PsTokenCursor) =>
        match psParseProofScriptSimpleApplication cursor with
'''
new = '''      let smaller :
          PsTokenCursor ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseProofScriptBinderTypeWithFuel remaining;
      let parseDomain :
          PsTokenCursor ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        fun (domainCursor : PsTokenCursor) =>
          if psTokenCursorAtText domainCursor "(" then
            match psTokenCursorAdvance domainCursor with
            | Option.none =>
                Except.error (PsParseError.unexpectedEnd "(")
            | Option.some opening =>
                match smaller opening.cursor with
                | Except.error error => Except.error error
                | Except.ok grouped =>
                    match psTokenCursorExpectText grouped.cursor ")" with
                    | Except.error error => Except.error error
                    | Except.ok close =>
                        Except.ok {
                          value := grouped.value
                          cursor := close.cursor
                        }
          else
            psParseProofScriptSimpleApplication domainCursor;
      fun (cursor : PsTokenCursor) =>
        match parseDomain cursor with
'''
replace_once(parser, old, new)

rust_let_tests = Path("psc15selfhost/test/BackendRustLetFunctionResultTests.lean")
sites, patched = migrate_intrinsic_type_arguments(rust_let_tests)
if patched == 0:
    raise SystemExit(
        f"{rust_let_tests}: expected stale intrinsic fixtures, sites={sites} patched=0"
    )
print(
    f"BACKEND_RUST_LET_INTRINSIC_MIGRATION: sites={sites} patched={patched}"
)
