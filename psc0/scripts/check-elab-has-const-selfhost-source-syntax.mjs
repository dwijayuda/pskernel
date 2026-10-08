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
  /def psExprHasConst([\s\S]*?)(?=\ndef psMatchNameEqTarget)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_HAS_CONST_SELFHOST_SOURCE_SYNTAX_MISSING: psExprHasConst block",
  );
}

const block = match[0];
const required = [
  /def psExprHasConst\s*\(target : PsName\)\s*\(expr : PsExpr\) : Bool :=\s*match expr with/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_HAS_CONST_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /def psExprHasConst \(target : PsName\) : PsExpr -> Bool/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_HAS_CONST_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_HAS_CONST_SELFHOST_SOURCE_SYNTAX: PASS (explicit expr parameter with structural top-level match)\n",
);
