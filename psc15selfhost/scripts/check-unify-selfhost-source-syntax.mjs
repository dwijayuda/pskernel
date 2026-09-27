import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const unify = await readFile(
  path.join(root, "packages/meta/src/Ps/Meta/Unify.lean"),
  "utf8",
);

const required = [
  "let unified := psLevelUnify context.levels left right;\n      if unified.success then",
  "let leftValue := psWhnf environment context localContext left;\n      let rightValue := psWhnf environment context localContext right;\n      if psExprAlphaEq leftValue rightValue then",
  "let unified := psLevelUnify context.levels leftLevel rightLevel;\n            if unified.success then",
  "                rightFn;\n            if fnResult.success then",
  "                rightType;\n            if typeResult.success then",
  "                  PsBinderInfo.explicit;\n              let fvar := PsExpr.fvar pushed.id;\n              psUnifyWithFuel",
  "    psUnifyWithFuel environment localContext context 512 left right;\n  if result.success then",
];
for (const marker of required) {
  if (!unify.includes(marker)) {
    throw new Error(`PSC2_UNIFY_SELFHOST_SOURCE_SYNTAX_MISSING: ${marker}`);
  }
}

const forbidden = [
  "let unified := psLevelUnify context.levels left right\n      if unified.success then",
  "let leftValue := psWhnf environment context localContext left\n      let rightValue :=",
  "let rightValue := psWhnf environment context localContext right\n      if psExprAlphaEq",
  "let unified := psLevelUnify context.levels leftLevel rightLevel\n            if unified.success then",
  "                rightFn\n            if fnResult.success then",
  "                rightType\n            if typeResult.success then",
  "                  PsBinderInfo.explicit\n              let fvar :=",
  "let fvar := PsExpr.fvar pushed.id\n              psUnifyWithFuel",
  "    psUnifyWithFuel environment localContext context 512 left right\n  if result.success then",
];
for (const marker of forbidden) {
  if (unify.includes(marker)) {
    throw new Error(`PSC2_UNIFY_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${marker}`);
  }
}

process.stdout.write(
  "PSC2_UNIFY_SELFHOST_SOURCE_SYNTAX: PASS (all term-level let continuations explicitly sequenced)\n",
);
