import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const infer = await readFile(
  path.join(root, "packages/meta/src/Ps/Meta/Infer.lean"),
  "utf8",
);

const required = [
  'def psInferAppViewAcc\n    (expr : PsExpr)\n    (args : List PsExpr) : PsInferAppView :=\n  match expr with',
  '| .app fn arg =>\n      psInferAppViewAcc fn (List.cons arg args)',
  '| _ =>\n      PsInferAppView.mk expr args',
];
for (const marker of required) {
  if (!infer.includes(marker)) {
    throw new Error(`PSC2_INFER_SELFHOST_SOURCE_SYNTAX_MISSING: ${marker}`);
  }
}

const forbidden = [
  '| head =>',
  'head := head',
];
for (const marker of forbidden) {
  if (infer.includes(marker)) {
    throw new Error(`PSC2_INFER_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${marker}`);
  }
}

process.stdout.write(
  "PSC2_INFER_SELFHOST_SOURCE_SYNTAX: PASS (explicit app-view fallback)\n",
);
