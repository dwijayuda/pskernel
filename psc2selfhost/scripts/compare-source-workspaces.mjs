import { readFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const selfhostRoot = path.resolve(scriptDir, "..");

if (process.argv.length < 4) {
  throw new Error(
    "usage: node scripts/compare-source-workspaces.mjs <bootstrap-workspace> <selfhost-workspace>",
  );
}

const leftRoot = path.resolve(selfhostRoot, process.argv[2]);
const rightRoot = path.resolve(selfhostRoot, process.argv[3]);

const leftManifest = JSON.parse(
  await readFile(path.join(leftRoot, ".proofscript-bootstrap.json"), "utf8"),
);
const rightManifest = JSON.parse(
  await readFile(path.join(rightRoot, ".proofscript-selfhost.json"), "utf8"),
);

if (leftManifest.entry !== rightManifest.entry) {
  throw new Error(
    `PSC1_SELFHOST_SOURCE_ENTRY_MISMATCH: ${leftManifest.entry} != ${rightManifest.entry}`,
  );
}

const leftFiles = [...leftManifest.generated].sort();
const rightFiles = [...rightManifest.generated].sort();
if (JSON.stringify(leftFiles) !== JSON.stringify(rightFiles)) {
  throw new Error("PSC1_SELFHOST_SOURCE_FILESET_MISMATCH");
}

const hash = createHash("sha256");
for (const relativePath of leftFiles) {
  const [left, right] = await Promise.all([
    readFile(path.join(leftRoot, relativePath), "utf8"),
    readFile(path.join(rightRoot, relativePath), "utf8"),
  ]);
  if (left !== right) {
    throw new Error(`PSC1_SELFHOST_SOURCE_MISMATCH: ${relativePath}`);
  }
  hash.update(relativePath, "utf8");
  hash.update("\0", "utf8");
  hash.update(left, "utf8");
  hash.update("\0", "utf8");
}

process.stdout.write(
  [
    "PSC1_SELFHOST_SOURCE_FIXED_POINT: PASS",
    `files=${leftFiles.length}`,
    `sha256=${hash.digest("hex")}`,
  ].join("\n") + "\n",
);
