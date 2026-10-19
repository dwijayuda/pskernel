import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const match = source.match(
  /def psExprAppViewAccWorker\b([\s\S]*?)(?=\ndef psExprHasConst\b)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_APP_VIEW_SELFHOST_SOURCE_SYNTAX_MISSING: app-view worker block",
  );
}

// Keep both supported source spellings. The helper migration conformance gate
// checks public types, direct expected trees, accumulator suffixes and round trips.
const block = match[0];
const workerForms = [
  [
    /def psExprAppViewAccWorker\s*\(expr : PsExpr\)\s*:\s*List PsExpr -> PsExprAppView :=\s*match expr with/,
    /\| \.app fn argument =>\s*let smaller : List PsExpr -> PsExprAppView :=\s*psExprAppViewAccWorker fn;\s*fun \(args : List PsExpr\) =>\s*smaller \(List\.cons argument args\)/,
    /\| _ =>\s*fun \(args : List PsExpr\) =>\s*\{\s*head := expr\s*args := args\s*\}/,
  ],
  [
    /def psExprAppViewAccWorker\s*\(expr : PsExpr\)\s*\(args : List PsExpr\)\s*:\s*PsExprAppView :=\s*match expr with/,
    /\| \.app fn argument =>\s*psExprAppViewAccWorker fn\s*\(List\.cons argument args\)/,
    /\| _ =>\s*\{\s*head := expr\s*args := args\s*\}/,
  ],
];
if (!workerForms.some((patterns) => patterns.every((pattern) => pattern.test(block)))) {
  throw new Error(
    "PSC2_ELAB_APP_VIEW_SELFHOST_SOURCE_SYNTAX_MISSING: supported structural worker",
  );
}

const wrappers = [
  /def psExprAppViewAcc\s*\(expr : PsExpr\)\s*\(args : List PsExpr\) : PsExprAppView :=\s*psExprAppViewAccWorker expr args/,
  /def psExprAppView \(expr : PsExpr\) : PsExprAppView :=\s*psExprAppViewAcc expr \[\]/,
];
for (const pattern of wrappers) {
  if (!pattern.test(block)) {
    throw new Error(
      "PSC2_ELAB_APP_VIEW_SELFHOST_SOURCE_SYNTAX_MISSING: public wrapper argument order",
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_APP_VIEW_SELFHOST_SOURCE_SYNTAX: PASS (historical or qualified SH/1 worker; public wrapper order)\n",
);
