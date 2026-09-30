import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const workerMatch = source.match(
  /def psExprApplyManyWorker([\s\S]*?)(?=\ndef psExprApplyMany)/,
);
if (workerMatch === null) {
  throw new Error(
    "PSC2_ELAB_APPLY_MANY_SELFHOST_SOURCE_SYNTAX_MISSING: psExprApplyManyWorker block",
  );
}

const worker = workerMatch[0];
const requiredWorker = [
  /def psExprApplyManyWorker\s*\(arguments : List PsExpr\)\s*:\s*PsExpr -> PsExpr :=/,
  /\| \[\] =>\s*fun \(fn : PsExpr\) =>\s*fn/,
  /let smaller : PsExpr -> PsExpr :=\s*psExprApplyManyWorker rest;/,
  /fun \(fn : PsExpr\) =>\s*smaller\s*\(PsExpr\.app fn argument\)/,
];
for (const pattern of requiredWorker) {
  if (!pattern.test(worker)) {
    throw new Error(
      `PSC2_ELAB_APPLY_MANY_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const wrapperMatch = source.match(
  /def psExprApplyMany([\s\S]*?)(?=\ndef psElabIf)/,
);
if (wrapperMatch === null) {
  throw new Error(
    "PSC2_ELAB_APPLY_MANY_SELFHOST_SOURCE_SYNTAX_MISSING: psExprApplyMany wrapper block",
  );
}

const wrapper = wrapperMatch[0];
if (!/def psExprApplyMany\s*\(fn : PsExpr\)\s*\(arguments : List PsExpr\)\s*:\s*PsExpr :=\s*psExprApplyManyWorker arguments fn/.test(wrapper)) {
  throw new Error(
    "PSC2_ELAB_APPLY_MANY_SELFHOST_SOURCE_SYNTAX_MISSING: invariant-safe wrapper",
  );
}
if (/psExprApplyMany\s*\(PsExpr\.app fn argument\)\s+rest/.test(wrapper)) {
  throw new Error(
    "PSC2_ELAB_APPLY_MANY_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: recursive accumulator mutation",
  );
}

process.stdout.write(
  "PSC2_ELAB_APPLY_MANY_SELFHOST_SOURCE_SYNTAX: PASS (list-recursive worker with post-recursion accumulator)\n",
);
