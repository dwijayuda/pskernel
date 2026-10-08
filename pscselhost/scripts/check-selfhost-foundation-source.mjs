import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const environmentDir = path.join(
  root,
  "packages",
  "environment",
  "src",
  "Ps",
  "Environment",
);

async function source(name) {
  return readFile(path.join(environmentDir, name), "utf8");
}

function requireMarkers(label, text, markers) {
  for (const marker of markers) {
    if (!text.includes(marker)) {
      throw new Error(`PSC2_SELFHOST_FOUNDATION_PSC1_LET_SYNTAX_MISSING: ${label}: ${marker}`);
    }
  }
}

const prelude = await source("SelfHostPrelude.lean");
requireMarkers("SelfHostPrelude", prelude, [
  'let uName := psRootName "u";',
  'let alphaName := psRootName "α";',
  'let errorTypeName := psRootName "ε";',
  'let majorName := psRootName "_major";',
  'let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero);',
  'PsBinderInfo.explicit;\n  let nilType :=',
  'PsBinderInfo.implicit;\n  let consType :=',
  'PsBinderInfo.implicit;\n  let optionType :=',
  'PsBinderInfo.implicit;\n  let exceptType :=',
  'false));\n  let withNil :=',
  '[]));\n  let withCons :=',
  '2));\n  let withOption :=',
  'false));\n  let withExceptError :=',
  '[]));\n  let withExceptOk :=',
]);

const prod = await source("SelfHostProd.lean");
requireMarkers("SelfHostProd", prod, [
  'let uName := psRootName "u";',
  'let alphaName := psRootName "α";',
  'let betaName := psRootName "β";',
  'let motiveName := psRootName "_motive";',
  'let minorName := psRootName "_mk";',
  'let majorName := psRootName "_major";',
  'let fstName := psRootName "fst";',
  'let sndName := psRootName "snd";',
  'let typeType := PsExpr.sortE (PsLevel.succ PsLevel.zero);',
  'PsBinderInfo.explicit;\n  let prodMkType :=',
  'PsBinderInfo.implicit;\n  let motiveType :=',
  'PsBinderInfo.explicit;\n  let minorType :=',
  'PsBinderInfo.explicit;\n  let recType :=',
  'PsBinderInfo.implicit;\n  let withProd :=',
  'true));\n  let withProdMk :=',
  '[]));\n  psPreludeAdd withProdMk',
]);

process.stdout.write(
  "PSC2_SELFHOST_FOUNDATION_SOURCE: PASS (PSC1 let sequencing: List, Option, Except, Prod)\n",
);
