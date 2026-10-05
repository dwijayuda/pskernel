import { createHash } from "node:crypto";
import { existsSync } from "node:fs";
import { copyFile, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";

export const pscCacheSchemaVersion = 1;

export function sha256Bytes(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

export async function sha256File(filePath) {
  return sha256Bytes(await readFile(filePath));
}

export function pscCacheEnabled() {
  return process.env.PSC_NO_CACHE !== "1";
}

export function pscCacheRoot(projectRoot) {
  const configured = process.env.PSC_CACHE_DIR;
  return configured
    ? path.resolve(projectRoot, configured)
    : path.join(projectRoot, "dist", ".cache", "psc2-selfhost");
}

function cacheKey(contract, input) {
  const hash = createHash("sha256");
  hash.update(JSON.stringify(contract), "utf8");
  hash.update("\0", "utf8");
  hash.update(input);
  return hash.digest("hex");
}

export async function cachedTextTransform({
  projectRoot,
  namespace,
  contract,
  input,
  compute,
}) {
  if (!pscCacheEnabled()) {
    return { value: await compute(), cache: "disabled" };
  }

  const key = cacheKey(contract, input);
  const entryDir = path.join(pscCacheRoot(projectRoot), namespace, key);
  const outputPath = path.join(entryDir, "output.txt");
  const manifestPath = path.join(entryDir, "manifest.json");

  if (existsSync(outputPath) && existsSync(manifestPath)) {
    try {
      const [output, manifestText] = await Promise.all([
        readFile(outputPath, "utf8"),
        readFile(manifestPath, "utf8"),
      ]);
      const manifest = JSON.parse(manifestText);
      const outputSha256 = sha256Bytes(Buffer.from(output, "utf8"));
      if (
        manifest?.schemaVersion === pscCacheSchemaVersion &&
        manifest.key === key &&
        manifest.outputSha256 === outputSha256
      ) {
        return { value: output, cache: "hit", key };
      }
    } catch {
      // Corrupt or incomplete cache entries are misses, never trusted inputs.
    }
    await rm(entryDir, { recursive: true, force: true });
  }

  const value = await compute();
  const outputSha256 = sha256Bytes(Buffer.from(value, "utf8"));
  await mkdir(entryDir, { recursive: true });
  await writeFile(outputPath, value, "utf8");
  await writeFile(
    manifestPath,
    JSON.stringify(
      {
        schemaVersion: pscCacheSchemaVersion,
        key,
        outputSha256,
      },
      null,
      2,
    ) + "\n",
    "utf8",
  );
  return { value, cache: "miss", key };
}

export function fileSetCacheKey(contract, primaryBytes) {
  return cacheKey(contract, primaryBytes);
}

export async function restoreFileSetCache({
  projectRoot,
  namespace,
  key,
  outputs,
}) {
  if (!pscCacheEnabled()) return false;
  const entryDir = path.join(pscCacheRoot(projectRoot), namespace, key);
  const manifestPath = path.join(entryDir, "manifest.json");
  if (!existsSync(manifestPath)) return false;

  try {
    const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
    if (
      manifest?.schemaVersion !== pscCacheSchemaVersion ||
      manifest.key !== key ||
      typeof manifest.files !== "object"
    ) {
      return false;
    }

    const staged = [];
    for (const output of outputs) {
      const cachedPath = path.join(entryDir, output.cacheName);
      if (!existsSync(cachedPath)) return false;
      const bytes = await readFile(cachedPath);
      if (sha256Bytes(bytes) !== manifest.files[output.cacheName]) return false;
      staged.push([cachedPath, output.path]);
    }

    for (const [cachedPath, outputPath] of staged) {
      await mkdir(path.dirname(outputPath), { recursive: true });
      await copyFile(cachedPath, outputPath);
    }
    return true;
  } catch {
    return false;
  }
}

export async function storeFileSetCache({
  projectRoot,
  namespace,
  key,
  outputs,
}) {
  if (!pscCacheEnabled()) return;
  const entryDir = path.join(pscCacheRoot(projectRoot), namespace, key);
  await mkdir(entryDir, { recursive: true });

  const files = {};
  for (const output of outputs) {
    const bytes = await readFile(output.path);
    files[output.cacheName] = sha256Bytes(bytes);
    await writeFile(path.join(entryDir, output.cacheName), bytes);
  }

  await writeFile(
    path.join(entryDir, "manifest.json"),
    JSON.stringify(
      {
        schemaVersion: pscCacheSchemaVersion,
        key,
        files,
      },
      null,
      2,
    ) + "\n",
    "utf8",
  );
}
