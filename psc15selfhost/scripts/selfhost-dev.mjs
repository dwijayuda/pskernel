import { existsSync } from "node:fs";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { createInterface } from "node:readline";
import { createGeneratedCompilerSession } from "./generated-compiler-session.mjs";
import { compileTypeScriptCached } from "./compile-typescript-cached.mjs";
import { sha256Bytes } from "./cache-utils.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const node = process.execPath;

const config = JSON.parse(
  await readFile(path.join(root, "psconfig.json"), "utf8"),
);
if (!config.entry) throw new Error("PSC2_DEV_ENTRY_MISSING");

const parentCompiler =
  process.env.PSC_COMPILER ??
  path.join("dist", "bootstrap", "packages", "compiler", "index.js");
const outRoot =
  process.env.PSC_DEV_OUT_DIR ?? path.join("dist", "dev-selfhost");
const nextRoot =
  process.env.PSC_DEV_NEXT_OUT_DIR ?? path.join("dist", "dev-selfhost-next");
const currentWorkspace = path.join(outRoot, "workspace");
const nextWorkspace = path.join(nextRoot, "workspace");
const currentEntry = path.join(
  currentWorkspace,
  config.entry.replace(/\.(lean|ps)$/u, ".ps"),
);
const nextEntry = path.join(
  nextWorkspace,
  config.entry.replace(/\.(lean|ps)$/u, ".ps"),
);
const currentCompilerTs = path.join(
  outRoot,
  "packages",
  "compiler",
  "index.ts",
);
const currentCompilerJs = currentCompilerTs.replace(/\.ts$/u, ".js");
const nextCompilerTs = path.join(
  nextRoot,
  "packages",
  "compiler",
  "index.ts",
);

function runNode(args, cold = false) {
  const env = { ...process.env };
  if (cold) env.PSC_NO_CACHE = "1";
  const result = spawnSync(node, args, {
    cwd: root,
    env,
    encoding: "utf8",
    stdio: "inherit",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`PSC2_DEV_STEP_FAILED: ${args.join(" ")}`);
  }
}

async function withColdCacheMode(cold, action) {
  const previous = process.env.PSC_NO_CACHE;
  if (cold) process.env.PSC_NO_CACHE = "1";
  try {
    return await action();
  } finally {
    if (previous === undefined) delete process.env.PSC_NO_CACHE;
    else process.env.PSC_NO_CACHE = previous;
  }
}

async function compilerArtifacts(indexTsPath) {
  const stem = indexTsPath.slice(0, -3);
  const entries = [
    [".ts", indexTsPath],
    [".js", stem + ".js"],
    [".d.ts", stem + ".d.ts"],
    [".js.map", stem + ".js.map"],
  ];
  const artifacts = {};
  for (const [extension, file] of entries) {
    const bytes = await readFile(file);
    artifacts[extension] = {
      bytes,
      sha256: sha256Bytes(bytes),
    };
  }
  return artifacts;
}

function assertArtifactEquality(left, right, label) {
  for (const extension of [".ts", ".js", ".d.ts", ".js.map"]) {
    if (!left[extension].bytes.equals(right[extension].bytes)) {
      throw new Error(
        [
          `PSC2_DEV_ARTIFACT_MISMATCH: ${label} ${extension}`,
          `left.sha256=${left[extension].sha256}`,
          `right.sha256=${right[extension].sha256}`,
        ].join("\n"),
      );
    }
  }
}

async function writeCompiler(typeScript, indexTsPath, cold) {
  await mkdir(path.dirname(indexTsPath), { recursive: true });
  await writeFile(indexTsPath, typeScript, "utf8");
  const tsc = await withColdCacheMode(cold, () =>
    compileTypeScriptCached(root, path.resolve(root, indexTsPath)),
  );
  return {
    tscCache: tsc.cache,
    artifacts: await compilerArtifacts(path.resolve(root, indexTsPath)),
  };
}

function emitCurrentWorkspace(cold) {
  runNode(
    [
      "scripts/emit-project-with-generated.mjs",
      parentCompiler,
      config.entry,
      "--to",
      "ps",
      "--out",
      currentWorkspace,
    ],
    cold,
  );
}

const parentSession = await createGeneratedCompilerSession(root, parentCompiler);
const candidateSessions = new Map();

async function currentBuild({ cold = false } = {}) {
  emitCurrentWorkspace(cold);
  const result = await parentSession.compile(currentEntry, {
    cold,
    progress: process.env.PSC_SELFHOST_PROGRESS === "1",
  });
  const emitted = await writeCompiler(result.typeScript, currentCompilerTs, cold);
  process.stdout.write(
    [
      "PSC2_DEV_BUILD: PASS",
      `mode=${cold ? "cold" : "hot"}`,
      `closure.sha256=${result.project.closureSha256}`,
      `fingerprint=${result.fingerprint}`,
      `parse.hits=${result.stats.parseHits}`,
      `parse.misses=${result.stats.parseMisses}`,
      `snapshot.hits=${result.stats.snapshotHits}`,
      `snapshot.misses=${result.stats.snapshotMisses}`,
      `semantic.green=${result.stats.semanticGreen}`,
      `prepared.hit=${result.stats.preparedHit}`,
      `backend.hit=${result.stats.backendHit}`,
      `tsc.cache=${emitted.tscCache}`,
    ].join("\n") + "\n",
  );
  return { result, ...emitted };
}

async function candidateSession() {
  const candidateHash = (await compilerArtifacts(
    path.resolve(root, currentCompilerTs),
  ))[".js"].sha256;
  if (candidateHash === parentSession.compilerSha256) {
    return parentSession;
  }
  if (!candidateSessions.has(candidateHash)) {
    candidateSessions.clear();
    candidateSessions.set(
      candidateHash,
      await createGeneratedCompilerSession(root, currentCompilerJs),
    );
  }
  return candidateSessions.get(candidateHash);
}

async function fixedPoint({ cold = false } = {}) {
  const current = await currentBuild({ cold });
  await rm(path.resolve(root, nextRoot), { recursive: true, force: true });

  runNode(
    [
      "scripts/reemit-project-with-generated.mjs",
      currentCompilerJs,
      currentWorkspace,
      nextWorkspace,
    ],
    cold,
  );
  runNode(
    [
      "scripts/compare-generated-source-workspaces.mjs",
      currentWorkspace,
      nextWorkspace,
    ],
    cold,
  );

  const session = await candidateSession();
  const next = await session.compile(nextEntry, {
    cold,
    progress: process.env.PSC_SELFHOST_PROGRESS === "1",
  });
  const emittedNext = await writeCompiler(
    next.typeScript,
    nextCompilerTs,
    cold,
  );
  assertArtifactEquality(
    current.artifacts,
    emittedNext.artifacts,
    "current-vs-next",
  );

  process.stdout.write(
    [
      "PSC2_DEV_FIXED_POINT: PASS",
      `mode=${cold ? "cold" : "hot"}`,
      `source.closure.sha256=${current.result.project.closureSha256}`,
      `.ts.sha256=${current.artifacts[".ts"].sha256}`,
      `.js.sha256=${current.artifacts[".js"].sha256}`,
      `.d.ts.sha256=${current.artifacts[".d.ts"].sha256}`,
      `.js.map.sha256=${current.artifacts[".js.map"].sha256}`,
      `next.parse.hits=${next.stats.parseHits}`,
      `next.parse.misses=${next.stats.parseMisses}`,
      `next.snapshot.hits=${next.stats.snapshotHits}`,
      `next.snapshot.misses=${next.stats.snapshotMisses}`,
      `next.semantic.green=${next.stats.semanticGreen}`,
      `next.tsc.cache=${emittedNext.tscCache}`,
    ].join("\n") + "\n",
  );
}

async function oracle() {
  const hot = await currentBuild({ cold: false });
  const hotClosure = hot.result.project.closureSha256;
  const hotArtifacts = hot.artifacts;

  const cold = await currentBuild({ cold: true });
  if (hotClosure !== cold.result.project.closureSha256) {
    throw new Error(
      `PSC2_DEV_ORACLE_SOURCE_MISMATCH: ${hotClosure} != ${cold.result.project.closureSha256}`,
    );
  }
  assertArtifactEquality(hotArtifacts, cold.artifacts, "hot-vs-cold");

  process.stdout.write(
    [
      "PSC2_DEV_ORACLE: PASS",
      `closure.sha256=${hotClosure}`,
      `.ts.sha256=${hotArtifacts[".ts"].sha256}`,
      `.js.sha256=${hotArtifacts[".js"].sha256}`,
    ].join("\n") + "\n",
  );
}

function printStats() {
  process.stdout.write(
    JSON.stringify(
      {
        parent: parentSession.cacheSizes(),
        candidates: [...candidateSessions.entries()].map(([sha256, session]) => ({
          sha256,
          cache: session.cacheSizes(),
        })),
      },
      null,
      2,
    ) + "\n",
  );
}

const mode = process.argv.slice(2);
if (mode.includes("--once")) {
  await currentBuild();
  process.exit(0);
}
if (mode.includes("--check")) {
  await fixedPoint();
  process.exit(0);
}
if (mode.includes("--oracle")) {
  await oracle();
  process.exit(0);
}
if (mode.includes("--cold-check")) {
  await fixedPoint({ cold: true });
  process.exit(0);
}

process.stdout.write(
  [
    "PSC2_DEV_RESIDENT: READY",
    "commands: build | check | oracle | cold-check | stats | clear | quit",
    `compiler=${parentCompiler}`,
    `workspace=${currentWorkspace}`,
  ].join("\n") + "\n",
);

const rl = createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: true,
});

for await (const rawLine of rl) {
  const command = rawLine.trim();
  try {
    if (command === "" || command === "build") {
      await currentBuild();
    } else if (command === "check") {
      await fixedPoint();
    } else if (command === "oracle") {
      await oracle();
    } else if (command === "cold-check") {
      await fixedPoint({ cold: true });
    } else if (command === "stats") {
      printStats();
    } else if (command === "clear") {
      parentSession.clear();
      candidateSessions.clear();
      process.stdout.write("PSC2_DEV_CACHE_CLEAR: PASS\n");
    } else if (command === "quit" || command === "exit") {
      break;
    } else {
      process.stdout.write(
        "PSC2_DEV_COMMAND: expected build | check | oracle | cold-check | stats | clear | quit\n",
      );
    }
  } catch (error) {
    process.stderr.write(
      `PSC2_DEV_COMMAND_FAILED: ${error?.stack ?? error}\n`,
    );
  }
}
rl.close();
