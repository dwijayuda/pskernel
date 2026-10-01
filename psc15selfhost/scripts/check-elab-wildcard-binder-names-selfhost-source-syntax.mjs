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
  /def psElabWildcardBinderNamesWorker([\s\S]*?)(?=\ndef psElabMatchConstructorMinor)/,
);

if (blockMatch === null) {
  throw new Error(
    "PSC2_ELAB_WILDCARD_BINDER_NAMES_SELFHOST_SOURCE_SYNTAX_MISSING: remaining-recursive worker with post-recursion index",
  );
}

const block = blockMatch[0];

for (const pattern of [
  /def psElabWildcardBinderNamesWorker\s*\(span : PsSourceSpan\)\s*\(remaining : Nat\)\s*:\s*Nat -> List PsSyntaxName :=\s*match remaining with/,
  /\| 0 =>\s*fun \(_index : Nat\) =>\s*\[\]/,
  /let smaller\s*:\s*Nat -> List PsSyntaxName\s*:=\s*psElabWildcardBinderNamesWorker\s+span\s+nextRemaining/,
  /fun \(index : Nat\) =>[\s\S]*?psNatToString\s+index[\s\S]*?smaller\s+\(Nat\.succ index\)/,
  /def psElabWildcardBinderNames\s*\(span : PsSourceSpan\)\s*\(index : Nat\)\s*\(remaining : Nat\)\s*:\s*List PsSyntaxName :=\s*psElabWildcardBinderNamesWorker\s+span\s+remaining\s+index/,
]) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_WILDCARD_BINDER_NAMES_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

if (/\btoString\b/.test(block)) {
  throw new Error(
    "PSC2_ELAB_WILDCARD_BINDER_NAMES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: generic toString is outside the PSC1 selfhost surface",
  );
}

if (/psElabWildcardBinderNames\s+span\s+\(Nat\.succ index\)\s+nextRemaining/.test(block)) {
  throw new Error(
    "PSC2_ELAB_WILDCARD_BINDER_NAMES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: direct recursion changes invariant index argument",
  );
}

process.stdout.write(
  "PSC2_ELAB_WILDCARD_BINDER_NAMES_SELFHOST_SOURCE_SYNTAX: PASS (remaining-recursive worker, post-recursion index, project-owned Nat rendering)\n",
);
