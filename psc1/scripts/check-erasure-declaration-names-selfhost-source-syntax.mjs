import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Definition.lean"),
  "utf8",
);
const match = source.match(
  /def psBuildErasureDeclarationNamesWorker[\s\S]*?(?=\ndef psErasureReverseDeclarationNamesAcc\n|\ndef psErasureDeclarationNames\n)/,
);
if (match === null) {
  throw new Error("PSC2_ERASURE_DECLARATION_NAMES_MISSING: structural worker and wrapper");
}

const block = match[0];
const required = [
  /\(declarations : List PsDeclaration\)\s*\(state : PsErasureNameState\) : PsErasureNameState :=\s*match declarations with/,
  /\| List\.nil =>\s*state/,
  /\| List\.cons declaration rest =>\s*let sourceName : Option PsName :=/,
  /let sourceName : Option PsName :=\s*match declaration with/,
  /\| PsDeclaration\.definitionDecl name _ _ _ => Option\.some name/,
  /\| PsDeclaration\.partialDecl name _ _ _ => Option\.some name/,
  /\| PsDeclaration\.theoremDecl name _ _ _ => Option\.some name/,
  /\| PsDeclaration\.inductiveDecl info => Option\.some info\.name/,
  /\| _ => Option\.none;\s*match sourceName with/,
  /\| Option\.none => psBuildErasureDeclarationNamesWorker rest state/,
  /psErasureSafeIdentifier \(psNameToString name\) "decl";/,
  /psErasureAddUniqueString state\.used raw 4096;/,
  /psBuildErasureDeclarationNamesWorker\s+rest\s*\(PsErasureNameState\.mk\s*\(List\.cons candidate state\.used\)\s*\(List\.cons \(Prod\.mk name candidate\) state\.entriesRev\)\)/,
  /def psBuildErasureDeclarationNames\s*\(declarations : List PsDeclaration\)\s*\(state : PsErasureNameState\) : PsErasureNameState :=\s*psBuildErasureDeclarationNamesWorker declarations state/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(`PSC2_ERASURE_DECLARATION_NAMES_MISSING: ${pattern}`);
  }
}
if (/\| \[\], state =>|\| declaration :: rest, state =>|\| \.(?:definition|partial|theorem|inductive)Decl|\bused :=|\bentriesRev :=/.test(block)) {
  throw new Error("PSC2_ERASURE_DECLARATION_NAMES_FORBIDDEN: multi-argument equations or implicit constructors");
}

const ordered = source.match(
  /def psErasureReverseDeclarationNamesAcc[\s\S]*?(?=\ndef psEraseOpenDefinitionWithFuel\n)/,
);
if (ordered === null) {
  throw new Error("PSC2_ERASURE_DECLARATION_NAMES_MISSING: ordered-output reverse helper");
}
for (const pattern of [
  /\(entries : List \(PsName × String\)\) :\s*List \(PsName × String\) -> List \(PsName × String\) :=\s*match entries with/,
  /\| List\.nil =>\s*fun \(acc : List \(PsName × String\)\) => acc/,
  /psErasureReverseDeclarationNamesAcc rest;\s*fun \(acc : List \(PsName × String\)\) =>\s*smaller \(List\.cons entry acc\)/,
  /psBuildErasureDeclarationNames\s+declarations\s*\(PsErasureNameState\.mk List\.nil List\.nil\);/,
  /psErasureReverseDeclarationNamesAcc state\.entriesRev List\.nil/,
]) {
  if (!pattern.test(ordered[0])) {
    throw new Error(`PSC2_ERASURE_DECLARATION_NAMES_MISSING: ${pattern}`);
  }
}
if (/\.reverse\b|\bused :=|\bentriesRev :=/.test(ordered[0])) {
  throw new Error("PSC2_ERASURE_DECLARATION_NAMES_FORBIDDEN: generic reverse or implicit state constructor");
}

process.stdout.write(
  "PSC2_ERASURE_DECLARATION_NAMES: PASS (declaration-list recursion; typed name match; explicit constructors; ordered output through local reverse)\n",
);
