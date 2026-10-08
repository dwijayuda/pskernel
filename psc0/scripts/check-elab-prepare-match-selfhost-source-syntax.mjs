import "./check-elab-match-apply-parameters-selfhost-source-syntax.mjs";
import fs from "node:fs";

const path = new URL("../packages/elab/src/Ps/Elab/Term.lean", import.meta.url);
const source = fs.readFileSync(path, "utf8");
const start = source.indexOf("def psElabPrepareMatchAlternativesWorker");
const end = source.indexOf("\nstructure PsElabMatchField", start);
if (start < 0 || end < 0) {
  throw new Error("PSC2_ELAB_PREPARE_MATCH_SELFHOST_SOURCE_SYNTAX_SECTION_MISSING");
}
const section = source.slice(start, end);

const required = [
  /def\s+psElabMatchAlternativeListReverseAux\b/,
  /def\s+psElabMatchAlternativeListReverse\b/,
  /def\s+psElabMatchAlternativesCoverConstructors\b/,
  /def\s+psElabPrepareMatchAlternativesWorker\s*\n\s*\(inductiveInfo\s*:\s*PsInductiveInfo\)\s*\n\s*\(entries\s*:\s*List/,
  /\(entries\s*:\s*List[\s\S]*?\)\s*:\s*\n\s*List\s+PsElabMatchAlternative\s*->\s*\n\s*Except\s+PsElabError\s+\(List\s+PsElabMatchAlternative\)\s*:=\s*\n\s*match\s+entries\s+with/,
  /let\s+smaller\s*:\s*\n\s*List\s+PsElabMatchAlternative\s*->\s*\n\s*Except\s+PsElabError\s+\(List\s+PsElabMatchAlternative\)\s*:=\s*\n\s*psElabPrepareMatchAlternativesWorker\s*\n\s*inductiveInfo\s*\n\s*rest/,
  /fun\s*\(alternativesRev\s*:\s*List\s+PsElabMatchAlternative\)\s*=>/,
  /smaller\s*\n\s*\(List\.cons\s+alternative\s+alternativesRev\)/,
  /def\s+psElabPrepareMatchAlternatives\b[\s\S]*?psElabPrepareMatchAlternativesWorker\s*\n\s*inductiveInfo\s*\n\s*entries\s*\n\s*alternativesRev/,
  /psElabMatchAlternativeListReverse\s+alternativesRev/,
  /psElabMatchAlternativesCoverConstructors\s+alternatives\s+inductiveInfo\.constructors/,
  /match\s+rest\s+with\s*\n\s*\|\s*\[\]/,
];
for (const pattern of required) {
  if (!pattern.test(source)) {
    throw new Error(`PSC2_ELAB_PREPARE_MATCH_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`);
  }
}

for (const [label, pattern] of [
  ["direct recursive prepare-match call", /psElabPrepareMatchAlternatives\s*\n\s*inductiveInfo\s*\n\s*rest\s*\n\s*\(List\.cons\s+alternative\s+alternativesRev\)/],
  ["List.reverse", /\bList\.reverse\b/],
  ["List.all", /\bList\.all\b/],
  ["List.isEmpty", /\bList\.isEmpty\b/],
]) {
  if (pattern.test(section)) {
    throw new Error(`PSC2_ELAB_PREPARE_MATCH_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${label}`);
  }
}

console.log("PSC2_ELAB_PREPARE_MATCH_SELFHOST_SOURCE_SYNTAX: PASS (local list ops and invariant-safe alternatives accumulator recursion)");
