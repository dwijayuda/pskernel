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
  /def psCloseElabMatchFieldsWorker([\s\S]*?)(?=\nstructure PsElabMatchMinorResult)/,
);

if (blockMatch === null) {
  throw new Error(
    "PSC2_ELAB_CLOSE_MATCH_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: fields-recursive worker with post-recursion term accumulator",
  );
}

const block = blockMatch[0];
for (const pattern of [
  /def psCloseElabMatchFieldsWorker\s*\(metaContext : PsMetaContext\)\s*\(fields : List PsElabMatchField\)\s*:\s*PsExpr -> PsExpr :=\s*match fields with/,
  /let smaller\s*:\s*PsExpr -> PsExpr\s*:=\s*psCloseElabMatchFieldsWorker\s+metaContext\s+rest/,
  /fun \(term : PsExpr\) =>[\s\S]*?let closed :=[\s\S]*?PsExpr\.lam[\s\S]*?smaller\s+closed/,
  /def psCloseElabMatchFields\s*\(metaContext : PsMetaContext\)\s*\(fields : List PsElabMatchField\)\s*\(term : PsExpr\)\s*:\s*PsExpr :=\s*psCloseElabMatchFieldsWorker\s+metaContext\s+fields\s+term/,
]) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_CLOSE_MATCH_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

if (/psCloseElabMatchFields\s+metaContext\s+rest\s+closed/.test(block)) {
  throw new Error(
    "PSC2_ELAB_CLOSE_MATCH_FIELDS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: direct recursion changes invariant term argument",
  );
}

process.stdout.write(
  "PSC2_ELAB_CLOSE_MATCH_FIELDS_SELFHOST_SOURCE_SYNTAX: PASS (field-list-recursive worker with post-recursion term accumulator)\n",
);
