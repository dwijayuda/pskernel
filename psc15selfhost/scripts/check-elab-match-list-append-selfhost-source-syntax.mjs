// List.append is intentionally absent from the PSC1 bootstrap prelude; psElabMatch must stay on the project-local PsExpr-list helper.
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const helperStart = source.indexOf("def psElabExprListAppendWorker\n");
if (helperStart < 0) {
  throw new Error(
    "PSC2_ELAB_MATCH_LIST_APPEND_SELFHOST_SOURCE_SYNTAX_MISSING: PSC1-local PsExpr list append worker",
  );
}
const helperEnd = source.indexOf("\ndef psElabMatch\n", helperStart);
if (helperEnd < 0) {
  throw new Error(
    "PSC2_ELAB_MATCH_LIST_APPEND_SELFHOST_SOURCE_SYNTAX_MISSING: helper boundary before psElabMatch",
  );
}
const helperBlock = source.slice(helperStart, helperEnd);
const helperRequired = [
  /\(values : List PsExpr\)\s*:\s*\n\s*List PsExpr -> List PsExpr/,
  /let smaller\s*:\s*List PsExpr -> List PsExpr\s*:=\s*\n\s*psElabExprListAppendWorker rest/,
  /smaller right/,
  /def psElabExprListAppend\b/,
];
for (const pattern of helperRequired) {
  if (!pattern.test(helperBlock)) {
    throw new Error(
      `PSC2_ELAB_MATCH_LIST_APPEND_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const matchStart = source.indexOf("def psElabMatch\n", helperEnd);
const matchEnd = source.indexOf("\ndef psBinderAcceptsExplicitArgument", matchStart);
if (matchStart < 0 || matchEnd < 0) {
  throw new Error(
    "PSC2_ELAB_MATCH_LIST_APPEND_SELFHOST_SOURCE_SYNTAX_MISSING: psElabMatch block",
  );
}
const matchBlock = source.slice(matchStart, matchEnd);
if (/List\.append/.test(matchBlock)) {
  throw new Error(
    "PSC2_ELAB_MATCH_LIST_APPEND_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: generic List.append remains in psElabMatch bootstrap closure",
  );
}
const localCalls = matchBlock.match(/psElabExprListAppend/g) ?? [];
if (localCalls.length !== 2) {
  throw new Error(
    `PSC2_ELAB_MATCH_LIST_APPEND_SELFHOST_SOURCE_SYNTAX_MISSING: expected 2 project-local append calls, found ${localCalls.length}`,
  );
}

process.stdout.write(
  "PSC2_ELAB_MATCH_LIST_APPEND_SELFHOST_SOURCE_SYNTAX: PASS (PSC1-local PsExpr list append; generic List.append excluded from psElabMatch)\n",
);
