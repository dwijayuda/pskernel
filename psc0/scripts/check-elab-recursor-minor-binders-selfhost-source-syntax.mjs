import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);

const workerStart = source.indexOf("def psBuildRecursorMinorBindersWorker\n");
const wrapperStart = source.indexOf("\ndef psBuildRecursorMinorBinders\n");
const end = source.indexOf("\ndef psBuildInductiveRecursor\n", wrapperStart + 1);
if (workerStart < 0 || wrapperStart < 0 || end < 0 || workerStart > wrapperStart) {
  throw new Error(
    "PSC2_ELAB_RECURSOR_MINOR_BINDERS_SELFHOST_SOURCE_SYNTAX_MISSING: worker/wrapper declaration block",
  );
}

const worker = source.slice(workerStart, wrapperStart);
const wrapper = source.slice(wrapperStart, end);
const block = source.slice(workerStart, end);

const workerRequired = [
  /\(declarations\s*:\s*List PsDeclaration\)\s*:\s*\n\s*PsElabContext\s*->\s*\n\s*Nat\s*->\s*\n\s*List PsElabTypedBinder\s*->\s*\n\s*Except PsElabError PsElabRecursorMinorsResult\s*:=/,
  /match\s+declarations\s+with/,
  /\| List\.nil =>/,
  /\| List\.cons declaration rest =>/,
  /fun \(context\s*:\s*PsElabContext\) =>/,
  /fun \(_index\s*:\s*Nat\) =>/,
  /fun \(index\s*:\s*Nat\) =>/,
  /fun \(bindersRev\s*:\s*List PsElabTypedBinder\) =>/,
  /PsElabRecursorMinorsResult\.mk\s+context\s+bindersRev/,
  /psBuildRecursorMinorBindersWorker\s+parameterArgs\s+motiveId\s+rest\s*;/,
  /smaller\s+nextContext\s+\(Nat\.succ index\)/,
];
for (const pattern of workerRequired) {
  if (!pattern.test(worker)) {
    throw new Error(
      `PSC2_ELAB_RECURSOR_MINOR_BINDERS_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

if (!/psBuildRecursorMinorBindersWorker\s+parameterArgs\s+motiveId\s+declarations\s+context\s+index\s+bindersRev/.test(wrapper)) {
  throw new Error(
    "PSC2_ELAB_RECURSOR_MINOR_BINDERS_SELFHOST_SOURCE_SYNTAX_MISSING: thin wrapper delegates to worker",
  );
}

const forbidden = [
  /\|\s*\[\]\s*,\s*context\s*,/,
  /\|\s*declaration\s*::\s*rest\s*,\s*context\s*,/,
  /psBuildRecursorMinorBinders\s+parameterArgs\s+motiveId\s+rest\s+nextContext/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_RECURSOR_MINOR_BINDERS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

const recursorStart = source.indexOf("def psBuildInductiveRecursor\n");
const recursorEnd = source.indexOf("\ndef psElabInductiveDeclaration\n", recursorStart + 1);
if (recursorStart < 0 || recursorEnd < 0) {
  throw new Error(
    "PSC2_ELAB_INDUCTIVE_RECURSOR_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}
const recursor = source.slice(recursorStart, recursorEnd);
const recursorRequired = [
  /PsRecursorInfo\.mk\s+recursorName\s+\(List\.cons universeName List\.nil\)\s+recursorType\s+\(List\.cons inductiveInfo\.name List\.nil\)\s+\(psElabListLength parameterArgs\)\s+0\s+1\s+\(psElabListLength constructors\)/,
];
for (const pattern of recursorRequired) {
  if (!pattern.test(recursor)) {
    throw new Error(
      `PSC2_ELAB_INDUCTIVE_RECURSOR_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}
if (/\bparameterArgs\.length\b|\bconstructors\.length\b/.test(recursor)) {
  throw new Error(
    "PSC2_ELAB_INDUCTIVE_RECURSOR_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: method-style list length",
  );
}

const declarationStart = source.indexOf("def psElabInductiveDeclaration\n");
const declarationEnd = source.indexOf("\ndef psElabStructureDeclaration\n", declarationStart + 1);
if (declarationStart < 0 || declarationEnd < 0) {
  throw new Error(
    "PSC2_ELAB_INDUCTIVE_DECLARATION_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}
const declaration = source.slice(declarationStart, declarationEnd);
if (!/let result\s*:\s*Except PsElabError \(Prod PsElabContext PsExpr\)\s*:=\s*match resultType with/.test(declaration)) {
  throw new Error(
    "PSC2_ELAB_INDUCTIVE_DECLARATION_SELFHOST_SOURCE_SYNTAX_MISSING: typed result match",
  );
}
if (/let result\s*:=\s*match resultType with/.test(declaration)) {
  throw new Error(
    "PSC2_ELAB_INDUCTIVE_DECLARATION_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: untyped result match",
  );
}

process.stdout.write(
  "PSC2_ELAB_RECURSOR_MINOR_BINDERS_SELFHOST_SOURCE_SYNTAX: PASS (declaration-list-recursive worker; context/index/binder state applied post-recursion; explicit result constructor)\n",
);
process.stdout.write(
  "PSC2_ELAB_INDUCTIVE_RECURSOR_SELFHOST_SOURCE_SYNTAX: PASS (project-owned counts occupy recursor metadata fields; method-style length excluded)\n",
);
process.stdout.write(
  "PSC2_ELAB_INDUCTIVE_DECLARATION_SELFHOST_SOURCE_SYNTAX: PASS (explicit expected type for result-type local match)\n",
);
