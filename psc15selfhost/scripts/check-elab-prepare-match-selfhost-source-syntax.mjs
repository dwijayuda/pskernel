import fs from "node:fs";

const path = new URL("../packages/elab/src/Ps/Elab/Term.lean", import.meta.url);
const source = fs.readFileSync(path, "utf8");
const start = source.indexOf("def psElabPrepareMatchAlternatives");
const end = source.indexOf("\nstructure PsElabMatchField", start);
if (start < 0 || end < 0) {
  throw new Error("PSC2_ELAB_PREPARE_MATCH_SELFHOST_SOURCE_SYNTAX_SECTION_MISSING");
}
const section = source.slice(start, end);

const required = [
  /def\s+psElabMatchAlternativeListReverseAux\b/,
  /def\s+psElabMatchAlternativeListReverse\b/,
  /def\s+psElabMatchAlternativesCoverConstructors\b/,
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
  ["List.reverse", /\bList\.reverse\b/],
  ["List.all", /\bList\.all\b/],
  ["List.isEmpty", /\bList\.isEmpty\b/],
]) {
  if (pattern.test(section)) {
    throw new Error(`PSC2_ELAB_PREPARE_MATCH_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${label}`);
  }
}

console.log("PSC2_ELAB_PREPARE_MATCH_SELFHOST_SOURCE_SYNTAX: PASS (local reverse/coverage helpers and explicit rest matching)");
