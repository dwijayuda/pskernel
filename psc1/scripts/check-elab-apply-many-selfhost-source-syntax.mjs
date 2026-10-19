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
  /def psExprApplyManyWorker\b([\s\S]*?)(?=\ndef psExprApplyMany\b)/,
);
if (workerMatch === null) {
  throw new Error(
    "PSC2_ELAB_APPLY_MANY_SELFHOST_SOURCE_SYNTAX_MISSING: psExprApplyManyWorker block",
  );
}

// Accept the historical spelling and the qualified SH/1 explicit-parameter
// spelling. Public type and behavior correspondence are checked by the helper
// migration conformance gate; this guard only retains the source contract.
const worker = workerMatch[0];
const workerForms = [
  [
    /def psExprApplyManyWorker\s*\(arguments : List PsExpr\)\s*:\s*PsExpr -> PsExpr :=\s*match arguments with/,
    /\| \[\] =>\s*fun \(fn : PsExpr\) =>\s*fn/,
    /\| argument :: rest =>\s*let smaller : PsExpr -> PsExpr :=\s*psExprApplyManyWorker rest;\s*fun \(fn : PsExpr\) =>\s*smaller\s*\(PsExpr\.app fn argument\)/,
  ],
  [
    /def psExprApplyManyWorker\s*\(arguments : List PsExpr\)\s*\(fn : PsExpr\)\s*:\s*PsExpr :=\s*match arguments with/,
    /\| \[\] =>\s*fn/,
    /\| argument :: rest =>\s*psExprApplyManyWorker rest\s*\(PsExpr\.app fn argument\)/,
  ],
];
if (!workerForms.some((patterns) => patterns.every((pattern) => pattern.test(worker)))) {
  throw new Error(
    "PSC2_ELAB_APPLY_MANY_SELFHOST_SOURCE_SYNTAX_MISSING: supported structural worker",
  );
}

const wrapperMatch = source.match(
  /def psExprApplyMany\b([\s\S]*?)(?=\ndef psElabIf\b)/,
);
if (wrapperMatch === null) {
  throw new Error(
    "PSC2_ELAB_APPLY_MANY_SELFHOST_SOURCE_SYNTAX_MISSING: psExprApplyMany wrapper block",
  );
}

const wrapper = wrapperMatch[0];
if (!/def psExprApplyMany\s*\(fn : PsExpr\)\s*\(arguments : List PsExpr\)\s*:\s*PsExpr :=\s*psExprApplyManyWorker arguments fn/.test(wrapper)) {
  throw new Error(
    "PSC2_ELAB_APPLY_MANY_SELFHOST_SOURCE_SYNTAX_MISSING: public wrapper argument order",
  );
}

process.stdout.write(
  "PSC2_ELAB_APPLY_MANY_SELFHOST_SOURCE_SYNTAX: PASS (historical or qualified SH/1 worker; public wrapper order)\n",
);
