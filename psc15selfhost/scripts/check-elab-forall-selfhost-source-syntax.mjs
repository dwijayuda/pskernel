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
  /def psCloseElabForallBinders([\s\S]*?)(?=\ndef psElabForall)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_FORALL_SELFHOST_SOURCE_SYNTAX_MISSING: psCloseElabForallBinders block",
  );
}

const block = match[0];
const required = [
  /\(binders : List PsElabTypedBinder\)\s*:\s*PsExpr ->\s*PsExpr :=/,
  /\| \[\] =>\s*fun \(body : PsExpr\) =>\s*body/,
  /let smaller\s*:\s*PsExpr -> PsExpr :=\s*psCloseElabForallBinders metaContext rest;/,
  /fun \(body : PsExpr\) =>/,
  /smaller closedBody/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_FORALL_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /\(binders : List PsElabTypedBinder\)\s*\(body : PsExpr\)/,
  /psCloseElabForallBinders\s+metaContext\s+rest\s+closedBody/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_FORALL_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_FORALL_SELFHOST_SOURCE_SYNTAX: PASS (invariant-safe forall binder closing recursion)\n",
);
