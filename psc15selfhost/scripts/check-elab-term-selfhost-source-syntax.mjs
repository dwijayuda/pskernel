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
  /def psElabListLength\s*\{α : Type\}\s*\(values : List α\) : Nat :=\s*match values with\s*\| \[\] => 0\s*\| _ :: rest => Nat\.succ \(psElabListLength rest\)/,
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

const findStructureFieldMatch = source.match(
  /def psElabFindStructureField([\s\S]*?)(?=\ndef psElabProjectionStep)/,
);
if (findStructureFieldMatch === null) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabFindStructureField block");
}
const findStructureField = findStructureFieldMatch[0];
const findStructureFieldRequired = [
  /def psElabFindStructureField\s*\(context : PsElabContext\)\s*\(typeName : PsName\)\s*\(target : PsExpr\)\s*\(fieldName : String\)\s*\(remaining : Nat\)\s*:\s*Nat ->\s*PsExpr ->\s*Except PsElabError Nat :=/,
  /let smaller : Nat -> PsExpr -> Except PsElabError Nat :=\s*psElabFindStructureField\s+context\s+typeName\s+target\s+fieldName\s+nextRemaining;/,
  /fun \(index : Nat\) =>\s*fun \(cursor : PsExpr\) =>/,
  /smaller\s*\(Nat\.succ index\)\s*\(psExprInstantiate1\s+forallView\.body\s*\(PsExpr\.proj typeName index target\)\)/,
];
for (const pattern of findStructureFieldRequired) {
  if (!pattern.test(findStructureField)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabFindStructureField ${pattern}`);
  }
}
const findStructureFieldForbidden = [
  /def psElabFindStructureField[\s\S]*?\(index : Nat\)\s*\(remaining : Nat\)\s*\(cursor : PsExpr\)/,
  /psElabFindStructureField\s+context\s+typeName\s+target\s+fieldName\s*\(Nat\.succ index\)\s+nextRemaining/,
];
for (const pattern of findStructureFieldForbidden) {
  if (pattern.test(findStructureField)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: psElabFindStructureField ${pattern}`);
  }
}

const projectionStepMatch = source.match(
  /def psElabProjectionStep([\s\S]*?)(?=\ndef psElabProjectionChain)/,
);
if (projectionStepMatch === null) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabProjectionStep block");
}
const projectionStep = projectionStepMatch[0];
if (!/psElabFindStructureField\s+current\.context\s+typeName\s+current\.term\s+fieldName\s+constructorInfo\.numFields\s+0\s+fieldCursor/.test(projectionStep)) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabProjectionStep reordered psElabFindStructureField call");
}
if (/psElabFindStructureField\s+current\.context\s+typeName\s+current\.term\s+fieldName\s+0\s+constructorInfo\.numFields\s+fieldCursor/.test(projectionStep)) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: psElabProjectionStep old psElabFindStructureField call order");
}
if (!/Nat\.beq \(psElabListLength view\.args\) info\.numParams/.test(projectionStep)) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabProjectionStep local list length");
}
const projectionResolvedTerm = /psElabResolvedTerm\s+current\.context\s*\(PsExpr\.proj\s+typeName\s+index\s+current\.term\)\s+Option\.none/;
if (!projectionResolvedTerm.test(projectionStep)) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabProjectionStep explicit Option.none");
}
const projectionBareNone = /psElabResolvedTerm\s+current\.context\s*\(PsExpr\.proj\s+typeName\s+index\s+current\.term\)\s+none/;
if (projectionBareNone.test(projectionStep)) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: psElabProjectionStep bare none result expectation");
}

const forbidden = [
  /def psSyntaxNameAppendSegments\s*\(name : PsName\)\s*\(segments : List String\)/,
  /psSyntaxNameAppendSegments\s*\(psNameAppendStr name segment\)\s*rest/,
  /def psElabListLength\s*\{α : Type\}\s*:\s*List α -> Nat/,
  /\bList\.length\b/,
];

for (const pattern of forbidden) {
  if (pattern.test(source)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`);
  }
}

process.stdout.write(
  "PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX: PASS (invariant-safe syntax-name/projection/field/list-length recursion and explicit Option constructors)\n",
);
