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
  "selfhost:emit-lean",
  "node scripts/emit-project-with-generated.mjs dist/selfhost/packages/compiler/index.js dist/selfhost/workspace/packages/bootstrap/src/Ps/Bootstrap/SelfHost.ps --to lean --out dist/selfhost/lean",
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

if (!scripts["test:all"]?.includes("npm run test:kernel-core")) {
  throw new Error("PSC2_SELFHOST_KERNEL_TESTS_NOT_IN_FULL_SUITE");
}

const selfhostGeneration = await readFile(
  path.join(root, "scripts", "selfhost-generation.mjs"),
  "utf8",
);
const generationLayoutPatterns = [
  /path\.join\(\s*outputGeneration,\s*"workspace"\s*\)/u,
  /path\.join\(\s*outputGeneration,\s*"packages",\s*"compiler",\s*"index\.js",?\s*\)/u,
];
for (const pattern of generationLayoutPatterns) {
  if (!pattern.test(selfhostGeneration)) {
    throw new Error(
      `PSC2_SELFHOST_GENERATION_LAYOUT_DRIFT: ${pattern.source}`,
    );
  }
}
if (/leanWorkspace|outputLean/u.test(selfhostGeneration)) {
  throw new Error("PSC2_SELFHOST_LEAN_WORKSPACE_IN_CRITICAL_PATH");
}
if (
  /emit-project-with-generated\.mjs[\s\S]*?"--to"[\s\S]*?"lean"/u.test(
    selfhostGeneration,
  )
) {
  throw new Error("PSC2_SELFHOST_LEAN_EMIT_IN_CRITICAL_PATH");
}

const cli = await readFile(
  path.join(root, "packages", "cli", "bin", "psc.mjs"),
  "utf8",
);
const cliSelfhostForwarding =
  /"scripts\/selfhost-generation\.mjs",\s*compiler,\s*workspace,\s*output,/u;
if (!cliSelfhostForwarding.test(cli)) {
  throw new Error("PSC2_SELFHOST_CLI_FORWARDING_DRIFT");
}

process.stdout.write(
  `PSC2_SELFHOST_ORCHESTRATION: PASS (${files.length} files; 10 script contracts; minimal generation path; optional Lean assurance; kernel full-suite coverage)\n`,
);
