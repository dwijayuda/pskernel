import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const sourcePath = path.join(
  root,
  "packages",
  "environment",
  "src",
  "Ps",
  "Environment",
  "SelfHostProd.lean",
);
const source = await readFile(sourcePath, "utf8");

for (const marker of [
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
]) {
  if (!source.includes(marker)) {
    throw new Error(`PSC2_SELFHOST_PROD_PSC1_LET_SYNTAX_MISSING: ${marker}`);
  }
}

process.stdout.write("PSC2_SELFHOST_PROD_SOURCE: PASS (PSC1 let sequencing)\n");
