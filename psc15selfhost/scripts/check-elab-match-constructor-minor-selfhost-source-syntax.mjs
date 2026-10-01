// Regression gate: keep constructor-minor source inside the PSC1 bootstrap surface.
// In particular, avoid generic List.reverse here: unresolved bootstrap names can fall through projection elaboration as unsupportedTerm.
// Also keep Option constructors explicit in term position so bootstrap name resolution does not depend on Lean's open constructors.
// Constructor-pattern `some`/`none` remains valid pattern syntax; this guard only constrains the expected-type value expression.
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const blockMatch = source.match(
  /def psElabMatchConstructorMinor([\s\S]*?)(?=\ndef psElabMatchMinor\n)/,
);

if (blockMatch === null) {
  throw new Error(
    "PSC2_ELAB_MATCH_CONSTRUCTOR_MINOR_SELFHOST_SOURCE_SYNTAX_MISSING: constructor minor declaration",
  );
}

const block = blockMatch[0];

if (!/let binders\s*:\s*List PsSyntaxName\s*:=\s*match sourceBinders with/.test(block)) {
  throw new Error(
    "PSC2_ELAB_MATCH_CONSTRUCTOR_MINOR_SELFHOST_SOURCE_SYNTAX_MISSING: explicit List PsSyntaxName expected type for source-binder match",
  );
}

if (/let binders\s*:=\s*match sourceBinders with/.test(block)) {
  throw new Error(
    "PSC2_ELAB_MATCH_CONSTRUCTOR_MINOR_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: untyped source-binder match reaches match elaboration with no expected type",
  );
}

if (!/def psElabMatchFieldListReverseWorker\s*\([\s\S]*?def psElabMatchFieldListReverse\s*\(/.test(source)) {
  throw new Error(
    "PSC2_ELAB_MATCH_CONSTRUCTOR_MINOR_SELFHOST_SOURCE_SYNTAX_MISSING: PSC1-local PsElabMatchField reverse helper",
  );
}

if (!/let fields\s*:=\s*psElabMatchFieldListReverse\s+fieldResult\.fieldsRev/.test(block)) {
  throw new Error(
    "PSC2_ELAB_MATCH_CONSTRUCTOR_MINOR_SELFHOST_SOURCE_SYNTAX_MISSING: constructor minor uses local match-field reverse helper",
  );
}

if (/List\.reverse\s+fieldResult\.fieldsRev/.test(block)) {
  throw new Error(
    "PSC2_ELAB_MATCH_CONSTRUCTOR_MINOR_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: generic List.reverse in constructor minor bootstrap path",
  );
}

if (!/\(Option\.some expectedType\)/.test(block)) {
  throw new Error(
    "PSC2_ELAB_MATCH_CONSTRUCTOR_MINOR_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some expected type term",
  );
}

if (/\(some expectedType\)/.test(block)) {
  throw new Error(
    "PSC2_ELAB_MATCH_CONSTRUCTOR_MINOR_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: bare some in term position depends on unavailable bootstrap name resolution",
  );
}

process.stdout.write(
  "PSC2_ELAB_MATCH_CONSTRUCTOR_MINOR_SELFHOST_SOURCE_SYNTAX: PASS (typed source-binder match; PSC1-local match-field reverse; explicit Option.some expected type)\n",
);
