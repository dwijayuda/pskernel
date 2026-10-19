import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function assertErasureSelectedArgumentsIndex(source, basic) {
  const helper = basic.match(
    /def psErasureExprListAtWorker[\s\S]*?(?=\ndef psErasurePrimitiveType)/,
  )?.[0];
  if (
    !helper ||
    !/\(index : Nat\)\s*:\s*List PsExpr -> Option PsExpr/.test(helper) ||
    !/match index with/.test(helper) ||
    !/\| 0 =>[\s\S]*?Option\.some value/.test(helper) ||
    !/\| nextIndex \+ 1 =>[\s\S]*?psErasureExprListAtWorker nextIndex;[\s\S]*?_ :: rest => smaller rest/.test(helper) ||
    !/def psErasureExprListAt\s*\(values : List PsExpr\)\s*\(index : Nat\) : Option PsExpr :=\s*psErasureExprListAtWorker\s+index\s+values/.test(helper)
  ) {
    throw new Error(
      "PSC2_ERASURE_SELECTED_ARGUMENTS_INDEX_SELFHOST_SOURCE_SYNTAX_MISSING: structural PsExpr list lookup",
    );
  }

  const selected = source.match(
    /def psEraseSelectedArguments[\s\S]*?(?=\ndef psEraseSelectedTypeArguments)/,
  )?.[0];
  const selectedTypes = source.match(
    /def psEraseSelectedTypeArguments[\s\S]*?(?=\ndef psEraseTypedIntrinsic)/,
  )?.[0];
  if (!selected || !selectedTypes) {
    throw new Error(
      "PSC2_ERASURE_SELECTED_ARGUMENTS_INDEX_SELFHOST_SOURCE_SYNTAX_MISSING: declaration blocks",
    );
  }
  for (const block of [selected, selectedTypes]) {
    if (!/match psErasureExprListAt arguments index with/.test(block)) {
      throw new Error(
        "PSC2_ERASURE_SELECTED_ARGUMENTS_INDEX_SELFHOST_SOURCE_SYNTAX_MISSING: helper use",
      );
    }
    if (/arguments\s*\[\s*index\s*\]\?/.test(block)) {
      throw new Error(
        "PSC2_ERASURE_SELECTED_ARGUMENTS_INDEX_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: optional indexing syntax",
      );
    }
  }
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Expr.lean"),
  "utf8",
);
const basic = await readFile(path.join(root, "packages/erasure/src/Ps/Erasure/Basic.lean"), "utf8");
assertErasureSelectedArgumentsIndex(source, basic);
process.stdout.write(
  "PSC2_ERASURE_SELECTED_ARGUMENTS_INDEX_SELFHOST_SOURCE_SYNTAX: PASS (PSC1 structural PsExpr list lookup across runtime/type intrinsic selections)\n",
);
