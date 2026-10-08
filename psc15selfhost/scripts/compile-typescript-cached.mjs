import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { spawnSync } from "node:child_process";
import {
  fileSetCacheKey,
  pscCacheEnabled,
  restoreFileSetCache,
  storeFileSetCache,
} from "./cache-utils.mjs";
import {
  pinnedTypeScriptVersionText,
  resolveTypeScriptCli,
} from "./typescript-cli.mjs";

export const pscTypeScriptContractArgs = [
  "--ignoreConfig",
  "--target",
  "ES2022",
  "--module",
  "ES2022",
  "--moduleResolution",
  "bundler",
  "--strict",
  "--declaration",
  "--sourceMap",
  "--noEmitOnError",
  "--skipLibCheck",
  "--pretty",
  "false",
];

async function sha256Toolchain(files) {
  const hash = createHash("sha256");
  for (const file of files) {
    const bytes = await readFile(file);
    hash.update(path.basename(file), "utf8");
    hash.update("\0", "utf8");
    hash.update(bytes);
    hash.update("\0", "utf8");
  }
  hash.update(process.version, "utf8");
  hash.update("\0", "utf8");
  hash.update(process.platform, "utf8");
  hash.update("\0", "utf8");
  hash.update(process.arch, "utf8");
  return hash.digest("hex");
}

async function resolvePinnedTypeScript(projectRoot) {
  const tsc = resolveTypeScriptCli();
  const version = spawnSync(process.execPath, [tsc, "--version"], {
    cwd: projectRoot,
    encoding: "utf8",
    timeout: 10000,
  });
  if (
    version.error ||
    version.status !== 0 ||
    version.stdout.trim() !== pinnedTypeScriptVersionText
  ) {
    throw new Error("PSC2_SELFHOST_TYPESCRIPT_PIN: require TypeScript 7.0.2");
  }

  const packageRoot = path.resolve(path.dirname(tsc), "..");
  const getExePathFile = path.join(packageRoot, "lib", "getExePath.js");
  const getExePathModule = await import(pathToFileURL(getExePathFile).href);
  const executable = getExePathModule.default();
  const platformPackageRoot = path.resolve(path.dirname(executable), "..");

  return {
    tsc,
    executable,
    sha256: await sha256Toolchain([
      tsc,
      path.join(packageRoot, "lib", "tsc.js"),
      getExePathFile,
      path.join(packageRoot, "package.json"),
      path.join(platformPackageRoot, "package.json"),
      executable,
    ]),
  };
}

function compileTypeScriptCold(projectRoot, typeScriptPath, tsc) {
  const result = spawnSync(
    process.execPath,
    [tsc, typeScriptPath, ...pscTypeScriptContractArgs],
    {
      cwd: projectRoot,
      encoding: "utf8",
      stdio: "pipe",
    },
  );
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(
      [
        "PSC2_SELFHOST_TSC_FAILED",
        result.stdout,
        result.stderr,
      ].filter(Boolean).join("\n"),
    );
  }
}

export async function compileTypeScriptCached(projectRoot, typeScriptPath) {
  const pinned = await resolvePinnedTypeScript(projectRoot);
  const typeScriptBytes = await readFile(typeScriptPath);
  const stem = typeScriptPath.slice(0, -3);
  const outputs = [
    { cacheName: "index.js", path: stem + ".js" },
    { cacheName: "index.d.ts", path: stem + ".d.ts" },
    { cacheName: "index.js.map", path: stem + ".js.map" },
  ];
  const key = fileSetCacheKey(
    {
      operation: "tsc-v1",
      version: pinnedTypeScriptVersionText,
      toolchainSha256: pinned.sha256,
      inputName: path.basename(typeScriptPath),
      args: pscTypeScriptContractArgs,
    },
    typeScriptBytes,
  );

  if (
    await restoreFileSetCache({
      cacheTrust: 'bootstrap-local',
      projectRoot,
      namespace: "tsc-v1",
      key,
      outputs,
    })
  ) {
    return { cache: "hit", key };
  }

  compileTypeScriptCold(projectRoot, typeScriptPath, pinned.tsc);
  await storeFileSetCache({
    cacheTrust: 'bootstrap-local',
    projectRoot,
    namespace: "tsc-v1",
    key,
    outputs,
  });
  return { cache: pscCacheEnabled() ? "miss" : "disabled", key };
}
