import fs from "node:fs";

const path = new URL("../packages/elab/src/Ps/Elab/Term.lean", import.meta.url);
const source = fs.readFileSync(path, "utf8");
const start = source.indexOf("def psElabFillWildcardAlternatives");
const end = source.indexOf("\ndef psElabMatchPatternConstructorName", start);
if (start < 0 || end < 0) {
  throw new Error("PSC2_ELAB_FILL_WILDCARD_SELFHOST_SOURCE_SYNTAX_SECTION_MISSING");
}
const section = source.slice(start, end);
if (!/let\s+next\s*:\s*List\s+PsElabMatchAlternative\s*:=\s*\n\s*match\s+psElabMatchAlternativeFind/.test(section)) {
  throw new Error("PSC2_ELAB_FILL_WILDCARD_SELFHOST_SOURCE_SYNTAX_MISSING: typed next match");
}
if (/let\s+next\s*:=\s*\n\s*match/.test(section)) {
  throw new Error("PSC2_ELAB_FILL_WILDCARD_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: untyped next match");
}
console.log("PSC2_ELAB_FILL_WILDCARD_SELFHOST_SOURCE_SYNTAX: PASS (typed local match result)");
