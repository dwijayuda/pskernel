import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const start = source.indexOf("def psElabApplyArgsWithFuelWorker\n");
const end = source.indexOf("\ndef psElabApplyArgsWithFuel\n", start);
if (start < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_APPLY_ARGS_NEXT_PENDING_SELFHOST_SOURCE_SYNTAX_MISSING: psElabApplyArgsWithFuelWorker block",
  );
}

const block = source.slice(start, end);
if (!/let\s+nextPending\s*:\s*List\s+Nat\s*:=/m.test(block)) {
  throw new Error(
    "PSC2_ELAB_APPLY_ARGS_NEXT_PENDING_SELFHOST_SOURCE_SYNTAX_MISSING: explicit List Nat expected type",
  );
}
if (/let\s+nextPending\s*:=/m.test(block)) {
  throw new Error(
    "PSC2_ELAB_APPLY_ARGS_NEXT_PENDING_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: untyped nextPending match initializer remains",
  );
}

process.stdout.write(
  "PSC2_ELAB_APPLY_ARGS_NEXT_PENDING_SELFHOST_SOURCE_SYNTAX: PASS (explicit List Nat expected type for nested match)\n",
);
