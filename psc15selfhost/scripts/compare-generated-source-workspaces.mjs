import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  canonicalGeneratedPaths,
  computeBootstrapWorkspaceClosureSha256,
  assertBootstrapWorkspaceManifest,
} from "./bootstrap-manifest.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");

if (process.argv.length < 4) {
  throw new Error(
    "usage: node scripts/compare-generated-source-workspaces.mjs <left-workspace> <right-workspace>",
  );
}

async function readWorkspace(workspacePath) {
  const workspace = path.resolve(root, workspacePath);
  for (const candidate of [
    [".proofscript-bootstrap.json", "bootstrap"],
    [".proofscript-selfhost.json", "selfhost"],
    [".proofscript-project.json", "project"],
  ]) {
    const [name, kind] = candidate;
    const manifestPath = path.join(workspace, name);
    if (!existsSync(manifestPath)) continue;

    const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
    if (kind === "project") {
      if (
        manifest === null ||
        typeof manifest !== "object" ||
        manifest.schemaVersion !== 1 ||
        typeof manifest.entry !== "string"
      ) {
        throw new Error(`PSC2_CURRENT_SOURCE_MANIFEST_SHAPE: ${manifestPath}`);
      }
      const generated = canonicalGeneratedPaths(manifest.generated);
      if (manifest.sourceCount !== generated.length) {
        throw new Error(`PSC2_CURRENT_SOURCE_COUNT: ${manifestPath}`);
      }
      const closureSha256 = await computeBootstrapWorkspaceClosureSha256(
        workspace,
        manifest.entry,
        generated,
      );
      return { workspace, kind, manifest, generated, closureSha256 };
    }

    const closureSha256 = await assertBootstrapWorkspaceManifest(
      workspace,
      manifest,
      kind,
    );
    return {
      workspace,
      kind,
      manifest,
      generated: canonicalGeneratedPaths(manifest.generated),
      closureSha256,
    };
  }
  throw new Error(`PSC2_CURRENT_SOURCE_MANIFEST_MISSING: ${workspace}`);
}

const [left, right] = await Promise.all([
  readWorkspace(process.argv[2]),
  readWorkspace(process.argv[3]),
]);

if (left.manifest.entry !== right.manifest.entry) {
  throw new Error(
    `PSC2_CURRENT_SOURCE_ENTRY_MISMATCH: ${left.manifest.entry} != ${right.manifest.entry}`,
  );
}
if (JSON.stringify(left.generated) !== JSON.stringify(right.generated)) {
  throw new Error("PSC2_CURRENT_SOURCE_FILESET_MISMATCH");
}
if (left.closureSha256 !== right.closureSha256) {
  throw new Error(
    `PSC2_CURRENT_SOURCE_CLOSURE_MISMATCH: ${left.closureSha256} != ${right.closureSha256}`,
  );
}

for (const relativePath of left.generated) {
  const [leftSource, rightSource] = await Promise.all([
    readFile(path.join(left.workspace, relativePath)),
    readFile(path.join(right.workspace, relativePath)),
  ]);
  if (!leftSource.equals(rightSource)) {
    throw new Error(`PSC2_CURRENT_SOURCE_MISMATCH: ${relativePath}`);
  }
}

process.stdout.write(
  [
    "PSC2_CURRENT_SOURCE_FIXED_POINT: PASS",
    `files=${left.generated.length}`,
    `closure.sha256=${left.closureSha256}`,
  ].join("\n") + "\n",
);
