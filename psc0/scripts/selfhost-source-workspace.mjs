import { existsSync, lstatSync } from "node:fs";
import { readFile, realpath } from "node:fs/promises";
import path from "node:path";
import { packageBySection, parseImports } from "./workspace-layout.mjs";
import { assertBootstrapManifestShape, computeBootstrapClosureSha256 } from "./bootstrap-manifest.mjs";

const generationManifests = [
  [".proofscript-bootstrap.json", "bootstrap"],
  [".proofscript-selfhost.json", "selfhost"],
];
const present = (file) => lstatSync(file, { throwIfNoEntry: false }) !== undefined;
const slash = (file) => file.split(path.sep).join("/");

function assertInside(root, file) {
  const relative = path.relative(root, file);
  if (relative === ".." || relative.startsWith(`..${path.sep}`) || path.isAbsolute(relative)) {
    throw new Error(`PSC2_SELFHOST_SOURCE_OUTSIDE_WORKSPACE: ${file}`);
  }
}

// A generation manifest is a boundary even when malformed or missing files.
// Never walk through that boundary to a parent handwritten workspace.
export function findSourceWorkspaceRoot(entryPath) {
  let current = path.dirname(path.resolve(entryPath));
  for (let fuel = 0; fuel < 64; fuel += 1) {
    if (generationManifests.some(([name]) => present(path.join(current, name)))) return current;
    if (existsSync(path.join(current, "packages")) &&
        (present(path.join(current, "package.json")) ||
         present(path.join(current, ".proofscript-project.json")) ||
         existsSync(path.join(current, "stdlib")))) return current;
    const parent = path.dirname(current);
    if (parent === current) break;
    current = parent;
  }
  throw new Error(`PSC2_SELFHOST_WORKSPACE_NOT_FOUND: ${entryPath}`);
}

function generatedModulePath(root, moduleName) {
  if (!/^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*$/u.test(moduleName)) {
    throw new Error(`PSC2_SELFHOST_IMPORT_NAME: ${moduleName}`);
  }
  const parts = moduleName.split(".");
  if (parts[0] === "ProofScript") return path.join(root, "stdlib", ...parts) + ".ps";
  if (parts[0] === "Ps" && parts.length >= 2) {
    const packageName = packageBySection.get(parts[1]);
    if (!packageName) throw new Error(`PSC2_SELFHOST_UNKNOWN_PACKAGE: ${moduleName}`);
    return path.join(root, "packages", packageName, "src", ...parts) + ".ps";
  }
  return path.join(root, ...parts) + ".ps";
}

// Return a validated, immutable-in-memory snapshot of exactly the declared PS
// closure, in dependency order. Hash the bytes actually consumed, not a second
// filesystem read. Ordinary (non-generation) projects keep their existing policy.
export async function readGeneratedSourceClosure(entryPath, workspaceRoot = findSourceWorkspaceRoot(entryPath)) {
  const root = path.resolve(workspaceRoot);
  const candidates = generationManifests.filter(([name]) => present(path.join(root, name)));
  if (candidates.length === 0) return undefined;
  if (candidates.length !== 1) throw new Error("PSC2_SELFHOST_MANIFEST_AMBIGUITY");
  const [manifestName, generation] = candidates[0];
  const realRoot = await realpath(root);
  let manifest;
  try {
    const manifestPath = await realpath(path.join(root, manifestName));
    assertInside(realRoot, manifestPath);
    manifest = JSON.parse(await readFile(manifestPath, "utf8"));
  } catch (error) {
    throw new Error(`PSC2_SELFHOST_MANIFEST_INVALID: ${manifestName}: ${error.message}`, { cause: error });
  }
  const generated = assertBootstrapManifestShape(manifest, generation);
  const absoluteEntry = path.resolve(entryPath);
  assertInside(root, absoluteEntry);
  if (slash(path.relative(root, absoluteEntry)) !== manifest.entry) {
    throw new Error(`PSC2_SELFHOST_SOURCE_ENTRY_MISMATCH: ${entryPath}`);
  }
  const allowed = new Set(generated);
  const visiting = new Set();
  const consumed = new Map();
  const ordered = [];
  async function visit(file) {
    const absolute = path.resolve(file);
    assertInside(root, absolute);
    const relative = slash(path.relative(root, absolute));
    if (!allowed.has(relative)) throw new Error(`PSC2_SELFHOST_SOURCE_NOT_IN_MANIFEST: ${relative}`);
    if (visiting.has(relative)) throw new Error(`PSC2_SELFHOST_IMPORT_CYCLE: ${relative}`);
    if (consumed.has(relative)) return;
    let resolved;
    try {
      resolved = await realpath(absolute);
    } catch (error) {
      throw new Error(`PSC2_SELFHOST_SOURCE_MISSING: ${relative}`, { cause: error });
    }
    assertInside(realRoot, resolved);
    const source = await readFile(resolved, "utf8");
    visiting.add(relative);
    for (const moduleName of parseImports(source)) await visit(generatedModulePath(root, moduleName));
    visiting.delete(relative);
    consumed.set(relative, source);
    ordered.push(Object.freeze({ path: absolute, source }));
  }
  await visit(absoluteEntry);
  if (JSON.stringify([...consumed.keys()].sort()) !== JSON.stringify(generated)) {
    throw new Error("PSC2_SELFHOST_SOURCE_FILESET_MISMATCH");
  }
  const closureSha256 = await computeBootstrapClosureSha256(manifest.entry, generated,
    async (relative) => consumed.get(relative));
  if (closureSha256 !== manifest.closureSha256) {
    throw new Error(`PSC2_SELFHOST_SOURCE_CLOSURE_MISMATCH: expected ${manifest.closureSha256}, got ${closureSha256}`);
  }
  return Object.freeze({ workspaceRoot: root, closureSha256, ordered: Object.freeze(ordered) });
}
