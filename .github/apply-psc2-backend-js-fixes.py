from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one replacement, found {count}")
    path.write_text(text.replace(old, new, 1))


def insert_field(
    path: Path,
    block_start: str,
    block_end: str,
    old: str,
    new: str,
) -> None:
    text = path.read_text()
    start = text.index(block_start)
    end = text.index(block_end, start)
    block = text[start:end]
    if new.strip() in block:
        raise SystemExit(f"{path}: field already present in {block_start.strip()}")
    count = block.count(old)
    if count != 1:
        raise SystemExit(
            f"{path}: expected one anchor in {block_start.strip()}, found {count}"
        )
    block = block.replace(old, old + new, 1)
    path.write_text(text[:start] + block + text[end:])


printer = Path("psc15selfhost/packages/syntax/src/Ps/Syntax/PrintProofScript.lean")
text = printer.read_text()
start = text.index("      | .forallE binders body _ =>\n")
end = text.index("      | .letE name type value body _ =>\n", start)
block = text[start:end]
old = '''                  | Except.ok name =>
                      match
                          smaller type with
                      | Except.error error => Except.error error
                      | Except.ok printedType =>
                          let delimiters :=
                            psPrintBinderDelimiters head.kind;
                          Except.ok
                            (psPrintProofScriptConcat5
                              delimiters.fst
                              name
                              " : "
                              printedType
                              delimiters.snd);
'''
new = '''                  | Except.ok name =>
                      match
                          smaller type with
                      | Except.error error => Except.error error
                      | Except.ok printedType =>
                          let anonymousExplicit :=
                            match head.kind with
                            | PsSyntaxBinderKind.explicit =>
                                psStringEq name "_"
                            | _ => false;
                          if anonymousExplicit then
                            Except.ok
                              (psPrintProofScriptConcat3
                                "("
                                printedType
                                ")")
                          else
                            let delimiters :=
                              psPrintBinderDelimiters head.kind;
                            Except.ok
                              (psPrintProofScriptConcat5
                                delimiters.fst
                                name
                                " : "
                                printedType
                                delimiters.snd);
'''
if block.count(old) != 1:
    raise SystemExit("PrintProofScript forall binder shape changed")
block = block.replace(old, new, 1)
printer.write_text(text[:start] + block + text[end:])

bootstrap = Path("psc15selfhost/test/BootstrapTests.lean")
insert_field(
    bootstrap,
    "  let inductiveInfo : PsInductiveInfo := {\n",
    "  let constructorInfo : PsConstructorInfo := {\n",
    "    constructors := [ctorName]\n",
    "    isStructure := false\n",
)
insert_field(
    bootstrap,
    "  let constructorInfo : PsConstructorInfo := {\n",
    "  let recursorInfo : PsRecursorInfo := {\n",
    "    numFields := 0\n",
    "    recursiveFields := []\n",
)
insert_field(
    bootstrap,
    "  let indInfo : PsInductiveInfo := {\n",
    "  let leftInfo : PsConstructorInfo := {\n",
    "    constructors := [leftName, rightName]\n",
    "    isStructure := false\n",
)
insert_field(
    bootstrap,
    "  let leftInfo : PsConstructorInfo := {\n",
    "  let rightInfo : PsConstructorInfo := {\n",
    "    numFields := 0\n",
    "    recursiveFields := []\n",
)
insert_field(
    bootstrap,
    "  let rightInfo : PsConstructorInfo := {\n",
    "  let recInfo : PsRecursorInfo := {\n",
    "    numFields := 0\n",
    "    recursiveFields := []\n",
)
insert_field(
    bootstrap,
    "  let boxInfo : PsInductiveInfo := {\n",
    "  let ctorInfo : PsConstructorInfo := {\n",
    "    constructors := [ctorName]\n",
    "    isStructure := false\n",
)
insert_field(
    bootstrap,
    "  let ctorInfo : PsConstructorInfo := {\n",
    "  let recInfo : PsRecursorInfo := {\n",
    "    numFields := 1\n",
    "    recursiveFields := []\n",
)

coverage = Path("psc15selfhost/packages/backend-rust/src/Ps/BackendRust/Coverage.lean")
replace_once(
    coverage,
    '  | PsVerifiedIrIntrinsic.intLt => "Int.lt"\n'
    '  | PsVerifiedIrIntrinsic.boolNot => "Bool.not"\n',
    '  | PsVerifiedIrIntrinsic.intLt => "Int.lt"\n'
    '  | PsVerifiedIrIntrinsic.intRepr => "Int.repr"\n'
    '  | PsVerifiedIrIntrinsic.boolNot => "Bool.not"\n',
)
replace_once(
    coverage,
    "  | PsVerifiedIrIntrinsic.intLt => 2\n"
    "  | PsVerifiedIrIntrinsic.boolNot => 1\n",
    "  | PsVerifiedIrIntrinsic.intLt => 2\n"
    "  | PsVerifiedIrIntrinsic.intRepr => 1\n"
    "  | PsVerifiedIrIntrinsic.boolNot => 1\n",
)

rust_expr = Path("psc15selfhost/packages/backend-rust/src/Ps/BackendRust/Expr.lean")
replace_once(
    rust_expr,
    '                      ") ("\n',
    '                      ")("\n',
)
