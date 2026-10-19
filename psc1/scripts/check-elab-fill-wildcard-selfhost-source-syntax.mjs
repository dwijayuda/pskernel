import fs from "node:fs";

const path = new URL("../packages/elab/src/Ps/Elab/Term.lean", import.meta.url);
const source = fs.readFileSync(path, "utf8");
const start = source.indexOf("def psElabFillWildcardAlternatives");
const end = source.indexOf("\ndef psElabMatchPatternConstructorName", start);
if (start < 0 || end < 0) {
  throw new Error("PSC2_ELAB_FILL_WILDCARD_SELFHOST_SOURCE_SYNTAX_SECTION_MISSING");
}
const section = source.slice(start, end);

const required = [
  /\(constructors\s*:\s*List\s+PsName\)\s*:\s*\n\s*List\s+PsElabMatchAlternative\s*->\s*\n\s*List\s+PsElabMatchAlternative\s*:=/,
  /let\s+smaller\s*:\s*\n?\s*List\s+PsElabMatchAlternative\s*->\s*\n?\s*List\s+PsElabMatchAlternative\s*:=\s*\n\s*psElabFillWildcardAlternatives\s+\n?\s*pattern\s+\n?\s*body\s+\n?\s*span\s+\n?\s*rest/,
  /fun\s*\(alternativesRev\s*:\s*List\s+PsElabMatchAlternative\)\s*=>/,
  /let\s+next\s*:\s*List\s+PsElabMatchAlternative\s*:=\s*\n\s*match\s+psElabMatchAlternativeFind/,
  /smaller\s+next/,
];
for (const pattern of required) {
  if (!pattern.test(section)) {
    throw new Error(`PSC2_ELAB_FILL_WILDCARD_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`);
  }
}

if (/let\s+next\s*:=\s*\n\s*match/.test(section)) {
  throw new Error("PSC2_ELAB_FILL_WILDCARD_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: untyped next match");
}
if (/psElabFillWildcardAlternatives\s+\n?\s*pattern\s+\n?\s*body\s+\n?\s*span\s+\n?\s*rest\s+\n?\s*next/.test(section)) {
  throw new Error("PSC2_ELAB_FILL_WILDCARD_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: direct recursive accumulator update");
}

console.log("PSC2_ELAB_FILL_WILDCARD_SELFHOST_SOURCE_SYNTAX: PASS (typed local match and invariant-safe accumulator recursion)");
