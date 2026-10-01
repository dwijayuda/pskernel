import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const closeMatch = source.match(
  /def psCloseElabForallBinders([\s\S]*?)(?=\ndef psElabForall)/,
);
if (closeMatch === null) {
  throw new Error(
    "PSC2_ELAB_FORALL_SELFHOST_SOURCE_SYNTAX_MISSING: psCloseElabForallBinders block",
  );
}

const closeBlock = closeMatch[0];
const closeRequired = [
  /\(binders : List PsElabTypedBinder\)\s*:\s*PsExpr ->\s*PsExpr :=/,
  /\| \[\] =>\s*fun \(body : PsExpr\) =>\s*body/,
  /let smaller\s*:\s*PsExpr -> PsExpr :=\s*psCloseElabForallBinders metaContext rest;/,
  /fun \(body : PsExpr\) =>/,
  /smaller closedBody/,
];
for (const pattern of closeRequired) {
  if (!pattern.test(closeBlock)) {
    throw new Error(
      `PSC2_ELAB_FORALL_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const closeForbidden = [
  /\(binders : List PsElabTypedBinder\)\s*\(body : PsExpr\)/,
  /psCloseElabForallBinders\s+metaContext\s+rest\s+closedBody/,
];
for (const pattern of closeForbidden) {
  if (pattern.test(closeBlock)) {
    throw new Error(
      `PSC2_ELAB_FORALL_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

const forallMatch = source.match(
  /def psElabForall([\s\S]*?)(?=\ndef psElabLetAfterValue)/,
);
if (forallMatch === null) {
  throw new Error(
    "PSC2_ELAB_FORALL_SELFHOST_SOURCE_SYNTAX_MISSING: psElabForall block",
  );
}

const forallBlock = forallMatch[0];
const forallRequired = [
  /match elaborate\s+binderResult\.context\s+body\s+Option\.none with/,
];
for (const pattern of forallRequired) {
  if (!pattern.test(forallBlock)) {
    throw new Error(
      `PSC2_ELAB_FORALL_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forallForbidden = [
  /match elaborate\s+binderResult\.context\s+body\s+none with/,
];
for (const pattern of forallForbidden) {
  if (pattern.test(forallBlock)) {
    throw new Error(
      `PSC2_ELAB_FORALL_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_FORALL_SELFHOST_SOURCE_SYNTAX: PASS (invariant-safe forall binder closing recursion; explicit Option.none body expectation)\n",
);
