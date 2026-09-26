import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import path from "node:path";

export const bootstrapManifestSchemaVersion = 2;

export function assertCanonicalPsRelativePath(relativePath) {
  if (typeof relativePath !== "string" || relativePath.length === 0) {
    throw new Error("PSC2_BOOTSTRAP_MANIFEST_PATH_KIND");
  }
  if (relativePath.includes("\\")) {
    throw new Error(`PSC2_BOOTSTRAP_MANIFEST_PATH_SEPARATOR: ${relativePath}`);
  }
  if (relativePath.startsWith("/") || /^[A-Za-z]:/u.test(relativePath)) {
    throw new Error(`PSC2_BOOTSTRAP_MANIFEST_PATH_ABSOLUTE: ${relativePath}`);
  }
  if (!relativePath.endsWith(".ps")) {
    throw new Error(`PSC2_BOOTSTRAP_MANIFEST_PATH_KIND: ${relativePath}`);
  }
  const segments = relativePath.split("/");
  if (segments.some((segment) => segment.length === 0 || segment === "." || segment === "..")) {
    throw new Error(`PSC2_BOOTSTRAP_MANIFEST_PATH_TRAVERSAL: ${relativePath}`);
  }
}

export function canonicalGeneratedPaths(paths) {
  if (!Array.isArray(paths)) {
    throw new Error("PSC2_BOOTSTRAP_MANIFEST_GENERATED_KIND");
  }
  const canonical = [];
  const seen = new Set();
  for (const relativePath of paths) {
    assertCanonicalPsRelativePath(relativePath);
    if (seen.has(relativePath)) {
      throw new Error(`PSC2_BOOTSTRAP_MANIFEST_DUPLICATE_PATH: ${relativePath}`);
    }
    seen.add(relativePath);
    canonical.push(relativePath);
  }
  canonical.sort();
  return canonical;
}

export function assertBootstrapManifestShape(manifest, generation) {
  if (manifest === null || typeof manifest !== "object" || Array.isArray(manifest)) {
    throw new Error("PSC2_BOOTSTRAP_MANIFEST_OBJECT");
  }
  if (manifest.schemaVersion !== bootstrapManifestSchemaVersion) {
    throw new Error(
      `PSC2_BOOTSTRAP_MANIFEST_SCHEMA: expected ${bootstrapManifestSchemaVersion}, got ${String(manifest.schemaVersion)}`,
    );
  }
  if (generation !== undefined && manifest.generation !== generation) {
    throw new Error(
      `PSC2_BOOTSTRAP_MANIFEST_GENERATION: expected ${generation}, got ${String(manifest.generation)}`,
    );
  }
  assertCanonicalPsRelativePath(manifest.entry);
  const canonical = canonicalGeneratedPaths(manifest.generated);
  if (JSON.stringify(manifest.generated) !== JSON.stringify(canonical)) {
    throw new Error("PSC2_BOOTSTRAP_MANIFEST_NONCANONICAL_ORDER");
  }
  if (manifest.sourceCount !== canonical.length) {
    throw new Error(
      `PSC2_BOOTSTRAP_MANIFEST_SOURCE_COUNT: expected ${canonical.length}, got ${String(manifest.sourceCount)}`,
    );
  }
  if (!canonical.includes(manifest.entry)) {
    throw new Error(`PSC2_BOOTSTRAP_MANIFEST_ENTRY_NOT_GENERATED: ${manifest.entry}`);
  }
  if (typeof manifest.closureSha256 !== "string" || !/^[0-9a-f]{64}$/u.test(manifest.closureSha256)) {
    throw new Error("PSC2_BOOTSTRAP_MANIFEST_CLOSURE_HASH");
  }
  return canonical;
}

export async function computeBootstrapClosureSha256(entry, generated, readSource) {
  assertCanonicalPsRelativePath(entry);
  const canonical = canonicalGeneratedPaths(generated);
  if (!canonical.includes(entry)) {
    throw new Error(`PSC2_BOOTSTRAP_MANIFEST_ENTRY_NOT_GENERATED: ${entry}`);
  }
  const hash = createHash("sha256");
  hash.update("proofscript-bootstrap-closure-v2\0", "utf8");
  hash.update(entry, "utf8");
  hash.update("\0", "utf8");
  for (const relativePath of canonical) {
    const source = await readSource(relativePath);
    if (typeof source !== "string") {
      throw new Error(`PSC2_BOOTSTRAP_MANIFEST_SOURCE_KIND: ${relativePath}`);
    }
    hash.update(relativePath, "utf8");
    hash.update("\0", "utf8");
    hash.update(source, "utf8");
    hash.update("\0", "utf8");
  }
  return hash.digest("hex");
}

export async function computeBootstrapWorkspaceClosureSha256(workspaceRoot, entry, generated) {
  const root = path.resolve(workspaceRoot);
  return computeBootstrapClosureSha256(entry, generated, async (relativePath) => {
    const absolute = path.resolve(root, relativePath);
    const relative = path.relative(root, absolute);
    if (relative.startsWith("..") || path.isAbsolute(relative)) {
      throw new Error(`PSC2_BOOTSTRAP_MANIFEST_SOURCE_OUTSIDE_WORKSPACE: ${relativePath}`);
    }
    return readFile(absolute, "utf8");
  });
}

export async function assertBootstrapWorkspaceManifest(workspaceRoot, manifest, generation) {
  const generated = assertBootstrapManifestShape(manifest, generation);
  const actualHash = await computeBootstrapWorkspaceClosureSha256(
    workspaceRoot,
    manifest.entry,
    generated,
  );
  if (manifest.closureSha256 !== actualHash) {
    throw new Error(
      `PSC2_BOOTSTRAP_MANIFEST_CLOSURE_MISMATCH: expected ${manifest.closureSha256}, got ${actualHash}`,
    );
  }
  return actualHash;
}
