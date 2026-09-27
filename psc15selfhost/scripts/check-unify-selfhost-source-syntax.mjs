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
  /let unified := psLevelUnify context\.levels left right;\s*if unified\.success then/,
  /let leftValue := psWhnf environment context localContext left;\s*let rightValue := psWhnf environment context localContext right;\s*if psExprAlphaEq leftValue rightValue then/,
  /match leftValue with\s*\| \.mvar leftId =>\s*match rightValue with/,
  /\| leftOther =>\s*match rightValue with\s*\| \.mvar id =>/,
  /if Nat\.beq leftId rightId then/,
  /else if psMetaVarIsNatural context rightId then\s*if psMetaVarIsNatural context leftId then\s*if psMetaVarAssignable context leftId then/,
  /if Nat\.beq leftIndex rightIndex then/,
  /if psNameEq leftType rightType then\s*if Nat\.beq leftIndex rightIndex then/,
  /let unified := psLevelUnify context\.levels leftLevel rightLevel;\s*if unified\.success then/,
  /rightFn;\s*if fnResult\.success then/,
  /rightType;\s*if typeResult\.success then/,
  /PsBinderInfo\.explicit;\s*let fvar := PsExpr\.fvar pushed\.id;\s*psUnifyWithFuel/,
  /psUnifyWithFuel environment localContext context 512 left right;\s*if result\.success then/,
];
for (const pattern of required) {
  if (!pattern.test(unify)) {
    throw new Error(`PSC2_UNIFY_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`);
  }
}

const forbidden = [
  /match leftValue\s*,\s*rightValue with/,
  /==/,
  /&&/,
  /!\s*psMetaVarIsNatural/,
  /let unified := psLevelUnify context\.levels left right\s+if unified\.success then/,
  /let leftValue := psWhnf environment context localContext left\s+let rightValue :=/,
  /let rightValue := psWhnf environment context localContext right\s+if psExprAlphaEq/,
  /let unified := psLevelUnify context\.levels leftLevel rightLevel\s+if unified\.success then/,
  /rightFn\s+if fnResult\.success then/,
  /rightType\s+if typeResult\.success then/,
  /PsBinderInfo\.explicit\s+let fvar :=/,
  /let fvar := PsExpr\.fvar pushed\.id\s+psUnifyWithFuel/,
  /psUnifyWithFuel environment localContext context 512 left right\s+if result\.success then/,
];
for (const pattern of forbidden) {
  if (pattern.test(unify)) {
    throw new Error(`PSC2_UNIFY_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`);
  }
}

process.stdout.write(
  "PSC2_UNIFY_SELFHOST_SOURCE_SYNTAX: PASS (explicit let sequencing, unary matching, explicit Nat equality, explicit boolean control flow)\n",
);
