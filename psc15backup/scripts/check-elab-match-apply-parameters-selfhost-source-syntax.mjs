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
  /def psElabMatchApplyParametersWorker([\s\S]*?)(?=\ndef psSyntaxNameIsWildcardBinder)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_MATCH_APPLY_PARAMETERS_SELFHOST_SOURCE_SYNTAX_MISSING: invariant-safe match-parameter worker block",
  );
}

const block = match[0];
const required = [
  /def psElabMatchApplyParametersWorker\s*\(context : PsElabContext\)\s*\(parameters : List PsExpr\)\s*:\s*PsExpr ->\s*Except PsElabError PsExpr :=\s*match parameters with/,
  /\| \[\] =>\s*fun \(cursor : PsExpr\) =>\s*Except\.ok cursor/,
  /\| parameter :: rest =>\s*let smaller :\s*PsExpr -> Except PsElabError PsExpr :=\s*psElabMatchApplyParametersWorker\s*context\s*rest;\s*fun \(cursor : PsExpr\) =>/,
  /\| Except\.ok forallView =>\s*smaller\s*\(psExprInstantiate1\s*forallView\.body\s*parameter\)/,
  /def psElabMatchApplyParameters\s*\(context : PsElabContext\)\s*\(parameters : List PsExpr\)\s*\(cursor : PsExpr\)\s*:\s*Except PsElabError PsExpr :=\s*psElabMatchApplyParametersWorker\s*context\s*parameters\s*cursor/,
];

for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_APPLY_PARAMETERS_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /psElabMatchApplyParameters\s+context\s+rest\s*\(/,
  /psElabMatchApplyParametersWorker\s+context\s+rest\s*\(psExprInstantiate1/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_APPLY_PARAMETERS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_MATCH_APPLY_PARAMETERS_SELFHOST_SOURCE_SYNTAX: PASS (parameter-recursive worker with post-recursion cursor)\n",
);
