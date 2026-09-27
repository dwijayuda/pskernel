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
  'let resolved := psLevelInstantiate context value;',
  'PsLevelAssignment.mk id resolved',
  'let leftValue := psLevelInstantiate context left;',
  'let rightValue := psLevelInstantiate context right;',
  'let first := psLevelUnifyWithFuel context fuel leftA rightA;',
  'let first := psLevelUnifyWithFuel context fuel leftA rightA;',
]);
forbidMarkers("LevelContext", levelContext, [
  'List.cons { id := id, value := resolved } context.assignments',
]);

process.stdout.write(
  "PSC2_SELFHOST_SOURCE_SYNTAX: PASS (PSC1 let/application subset)\n",
);
