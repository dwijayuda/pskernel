import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureSelectedArgumentsCons(source) {
  const selected = source.match(
    /def psEraseSelectedArguments[\s\S]*?(?=\ndef psEraseSelectedTypeArguments)/,
  )?.[0];
  const selectedTypes = source.match(
    /def psEraseSelectedTypeArguments[\s\S]*?(?=\ndef psEraseTypedIntrinsic)/,
  )?.[0];

  if (!selected || !selectedTypes) {
    throw new Error(
      "PSC2_ERASURE_SELECTED_ARGUMENTS_CONS_SELFHOST_SOURCE_SYNTAX_MISSING: declaration blocks",
    );
  }

  for (const block of [selected, selectedTypes]) {
    if (!/Except\.ok \(List\.cons erased erasedRest\)/.test(block)) {
      throw new Error(
        "PSC2_ERASURE_SELECTED_ARGUMENTS_CONS_SELFHOST_SOURCE_SYNTAX_MISSING: explicit List.cons result",
      );
    }
    if (/Except\.ok \(erased\s*::\s*erasedRest\)/.test(block)) {
      throw new Error(
        "PSC2_ERASURE_SELECTED_ARGUMENTS_CONS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: term-level cons syntax",
      );
    }
  }
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
assertErasureSelectedArgumentsCons(source);
process.stdout.write(
  "PSC2_ERASURE_SELECTED_ARGUMENTS_CONS_SELFHOST_SOURCE_SYNTAX: PASS (explicit List.cons for selected runtime/type argument result accumulation)\n",
);
