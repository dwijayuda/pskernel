import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const required = [
  /def psSyntaxNameAppendSegments\s*\(segments : List String\)\s*:\s*PsName -> PsName :=\s*match segments with/,
  /\| \[\] =>\s*fun \(name : PsName\) =>\s*name/,
  /let smaller : PsName -> PsName :=\s*psSyntaxNameAppendSegments rest;/,
  /fun \(name : PsName\) =>\s*smaller \(psNameAppendStr name segment\)/,
  /psSyntaxNameAppendSegments\s+rest\s*\(psNameAppendStr PsName\.anonymous first\)/,
];

for (const pattern of required) {
  if (!pattern.test(source)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`);
  }
}

const syntaxNameToNameMatch = source.match(
  /def psSyntaxNameToName\s*\(name : PsSyntaxName\) : Option PsName :=([\s\S]*?)(?=\ndef psElabResultWithMeta)/,
);
if (syntaxNameToNameMatch === null) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psSyntaxNameToName block");
}
const syntaxNameToName = syntaxNameToNameMatch[1];
const syntaxNameToNameRequired = [
  /\| \[\] =>\s*Option\.none/,
  /\| first :: rest =>\s*Option\.some\s*\(psSyntaxNameAppendSegments/,
];
for (const pattern of syntaxNameToNameRequired) {
  if (!pattern.test(syntaxNameToName)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psSyntaxNameToName ${pattern}`);
  }
}

const projectionApplyMatch = source.match(
  /def psElabProjectionApplyParameters([\s\S]*?)(?=\ndef psElabFindStructureField)/,
);
if (projectionApplyMatch === null) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabProjectionApplyParameters block");
}
const projectionApply = projectionApplyMatch[0];
const projectionApplyRequired = [
  /def psElabProjectionApplyParameters\s*\(context : PsElabContext\)\s*\(parameters : List PsExpr\)\s*:\s*PsExpr ->\s*Except PsElabError PsExpr :=/,
  /let smaller : PsExpr -> Except PsElabError PsExpr :=\s*psElabProjectionApplyParameters context rest;/,
  /fun \(cursor : PsExpr\) =>/,
  /smaller\s*\(psExprInstantiate1 forallView\.body parameter\)/,
];
for (const pattern of projectionApplyRequired) {
  if (!pattern.test(projectionApply)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabProjectionApplyParameters ${pattern}`);
  }
}
const projectionApplyForbidden = [
  /def psElabProjectionApplyParameters\s*\(context : PsElabContext\)\s*\(parameters : List PsExpr\)\s*\(cursor : PsExpr\)/,
  /psElabProjectionApplyParameters\s+context\s+rest\s*\(psExprInstantiate1 forallView\.body parameter\)/,
];
for (const pattern of projectionApplyForbidden) {
  if (pattern.test(projectionApply)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: psElabProjectionApplyParameters ${pattern}`);
  }
}

const forbidden = [
  /def psSyntaxNameAppendSegments\s*\(name : PsName\)\s*\(segments : List String\)/,
  /psSyntaxNameAppendSegments\s*\(psNameAppendStr name segment\)\s*rest/,
];

for (const pattern of forbidden) {
  if (pattern.test(source)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`);
  }
}

process.stdout.write(
  "PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX: PASS (invariant-safe syntax-name/projection recursion and explicit Option constructors)\n",
);
