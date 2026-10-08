import { createHash } from "node:crypto";
import { existsSync } from "node:fs";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { canonicalBytes } from './artifact-evidence.mjs';

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
  hash.update(canonicalBytes(contract));
  hash.update("\0", "utf8");
  hash.update(input);
  return hash.digest("hex");
}

function component(value) {
  if (typeof value !== 'string' || !/^[A-Za-z0-9][A-Za-z0-9._-]*$/u.test(value)) throw new Error('PSC_CACHE_PATH_COMPONENT');
  return value;
}

function entryPath(projectRoot, namespace, key) {
  if (!/^[a-f0-9]{64}$/u.test(key)) throw new Error('PSC_CACHE_KEY');
  return path.join(pscCacheRoot(projectRoot), component(namespace), key);
}

function trustedBootstrap(cacheTrust) {
  if (!['untrusted', 'bootstrap-local'].includes(cacheTrust)) throw new Error('PSC_CACHE_TRUST_CLASS');
  return cacheTrust === 'bootstrap-local';
}

export async function cachedTextTransform({
  projectRoot,
  namespace,
  contract,
  input,
  compute,
  cacheTrust = 'untrusted',
}) {
  // Hashes supplied by a cache are not evidence. Untrusted callers use the
  // evidence-cache verifier; this legacy path is explicitly bootstrap-local.
  if (!trustedBootstrap(cacheTrust)) return { value: await compute(), cache: 'untrusted-bypass' };
  if (!pscCacheEnabled()) {
    return { value: await compute(), cache: "disabled" };
  }

  const key = cacheKey(contract, input);
  const entryDir = entryPath(projectRoot, namespace, key);
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
  cacheTrust = 'untrusted',
}) {
  if (!trustedBootstrap(cacheTrust)) return false;
  if (!pscCacheEnabled()) return false;
  const entryDir = entryPath(projectRoot, namespace, key);
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
      const cachedPath = path.join(entryDir, component(output.cacheName));
      if (!existsSync(cachedPath)) return false;
      const bytes = await readFile(cachedPath);
      if (sha256Bytes(bytes) !== manifest.files[output.cacheName]) return false;
      staged.push([bytes, output.path]);
    }

    for (const [bytes, outputPath] of staged) {
      await mkdir(path.dirname(outputPath), { recursive: true });
      await writeFile(outputPath, bytes);
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
  cacheTrust = 'untrusted',
}) {
  if (!trustedBootstrap(cacheTrust)) return;
  if (!pscCacheEnabled()) return;
  const entryDir = entryPath(projectRoot, namespace, key);
  await mkdir(entryDir, { recursive: true });

  const files = {};
  for (const output of outputs) {
    const bytes = await readFile(output.path);
    files[output.cacheName] = sha256Bytes(bytes);
    await writeFile(path.join(entryDir, component(output.cacheName)), bytes);
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
