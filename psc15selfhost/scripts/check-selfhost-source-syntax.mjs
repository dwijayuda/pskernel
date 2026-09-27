import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");

async function read(relativePath) {
  return readFile(path.join(root, ...relativePath.split("/")), "utf8");
}

function requireMarkers(label, text, markers) {
  for (const marker of markers) {
    if (!text.includes(marker)) {
      throw new Error(`PSC2_SELFHOST_SOURCE_SYNTAX_MISSING: ${label}: ${marker}`);
    }
  }
}

function forbidMarkers(label, text, markers) {
  for (const marker of markers) {
    if (text.includes(marker)) {
      throw new Error(`PSC2_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${label}: ${marker}`);
    }
  }
}

const prelude = await read(
  "packages/environment/src/Ps/Environment/SelfHostPrelude.lean",
);
requireMarkers("SelfHostPrelude", prelude, [
  'let uName := psRootName "u";',
  'let majorName := psRootName "_major";',
  'let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero);',
  'PsBinderInfo.explicit;\n  let nilType :=',
  'PsBinderInfo.implicit;\n  let optionType :=',
  'PsBinderInfo.implicit;\n  let exceptType :=',
  'false));\n  let withNil :=',
  '2));\n  let withOption :=',
]);

const prod = await read(
  "packages/environment/src/Ps/Environment/SelfHostProd.lean",
);
requireMarkers("SelfHostProd", prod, [
  'let uName := psRootName "u";',
  'let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero);',
  'PsBinderInfo.explicit;\n  let prodMkType :=',
  'PsBinderInfo.implicit;\n  let motiveType :=',
  'PsBinderInfo.explicit;\n  let minorType :=',
  'PsBinderInfo.explicit;\n  let recType :=',
  'PsBinderInfo.implicit;\n  let withProd :=',
]);

const levelContext = await read(
  "packages/meta/src/Ps/Meta/LevelContext.lean",
);
requireMarkers("LevelContext", levelContext, [
  'def psLevelFindAssignmentInList\n    (id : Nat)\n    (assignments : List PsLevelAssignment) : Option PsLevel :=\n  match assignments with',
  'def psLevelInstantiateWithFuel\n    (context : PsLevelMetaContext)\n    (fuel : Nat) : PsLevel -> PsLevel :=\n  match fuel with',
  '| Nat.zero =>\n      fun (level : PsLevel) => level',
  'let smaller : PsLevel -> PsLevel :=\n        psLevelInstantiateWithFuel context remaining;',
  'fun (level : PsLevel) =>\n        match level with',
  '| Option.some value => smaller value',
  'let resolved := psLevelInstantiate context value;',
  'PsLevelAssignment.mk id resolved',
  'def psLevelUnifyWithFuelWorker\n    (fuel : Nat) :\n    PsLevelMetaContext -> PsLevel -> PsLevel -> PsLevelUnifyResult :=\n  match fuel with',
  'let smaller : PsLevelMetaContext -> PsLevel -> PsLevel -> PsLevelUnifyResult :=\n        psLevelUnifyWithFuelWorker remaining;',
  'let leftValue := psLevelInstantiate context left;',
  'let rightValue := psLevelInstantiate context right;',
  'match leftValue with',
  '| _ =>\n              match rightValue with',
  'match psLevelAssign context id leftValue with',
  'match rightValue with',
  'let first := smaller context leftA rightA;',
  'smaller first.context leftB rightB',
  'psLevelUnifyWithFuelWorker fuel context left right',
  'def psLevelInstantiateList\n    (context : PsLevelMetaContext)\n    (levels : List PsLevel) : List PsLevel :=\n  match levels with',
  'List.cons\n        (psLevelInstantiate context level)\n        (psLevelInstantiateList context rest)',
  'def psLevelInstantiateExpr\n    (context : PsLevelMetaContext)\n    (expr : PsExpr) : PsExpr :=\n  match expr with',
  'PsExpr.constE name (psLevelInstantiateList context levels)',
  '| _ => expr',
  'def psLevelHasMVar\n    (level : PsLevel) : Bool :=\n  match level with',
  'if psLevelHasMVar left then',
  'def psLevelListHasMVar\n    (levels : List PsLevel) : Bool :=\n  match levels with',
  'if psLevelHasMVar level then',
  'psLevelListHasMVar rest',
]);
forbidMarkers("LevelContext", levelContext, [
  'def psLevelFindAssignmentInList (id : Nat) : List PsLevelAssignment -> Option PsLevel',
  'def psLevelInstantiateWithFuel\n    (context : PsLevelMetaContext) : Nat -> PsLevel -> PsLevel',
  '(fuel : Nat)\n    (level : PsLevel) : PsLevel :=',
  'psLevelInstantiateWithFuel context remaining value',
  'List.cons { id := id, value := resolved } context.assignments',
  'match leftValue, rightValue with',
  '| value =>\n              match rightValue with',
  'match psLevelAssign context id value with',
  'psLevelUnifyWithFuel context fuel leftA rightA',
  'psLevelUnifyWithFuel first.context fuel leftB rightB',
  'def psLevelInstantiateExpr (context : PsLevelMetaContext) : PsExpr -> PsExpr',
  'levels.map (psLevelInstantiate context)',
  '| expr => expr',
  'def psLevelHasMVar : PsLevel -> Bool',
  'def psLevelListHasMVar : List PsLevel -> Bool',
  '||',
]);

const metaContext = await read(
  "packages/meta/src/Ps/Meta/Context.lean",
);
requireMarkers("MetaContext", metaContext, [
  'def psMetaFindDeclInList\n    (id : Nat)\n    (declarations : List PsMetaVarDecl) : Option PsMetaVarDecl :=\n  match declarations with',
  'psMetaFindDeclInList id rest',
  'def psMetaFindAssignmentInList\n    (id : Nat)\n    (assignments : List PsMetaAssignment) : Option PsExpr :=\n  match assignments with',
  'psMetaFindAssignmentInList id rest',
  'def psMetaAssignmentListLength\n    (assignments : List PsMetaAssignment) : Nat :=\n  match assignments with',
  '| [] => 0',
  '| _ :: rest =>\n      Nat.succ (psMetaAssignmentListLength rest)',
  'def psExprContainsMVar\n    (target : Nat)\n    (expr : PsExpr) : Bool :=\n  match expr with',
  'def psExprFVarsInContext\n    (localContext : PsLocalContext)\n    (expr : PsExpr) : Bool :=\n  match expr with',
  'psExprFVarsInContext localContext body',
  'def psMetaInstantiateStep\n    (context : PsMetaContext)\n    (expr : PsExpr) : PsExpr :=\n  match expr with',
  'psMetaInstantiateStep context body',
  'def psMetaInstantiateRounds\n    (context : PsMetaContext)\n    (fuel : Nat) : PsExpr -> PsExpr :=\n  match fuel with',
  '| Nat.zero =>\n      fun (expr : PsExpr) => expr',
  'let smaller : PsExpr -> PsExpr :=\n        psMetaInstantiateRounds context remaining;',
  'fun (expr : PsExpr) =>\n        smaller (psMetaInstantiateStep context expr)',
  'psMetaInstantiateRounds\n      context\n      (Nat.add (psMetaAssignmentListLength context.assignments) 1)\n      expr;',
  'def psExprHasUnresolvedMeta\n    (expr : PsExpr) : Bool :=\n  match expr with',
  'psExprHasUnresolvedMeta body',
]);
forbidMarkers("MetaContext", metaContext, [
  'def psMetaFindDeclInList (id : Nat) : List PsMetaVarDecl -> Option PsMetaVarDecl',
  'def psMetaFindAssignmentInList (id : Nat) : List PsMetaAssignment -> Option PsExpr',
  'def psExprContainsMVar (target : Nat) : PsExpr -> Bool',
  'def psExprFVarsInContext (localContext : PsLocalContext) : PsExpr -> Bool',
  'def psMetaInstantiateStep\n    (context : PsMetaContext) : PsExpr -> PsExpr',
  'def psMetaInstantiateRounds\n    (context : PsMetaContext) :\n    Nat -> PsExpr -> PsExpr',
  '(fuel : Nat)\n    (expr : PsExpr) : PsExpr :=',
  '| remaining + 1, expr =>',
  'psMetaInstantiateRounds\n        context\n        remaining\n        (psMetaInstantiateStep context expr)',
  'context.assignments.length',
  'List.length context.assignments',
  'def psExprHasUnresolvedMeta : PsExpr -> Bool',
  '| expr => expr',
]);

const reduce = await read(
  "packages/meta/src/Ps/Meta/Reduce.lean",
);
requireMarkers("Reduce", reduce, [
  'let instantiated := psMetaInstantiate metaContext expr;\n      match instantiated with',
  '| some declaration =>\n              match declaration with\n              | .letDecl _ _ _ value =>',
  'let reducedFn := psWhnfCoreWithFuel metaContext localContext fuel fn;\n          match reducedFn with',
  'let leftValue := psWhnfCore metaContext localContext left;\n  let rightValue := psWhnfCore metaContext localContext right;',
  'let core := psWhnfCoreWithFuel metaContext localContext fuel expr;\n      match core with',
  'let parameters := psDeclarationLevelParams declaration;\n                  if parameters.length == levels.length then',
  'let reducedFn :=\n            psWhnfWithFuel environment metaContext localContext fuel fn;\n          if psExprAlphaEq reducedFn fn then',
  'let leftValue :=\n        psWhnf environment metaContext localContext left;\n      let rightValue :=\n        psWhnf environment metaContext localContext right;',
]);
forbidMarkers("Reduce", reduce, [
  'let instantiated := psMetaInstantiate metaContext expr\n      match instantiated with',
  '| some (.letDecl _ _ _ value) =>',
  'let reducedFn := psWhnfCoreWithFuel metaContext localContext fuel fn\n          match reducedFn with',
  'let leftValue := psWhnfCore metaContext localContext left\n  let rightValue :=',
  'let rightValue := psWhnfCore metaContext localContext right\n  psExprAlphaEq',
  'let core := psWhnfCoreWithFuel metaContext localContext fuel expr\n      match core with',
  'let parameters := psDeclarationLevelParams declaration\n                  if parameters.length == levels.length then',
  'psWhnfWithFuel environment metaContext localContext fuel fn\n          if psExprAlphaEq reducedFn fn then',
  'psWhnf environment metaContext localContext left\n      let rightValue :=',
  'psWhnf environment metaContext localContext right\n      if psExprAlphaEq leftValue rightValue then',
]);

process.stdout.write(
  "PSC2_SELFHOST_SOURCE_SYNTAX: PASS (PSC1 explicit-recursion/invariant-fuel/local-list-ops/let/application/unary-match/no-bool-infix subset)\n",
);
