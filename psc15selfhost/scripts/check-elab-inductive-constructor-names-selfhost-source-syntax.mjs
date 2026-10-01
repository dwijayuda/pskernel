import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);
const start = source.indexOf("def psElabInductiveConstructorNames\n");
const end = source.indexOf("\ndef psElabContextWithEnvironment\n", start + 1);
if (start < 0 || end < 0) {
  throw new Error("PSC2_ELAB_CONSTRUCTOR_NAMES_MISSING: declaration block");
}

const block = source.slice(start, end);
// PSC1 needs the expected result type before elaborating a local match.
if (!/let currentName\s*:\s*PsName\s*:=\s*match\s+psSyntaxConstructorCoreName\s+inductiveName\s+source\.name\s+with/.test(block)) {
  throw new Error("PSC2_ELAB_CONSTRUCTOR_NAMES_MISSING: typed constructor-name match");
}
if (/let currentName\s*:=/.test(block)) {
  throw new Error("PSC2_ELAB_CONSTRUCTOR_NAMES_FORBIDDEN: untyped constructor-name match");
}

const alphaStart = source.indexOf("def psExprListAlphaEq");
const alphaEnd = source.indexOf("\ndef psElabIsDirectRecursiveField\n", alphaStart + 1);
if (alphaStart < 0 || alphaEnd < 0) {
  throw new Error("PSC2_ELAB_EXPR_LIST_ALPHA_EQ_MISSING: declaration block");
}

const alphaBlock = source.slice(alphaStart, alphaEnd);
const alphaRequired = [
  /def psExprListAlphaEqWorker\s*\(left : List PsExpr\)\s*:\s*List PsExpr -> Bool :=\s*match left with/,
  /\| List\.nil =>\s*fun \(right : List PsExpr\) =>\s*match right with/,
  /\| List\.cons leftExpr leftRest =>\s*let smaller : List PsExpr -> Bool :=\s*psExprListAlphaEqWorker leftRest;/,
  /if psExprAlphaEq leftExpr rightExpr then\s*smaller rightRest/,
  /def psExprListAlphaEq\s*\(left : List PsExpr\)\s*\(right : List PsExpr\) : Bool :=\s*psExprListAlphaEqWorker left right/,
];
for (const pattern of alphaRequired) {
  if (!pattern.test(alphaBlock)) {
    throw new Error(`PSC2_ELAB_EXPR_LIST_ALPHA_EQ_MISSING: ${pattern}`);
  }
}

if (/def psExprListAlphaEq\s*:\s*List PsExpr -> List PsExpr -> Bool/.test(alphaBlock)) {
  throw new Error(
    "PSC2_ELAB_EXPR_LIST_ALPHA_EQ_FORBIDDEN: multi-argument equation recursion",
  );
}

const directStart = source.indexOf("def psElabIsDirectRecursiveField\n");
const directEnd = source.indexOf("\ndef psElabContainerRecursiveName", directStart + 1);
if (directStart < 0 || directEnd < 0) {
  throw new Error("PSC2_ELAB_DIRECT_RECURSIVE_FIELD_MISSING: declaration block");
}
const directBlock = source.slice(directStart, directEnd);
if (!/Nat\.beq\s*\(psElabListLength view\.args\)\s*\(psElabListLength parameterArgs\)/.test(directBlock)) {
  throw new Error(
    "PSC2_ELAB_DIRECT_RECURSIVE_FIELD_MISSING: project-owned list length comparison",
  );
}
if (/\bview\.args\.length\b|\bparameterArgs\.length\b/.test(directBlock)) {
  throw new Error(
    "PSC2_ELAB_DIRECT_RECURSIVE_FIELD_FORBIDDEN: method-style list length",
  );
}

const inductiveConstructorStart = source.indexOf("def psElabInductiveConstructor\n");
const inductiveConstructorEnd = source.indexOf("\ndef psSetConstructorIndex\n", inductiveConstructorStart + 1);
if (inductiveConstructorStart < 0 || inductiveConstructorEnd < 0) {
  throw new Error("PSC2_ELAB_INDUCTIVE_CONSTRUCTOR_MISSING: declaration block");
}
const inductiveConstructorBlock = source.slice(
  inductiveConstructorStart,
  inductiveConstructorEnd,
);
if (!/PsConstructorInfo\.mk[\s\S]*?\(psElabListLength parameterArgs\)\s+\(psElabListLength source\.fields\)\s+recursiveFields/.test(inductiveConstructorBlock)) {
  throw new Error(
    "PSC2_ELAB_INDUCTIVE_CONSTRUCTOR_MISSING: project-owned parameter and field counts",
  );
}
if (/\bparameterArgs\.length\b|\bsource\.fields\.length\b/.test(inductiveConstructorBlock)) {
  throw new Error(
    "PSC2_ELAB_INDUCTIVE_CONSTRUCTOR_FORBIDDEN: method-style parameter or field counts",
  );
}
if (!/psElabRecursiveFieldIndices\s+fields\.context\s+inductiveName\s+parameterArgs\s+\(psElabTypedBinderListReverse fields\.bindersRev\)/.test(inductiveConstructorBlock)) {
  throw new Error(
    "PSC2_ELAB_INDUCTIVE_CONSTRUCTOR_MISSING: project-owned typed-binder reverse",
  );
}
if (/\bfields\.bindersRev\.reverse\b/.test(inductiveConstructorBlock)) {
  throw new Error(
    "PSC2_ELAB_INDUCTIVE_CONSTRUCTOR_FORBIDDEN: method-style typed-binder reverse",
  );
}

process.stdout.write(
  "PSC2_ELAB_CONSTRUCTOR_NAMES: PASS (explicit PsName result type for constructor-name selection)\n",
);
process.stdout.write(
  "PSC2_ELAB_EXPR_LIST_ALPHA_EQ_SELFHOST_SOURCE_SYNTAX: PASS (left-list-recursive worker; right list applied post-recursion)\n",
);
process.stdout.write(
  "PSC2_ELAB_DIRECT_RECURSIVE_FIELD_SELFHOST_SOURCE_SYNTAX: PASS (project-owned list length; method-style length excluded)\n",
);
process.stdout.write(
  "PSC2_ELAB_INDUCTIVE_CONSTRUCTOR_SELFHOST_SOURCE_SYNTAX: PASS (project-owned typed-binder reverse and list counts; generic list methods excluded)\n",
);
