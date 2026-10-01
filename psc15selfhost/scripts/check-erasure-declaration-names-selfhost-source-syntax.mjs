import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Definition.lean"),
  "utf8",
);
const match = source.match(
  /def psBuildErasureDeclarationNamesWorker[\s\S]*?(?=\ndef psErasureDeclarationNames\n)/,
);
if (match === null) {
  throw new Error("PSC2_ERASURE_DECLARATION_NAMES_MISSING: structural worker and wrapper");
}

const block = match[0];
const required = [
  /\(declarations : List PsDeclaration\) :\s*PsErasureNameState -> PsErasureNameState :=\s*match declarations with/,
  /\| List\.nil =>\s*fun \(state : PsErasureNameState\) => state/,
  /let smaller : PsErasureNameState -> PsErasureNameState :=\s*psBuildErasureDeclarationNamesWorker rest;/,
  /let sourceName : Option PsName :=\s*match declaration with/,
  /\| PsDeclaration\.definitionDecl name _ _ _ => Option\.some name/,
  /\| PsDeclaration\.partialDecl name _ _ _ => Option\.some name/,
  /\| PsDeclaration\.theoremDecl name _ _ _ => Option\.some name/,
  /\| PsDeclaration\.inductiveDecl info => Option\.some info\.name/,
  /\| _ => Option\.none;\s*match sourceName with/,
  /\| Option\.none => smaller state/,
  /psErasureSafeIdentifier \(psNameToString name\) "decl";/,
  /psErasureAddUniqueString state\.used raw 4096;/,
  /smaller\s*\(PsErasureNameState\.mk\s*\(List\.cons candidate state\.used\)\s*\(List\.cons \(Prod\.mk name candidate\) state\.entriesRev\)\)/,
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

process.stdout.write(
  "PSC2_ERASURE_DECLARATION_NAMES: PASS (declaration-list recursion; state applied afterward; typed name match and explicit constructors)\n",
);
