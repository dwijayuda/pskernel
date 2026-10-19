import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const workerStart = source.indexOf("def psElabApplyArgsWithFuelWorker\n");
const wrapperStart = source.indexOf("def psElabApplyArgsWithFuel\n");
const blockStart = workerStart >= 0 ? workerStart : wrapperStart;
const end = source.indexOf("\ndef psElabApplyArgs\n", wrapperStart + 1);
if (blockStart < 0 || wrapperStart < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_APPLY_ARGS_OPTION_SELFHOST_SOURCE_SYNTAX_MISSING: apply-args worker/wrapper block",
  );
}

const block = source.slice(blockStart, end);
if (!/\(\s*Option\.some\s+domain\s*\)/m.test(block)) {
  throw new Error(
    "PSC2_ELAB_APPLY_ARGS_OPTION_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some domain expectation",
  );
}
if (/\(\s*some\s+domain\s*\)/m.test(block)) {
  throw new Error(
    "PSC2_ELAB_APPLY_ARGS_OPTION_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: unqualified some domain value remains",
  );
}

process.stdout.write(
  "PSC2_ELAB_APPLY_ARGS_OPTION_SELFHOST_SOURCE_SYNTAX: PASS (explicit Option.some domain application expectation)\n",
);
