import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);

const workerStart = source.indexOf("def psCloseElabImplicitBindersWorker\n");
const wrapperStart = source.indexOf("\ndef psCloseElabImplicitBinders\n", workerStart + 1);
const end = source.indexOf("\ndef psExprListAlphaEq", wrapperStart + 1);
if (workerStart < 0 || wrapperStart < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_CLOSE_IMPLICIT_BINDERS_SELFHOST_SOURCE_SYNTAX_MISSING: worker/wrapper declaration block",
  );
}

const worker = source.slice(workerStart, wrapperStart);
const wrapper = source.slice(wrapperStart, end);
const required = [
  /\(binders\s*:\s*List PsElabTypedBinder\)\s*:\s*\n\s*PsMetaContext\s*->\s*PsExpr\s*->\s*PsExpr\s*:=/,
  /match\s+binders\s+with/,
  /\| List\.nil =>\s*fun \(_metaContext\s*:\s*PsMetaContext\) =>\s*fun \(body\s*:\s*PsExpr\) => body/,
  /\| List\.cons binder rest =>/,
  /let smaller\s*:\s*PsMetaContext\s*->\s*PsExpr\s*->\s*PsExpr\s*:=\s*\n\s*psCloseElabImplicitBindersWorker rest\s*;/,
  /fun \(metaContext\s*:\s*PsMetaContext\) =>/,
  /fun \(body\s*:\s*PsExpr\) =>/,
  /smaller metaContext closed/,
];
for (const pattern of required) {
  if (!pattern.test(worker)) {
    throw new Error(
      `PSC2_ELAB_CLOSE_IMPLICIT_BINDERS_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

if (!/psCloseElabImplicitBindersWorker\s+binders\s+metaContext\s+body/.test(wrapper)) {
  throw new Error(
    "PSC2_ELAB_CLOSE_IMPLICIT_BINDERS_SELFHOST_SOURCE_SYNTAX_MISSING: thin wrapper delegates to binder-recursive worker",
  );
}

const block = source.slice(workerStart, end);
const forbidden = [
  /\|\s*\[\]\s*,\s*body\s*=>/,
  /\|\s*binder\s*::\s*rest\s*,\s*body\s*=>/,
  /psCloseElabImplicitBinders\s+metaContext\s+rest\s+closed/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_CLOSE_IMPLICIT_BINDERS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_CLOSE_IMPLICIT_BINDERS_SELFHOST_SOURCE_SYNTAX: PASS (binder-recursive worker; meta-context/body applied post-recursion; no multi-argument equation matching)\n",
);