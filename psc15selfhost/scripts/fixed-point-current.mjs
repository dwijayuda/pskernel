import { existsSync } from "node:fs";
import { readFile, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import {
  canonicalGeneratedPaths,
  computeBootstrapWorkspaceClosureSha256,
  assertBootstrapWorkspaceManifest,
} from "./bootstrap-manifest.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const node = process.execPath;

const currentRoot =
  process.env.PSC_CURRENT_OUT_DIR ?? path.join("dist", "current-fixed-point");
const nextRoot =
  process.env.PSC_CURRENT_NEXT_OUT_DIR ?? path.join("dist", "current-fixed-point-next");
const provenWorkspace =
  process.env.PSC_PROVEN_WORKSPACE ?? path.join("dist", "bootstrap", "workspace");
const provenSelfhost =
  process.env.PSC_PROVEN_SELFHOST ?? path.join("dist", "selfhost");
const defaultCompiler = path.join(
  "dist",
  "bootstrap",
  "packages",
  "compiler",
  "index.js",
);
const parentCompiler = process.env.PSC_COMPILER ?? defaultCompiler;

function run(args, extraEnv = {}) {
  const result = spawnSync(node, args, {
    cwd: root,
    stdio: "inherit",
    env: { ...process.env, ...extraEnv },
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`PSC2_CURRENT_FIXED_POINT_STEP_FAILED: ${args.join(" ")}`);
  }
}

async function currentMatchesProven(currentWorkspace) {
  if (path.normalize(parentCompiler) !== path.normalize(defaultCompiler)) {
    return false;
  }

  const currentManifest = JSON.parse(
    await readFile(
      path.join(root, currentWorkspace, ".proofscript-project.json"),
      "utf8",
    ),
  );
  if (
    currentManifest === null ||
    typeof currentManifest !== "object" ||
    currentManifest.schemaVersion !== 1 ||
    typeof currentManifest.entry !== "string"
  ) {
    throw new Error("PSC2_CURRENT_FIXED_POINT_PROJECT_MANIFEST");
  }
  const currentFiles = canonicalGeneratedPaths(currentManifest.generated);
  if (currentManifest.sourceCount !== currentFiles.length) {
    throw new Error("PSC2_CURRENT_FIXED_POINT_PROJECT_COUNT");
  }

  const provenRoot = path.join(root, provenWorkspace);
  const provenManifest = JSON.parse(
    await readFile(
      path.join(provenRoot, ".proofscript-bootstrap.json"),
      "utf8",
    ),
  );
  const provenHash = await assertBootstrapWorkspaceManifest(
    provenRoot,
    provenManifest,
    "bootstrap",
  );
  const provenFiles = canonicalGeneratedPaths(provenManifest.generated);

  if (currentManifest.entry !== provenManifest.entry) return false;
  if (JSON.stringify(currentFiles) !== JSON.stringify(provenFiles)) return false;

  const currentHash = await computeBootstrapWorkspaceClosureSha256(
    path.join(root, currentWorkspace),
    currentManifest.entry,
    currentFiles,
  );
  if (currentHash !== provenHash) return false;

  for (const relativePath of currentFiles) {
    const [currentSource, provenSource] = await Promise.all([
      readFile(path.join(root, currentWorkspace, relativePath)),
      readFile(path.join(provenRoot, relativePath)),
    ]);
    if (!currentSource.equals(provenSource)) return false;
  }
  return true;
}

const config = JSON.parse(
  await readFile(path.join(root, "psconfig.json"), "utf8"),
);
if (!config.entry) {
  throw new Error("PSC2_CURRENT_FIXED_POINT_ENTRY_MISSING");
}
if (!existsSync(path.join(root, parentCompiler))) {
  throw new Error(`PSC2_CURRENT_FIXED_POINT_COMPILER_MISSING: ${parentCompiler}`);
}

await rm(path.join(root, currentRoot), { recursive: true, force: true });
await rm(path.join(root, nextRoot), { recursive: true, force: true });

const currentWorkspace = path.join(currentRoot, "workspace");
run([
  "scripts/emit-project-with-generated.mjs",
  parentCompiler,
  config.entry,
  "--to",
  "ps",
  "--out",
  currentWorkspace,
]);

if (await currentMatchesProven(currentWorkspace)) {
  run([
    "scripts/compare-source-workspaces.mjs",
    provenWorkspace,
    path.join(provenSelfhost, "workspace"),
  ]);
  run([
    "scripts/compare-compiler-artifacts.mjs",
    path.join("dist", "bootstrap", "packages", "compiler", "index.ts"),
    path.join(provenSelfhost, "packages", "compiler", "index.ts"),
  ]);
  process.stdout.write(
    [
      "PSC2_CURRENT_JS_FIXED_POINT: PASS",
      "mode=reused-proven-bootstrap",
      `current=${currentWorkspace}`,
    ].join("\n") + "\n",
  );
  process.exit(0);
}

const currentCompiler = path.join(
  currentRoot,
  "packages",
  "compiler",
  "index.js",
);
const currentCompilerTs = path.join(
  currentRoot,
  "packages",
  "compiler",
  "index.ts",
);
const currentEntry = path.join(
  currentWorkspace,
  config.entry.replace(/\.(lean|ps)$/u, ".ps"),
);

run([
  "scripts/compile-with-generated.mjs",
  parentCompiler,
  currentEntry,
  currentCompiler,
]);

run([
  "scripts/selfhost-generation.mjs",
  currentCompiler,
  currentWorkspace,
  nextRoot,
]);

const nextWorkspace = path.join(nextRoot, "workspace");
const nextCompilerTs = path.join(
  nextRoot,
  "packages",
  "compiler",
  "index.ts",
);

run([
  "scripts/compare-generated-source-workspaces.mjs",
  currentWorkspace,
  nextWorkspace,
]);
run([
  "scripts/compare-compiler-artifacts.mjs",
  currentCompilerTs,
  nextCompilerTs,
]);

process.stdout.write(
  [
    "PSC2_CURRENT_JS_FIXED_POINT: PASS",
    "mode=recompiled-current-source",
    `current=${currentRoot}`,
    `next=${nextRoot}`,
  ].join("\n") + "\n",
);
