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
  'if psLevelHasMVar left then',
  'if psLevelHasMVar level then',
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
  '||',
]);

process.stdout.write(
  "PSC2_SELFHOST_SOURCE_SYNTAX: PASS (PSC1 invariant-fuel/let/application/unary-match/no-bool-infix subset)\n",
);
