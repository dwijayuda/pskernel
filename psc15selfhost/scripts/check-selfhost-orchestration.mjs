import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const packageJson = JSON.parse(
  await readFile(path.join(root, "package.json"), "utf8"),
);
const scripts = packageJson.scripts ?? {};

function requireScript(name, expected) {
  const actual = scripts[name];
  if (actual !== expected) {
    throw new Error(
      `PSC2_SELFHOST_SCRIPT_MISMATCH: ${name}\nexpected=${expected}\nactual=${actual ?? "<missing>"}`,
    );
  }
}

const files = [
  "scripts/bootstrap-project.mjs",
  "scripts/selfhost-generation.mjs",
  "scripts/reemit-project-with-generated.mjs",
  "scripts/compile-with-generated.mjs",
  "scripts/compare-source-workspaces.mjs",
  "scripts/compare-selfhost.mjs",
  "packages/cli/bin/psc.mjs",
];
for (const relativePath of files) {
  if (!existsSync(path.join(root, relativePath))) {
    throw new Error(`PSC2_SELFHOST_ORCHESTRATION_FILE_MISSING: ${relativePath}`);
  }
}

requireScript(
  "bootstrap:emit",
  "node scripts/bootstrap-project.mjs",
);
requireScript(
  "bootstrap:compiler",
  "lake exe psc1 build dist/bootstrap/workspace/packages/bootstrap/src/Ps/Bootstrap/SelfHost.ps --out dist/bootstrap/packages/compiler/index.js",
);
requireScript(
  "selfhost",
  "node packages/cli/bin/psc.mjs selfhost --compiler dist/bootstrap/packages/compiler/index.js --workspace dist/bootstrap/workspace --out dist/selfhost",
);
requireScript(
  "selfhost:emit-source",
  "node scripts/reemit-project-with-generated.mjs dist/bootstrap/packages/compiler/index.js dist/bootstrap/workspace dist/selfhost/workspace",
);
requireScript(
  "selfhost:compiler",
  "node scripts/compile-with-generated.mjs dist/bootstrap/packages/compiler/index.js dist/selfhost/workspace/packages/bootstrap/src/Ps/Bootstrap/SelfHost.ps dist/selfhost/packages/compiler/index.js",
);
requireScript(
  "verify:source",
  "node scripts/compare-source-workspaces.mjs dist/bootstrap/workspace dist/selfhost/workspace",
);
requireScript(
  "verify:compiler",
  "node scripts/compare-selfhost.mjs dist/bootstrap/packages/compiler/index.ts dist/selfhost/packages/compiler/index.ts",
);
requireScript(
  "verify:selfhost",
  "npm run verify:source && npm run verify:compiler",
);
requireScript(
  "fixed-point",
  "npm run bootstrap && npm run selfhost && npm run verify:selfhost",
);

const selfhostGeneration = await readFile(
  path.join(root, "scripts", "selfhost-generation.mjs"),
  "utf8",
);
for (const requiredPath of [
  'path.join(outputGeneration, "workspace")',
  'path.join(outputGeneration, "packages",',
  '"compiler",',
  '"index.js",',
]) {
  if (!selfhostGeneration.includes(requiredPath)) {
    throw new Error(
      `PSC2_SELFHOST_GENERATION_LAYOUT_DRIFT: missing ${requiredPath}`,
    );
  }
}

process.stdout.write(
  `PSC2_SELFHOST_ORCHESTRATION: PASS (${files.length} files; 9 script contracts)\n`,
);
