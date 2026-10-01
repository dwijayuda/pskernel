import { readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const node = process.execPath;

function run(args) {
  const result = spawnSync(node, args, {
    cwd: root,
    stdio: "inherit",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`PSC1_BUILD_CURRENT_STEP_FAILED: ${args.join(" ")}`);
  }
}

const config = JSON.parse(
  await readFile(path.join(root, "psconfig.json"), "utf8"),
);
if (!config.entry) {
  throw new Error("PSC1_BUILD_CURRENT_ENTRY_MISSING");
}

const compiler =
  process.env.PSC_COMPILER ??
  path.join("dist", "bootstrap", "packages", "compiler", "index.js");
if (!existsSync(path.join(root, compiler))) {
  throw new Error(`PSC1_BUILD_CURRENT_COMPILER_MISSING: ${compiler}`);
}

const outRoot = process.env.PSC_OUT_DIR ?? path.join("dist", "current");
const psWorkspace = path.join(outRoot, "ps");
const leanWorkspace = path.join(outRoot, "lean");
const jsCompiler = path.join(outRoot, "packages", "compiler", "index.js");

run([
  "scripts/emit-project-with-generated.mjs",
  compiler,
  config.entry,
  "--to",
  "ps",
  "--out",
  psWorkspace,
]);

const psEntry = config.entry.replace(/\.(lean|ps)$/u, ".ps");

run([
  "scripts/emit-project-with-generated.mjs",
  compiler,
  path.join(psWorkspace, psEntry),
  "--to",
  "lean",
  "--out",
  leanWorkspace,
]);

run([
  "scripts/compile-with-generated.mjs",
  compiler,
  path.join(psWorkspace, psEntry),
  jsCompiler,
]);

const manifest = {
  schemaVersion: 1,
  sourceEntry: config.entry,
  proofScriptEntry: path.join(psWorkspace, psEntry).replaceAll(path.sep, "/"),
  leanEntry: path.join(
    leanWorkspace,
    config.entry.replace(/\.(lean|ps)$/u, ".lean"),
  ).replaceAll(path.sep, "/"),
  compiler: jsCompiler.replaceAll(path.sep, "/"),
};

await writeFile(
  path.join(root, outRoot, ".proofscript-build.json"),
  JSON.stringify(manifest, null, 2) + "\n",
  "utf8",
);

process.stdout.write(
  [
    `PSC1_BUILD_CURRENT_PS: ${manifest.proofScriptEntry}`,
    `PSC1_BUILD_CURRENT_LEAN: ${manifest.leanEntry}`,
    `PSC1_BUILD_CURRENT_JS: ${manifest.compiler}`,
  ].join("\n") + "\n",
);
