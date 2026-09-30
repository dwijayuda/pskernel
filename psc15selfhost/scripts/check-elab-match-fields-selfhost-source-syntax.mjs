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
  /def psElabMatchFieldsWorker([\s\S]*?)(?=\ndef psElabMatchFieldAt)/,
);
if (blockMatch === null) {
  throw new Error(
    "PSC2_ELAB_MATCH_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: invariant-safe match-fields worker block",
  );
}

const block = blockMatch[0];
const required = [
  /def psElabMatchFieldsWorker\s*\(inductiveName : PsName\)\s*\(binderSyntaxes : List PsSyntaxName\)\s*:\s*PsElabContext ->\s*PsExpr ->\s*List PsElabMatchField ->\s*Except PsElabError PsElabMatchFieldsResult :=\s*match binderSyntaxes with/,
  /let smaller[\s\S]*?psElabMatchFieldsWorker\s+inductiveName\s+rest/,
  /smaller\s+nextContext\s*\(psExprInstantiate1[\s\S]*?forallView\.body[\s\S]*?\(PsExpr\.fvar pushed\.id\)\)\s*\(List\.cons field fieldsRev\)/,
  /def psElabMatchFields\s*\(context : PsElabContext\)\s*\(inductiveName : PsName\)\s*\(cursor : PsExpr\)\s*\(binderSyntaxes : List PsSyntaxName\)\s*\(fieldsRev : List PsElabMatchField\)[\s\S]*?psElabMatchFieldsWorker\s+inductiveName\s+binderSyntaxes\s+context\s+cursor\s+fieldsRev/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /psElabMatchFields\s+nextContext/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_FIELDS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_MATCH_FIELDS_SELFHOST_SOURCE_SYNTAX: PASS (binder-list-recursive worker with post-recursion context/cursor/field accumulator)\n",
);
