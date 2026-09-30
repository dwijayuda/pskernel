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

const projectionChainMatch = source.match(
  /def psElabProjectionChainWorker([\s\S]*?)(?=\ndef psElabProjectionReference)/,
);
if (projectionChainMatch === null) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabProjectionChainWorker block");
}
const projectionChain = projectionChainMatch[0];
const projectionChainRequired = [
  /def psElabProjectionChainWorker\s*\(fields : List String\)\s*:\s*PsElabContext ->\s*PsElabTermResult ->\s*Except PsElabError PsElabTermResult :=/,
  /let smaller\s*:\s*PsElabContext -> PsElabTermResult -> Except PsElabError PsElabTermResult :=\s*psElabProjectionChainWorker rest;/,
  /fun \(context : PsElabContext\) =>\s*fun \(current : PsElabTermResult\) =>/,
  /smaller projected\.context projected/,
  /def psElabProjectionChain\s*\(context : PsElabContext\)\s*\(current : PsElabTermResult\)\s*\(fields : List String\)[\s\S]*?psElabProjectionChainWorker fields context current/,
];
for (const pattern of projectionChainRequired) {
  if (!pattern.test(projectionChain)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabProjectionChain ${pattern}`);
  }
}
const projectionChainForbidden = [
  /psElabProjectionChain\s+projected\.context\s+projected\s+rest/,
  /psElabProjectionChainWorker\s+rest\s+projected\.context\s+projected/,
];
for (const pattern of projectionChainForbidden) {
  if (pattern.test(projectionChain)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: psElabProjectionChain ${pattern}`);
  }
}

const projectionReferenceMatch = source.match(
  /def psElabProjectionReference([\s\S]*?)(?=\ndef psElabNamedReference)/,
);
if (projectionReferenceMatch === null) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabProjectionReference block");
}
const projectionReference = projectionReferenceMatch[0];
if (!/let baseTerm : PsExpr :=\s*match resolved with\s*\| \.local id => PsExpr\.fvar id\s*\| \.global name => PsExpr\.constE name \[\];/.test(projectionReference)) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabProjectionReference typed baseTerm match");
}
if (/let baseTerm :=\s*match resolved with/.test(projectionReference)) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: psElabProjectionReference untyped baseTerm match");
}
if (!/psElabResolvedTerm\s+context\s+baseTerm\s+Option\.none/.test(projectionReference)) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabProjectionReference explicit Option.none");
}
if (/psElabResolvedTerm\s+context\s+baseTerm\s+none/.test(projectionReference)) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: psElabProjectionReference bare none result expectation");
}

const characterMatch = source.match(
  /def psElabCharacter([\s\S]*?)(?=\ndef psElabUnit)/,
);
if (characterMatch === null) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabCharacter block");
}
const character = characterMatch[0];
if (!/PsLiteral\.natural\s*\(Char\.toNat value\)/.test(character)) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabCharacter explicit Char.toNat application");
}
if (/\bvalue\.toNat\b/.test(character)) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: psElabCharacter method-style Char.toNat");
}

const typedBindersAccMatch = source.match(
  /def psElabTypedBindersAcc([\s\S]*?)(?=\ndef psElabTypedBinders)/,
);
if (typedBindersAccMatch === null) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabTypedBindersAcc block");
}
const typedBindersAcc = typedBindersAccMatch[0];
const typedBindersAccRequired = [
  /\(entries : List \(Prod PsSyntaxBinderHead PsSyntaxTerm\)\)\s*:\s*PsElabContext ->\s*List PsElabTypedBinder ->\s*Except PsElabError PsElabTypedBindersResult :=/,
  /let smaller\s*:\s*PsElabContext ->\s*List PsElabTypedBinder ->\s*Except PsElabError PsElabTypedBindersResult :=\s*psElabTypedBindersAcc elaborate rest;/,
  /fun \(context : PsElabContext\) =>\s*fun \(bindersRev : List PsElabTypedBinder\) =>/,
  /elaborate\s+context\s+sourceType\s+Option\.none/,
  /smaller\s+nextContext\s*\(List\.cons binderEntry bindersRev\)/,
];
for (const pattern of typedBindersAccRequired) {
  if (!pattern.test(typedBindersAcc)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabTypedBindersAcc ${pattern}`);
  }
}
const typedBindersAccForbidden = [
  /\(context : PsElabContext\)\s*\(entries : List \(Prod PsSyntaxBinderHead PsSyntaxTerm\)\)\s*\(bindersRev : List PsElabTypedBinder\)/,
  /psElabTypedBindersAcc\s+elaborate\s+nextContext\s+rest/,
  /elaborate\s+context\s+sourceType\s+none/,
];
for (const pattern of typedBindersAccForbidden) {
  if (pattern.test(typedBindersAcc)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: psElabTypedBindersAcc ${pattern}`);
  }
}

const typedBindersMatch = source.match(
  /def psElabTypedBinders([\s\S]*?)(?=\ndef psCloseElabTypedBinders)/,
);
if (typedBindersMatch === null) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabTypedBinders block");
}
if (!/psElabTypedBindersAcc\s+elaborate\s+binders\s+context\s+\[\]/.test(typedBindersMatch[0])) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psElabTypedBinders worker call order");
}

const closeTypedBindersMatch = source.match(
  /def psCloseElabTypedBinders([\s\S]*?)(?=\ndef psElabLambdaExpectedBody)/,
);
if (closeTypedBindersMatch === null) {
  throw new Error("PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psCloseElabTypedBinders block");
}
const closeTypedBinders = closeTypedBindersMatch[0];
const closeTypedBindersRequired = [
  /\(binders : List PsElabTypedBinder\)\s*:\s*PsExpr ->\s*PsExpr ->\s*Prod PsExpr PsExpr :=/,
  /\| \[\] =>\s*fun \(value : PsExpr\) =>\s*fun \(type : PsExpr\) =>\s*Prod\.mk value type/,
  /let smaller\s*:\s*PsExpr ->\s*PsExpr ->\s*Prod PsExpr PsExpr :=\s*psCloseElabTypedBinders metaContext rest;/,
  /fun \(value : PsExpr\) =>\s*fun \(type : PsExpr\) =>/,
  /smaller\s+closedValue\s+closedType/,
];
for (const pattern of closeTypedBindersRequired) {
  if (!pattern.test(closeTypedBinders)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_MISSING: psCloseElabTypedBinders ${pattern}`);
  }
}
const closeTypedBindersForbidden = [
  /\(binders : List PsElabTypedBinder\)\s*\(value : PsExpr\)\s*\(type : PsExpr\)/,
  /psCloseElabTypedBinders\s+metaContext\s+rest\s+closedValue\s+closedType/,
];
for (const pattern of closeTypedBindersForbidden) {
  if (pattern.test(closeTypedBinders)) {
    throw new Error(`PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: psCloseElabTypedBinders ${pattern}`);
  }
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
  "PSC2_ELAB_TERM_SELFHOST_SOURCE_SYNTAX: PASS (invariant-safe projection, typed-binder accumulation and typed-binder closing recursion, typed projection-reference match, explicit projection-reference expectation, explicit character conversion, explicit typed-binder expectation, local list length, and explicit Option constructors)\n",
);
