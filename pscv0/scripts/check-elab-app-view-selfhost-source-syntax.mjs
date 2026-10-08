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
  /def psExprAppViewAccWorker([\s\S]*?)(?=\ndef psExprHasConst)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_APP_VIEW_SELFHOST_SOURCE_SYNTAX_MISSING: invariant-safe app-view worker block",
  );
}

const block = match[0];
const required = [
  /def psExprAppViewAccWorker\s*\(expr : PsExpr\)\s*:\s*List PsExpr -> PsExprAppView :=\s*match expr with/,
  /\| \.app fn argument =>\s*let smaller : List PsExpr -> PsExprAppView :=\s*psExprAppViewAccWorker fn;\s*fun \(args : List PsExpr\) =>\s*smaller \(List\.cons argument args\)/,
  /\| _ =>\s*fun \(args : List PsExpr\) =>\s*\{\s*head := expr\s*args := args\s*\}/,
  /def psExprAppViewAcc\s*\(expr : PsExpr\)\s*\(args : List PsExpr\) : PsExprAppView :=\s*psExprAppViewAccWorker expr args/,
  /def psExprAppView \(expr : PsExpr\) : PsExprAppView :=\s*psExprAppViewAcc expr \[\]/,
];

for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_APP_VIEW_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /psExprAppViewAcc\s+fn\s*\(List\.cons argument args\)/,
  /psExprAppViewAccWorker\s+fn\s*\(List\.cons argument args\)/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_APP_VIEW_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_APP_VIEW_SELFHOST_SOURCE_SYNTAX: PASS (expr-recursive worker with post-recursion args accumulator)\n",
);
