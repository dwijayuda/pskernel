import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");

if (process.argv.length < 4) {
  throw new Error(
    "usage: node scripts/compare-compiler-artifacts.mjs <left-index.ts> <right-index.ts>",
  );
}

function artifactPaths(indexTsPath) {
  if (!indexTsPath.endsWith(".ts")) {
    throw new Error(`PSC2_COMPILER_ARTIFACT_ENTRY_KIND: ${indexTsPath}`);
  }
  const stem = indexTsPath.slice(0, -3);
  return [
    [".ts", indexTsPath],
    [".js", stem + ".js"],
    [".d.ts", stem + ".d.ts"],
    [".js.map", stem + ".js.map"],
  ];
}

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

const leftEntry = path.resolve(root, process.argv[2]);
const rightEntry = path.resolve(root, process.argv[3]);
const leftArtifacts = artifactPaths(leftEntry);
const rightArtifacts = artifactPaths(rightEntry);

const lines = ["PSC2_CURRENT_COMPILER_FIXED_POINT: PASS"];
for (let index = 0; index < leftArtifacts.length; index += 1) {
  const [extension, leftPath] = leftArtifacts[index];
  const [, rightPath] = rightArtifacts[index];
  const [left, right] = await Promise.all([
    readFile(leftPath),
    readFile(rightPath),
  ]);
  const leftHash = sha256(left);
  const rightHash = sha256(right);
  if (!left.equals(right)) {
    throw new Error(
      [
        `PSC2_CURRENT_COMPILER_ARTIFACT_MISMATCH: ${extension}`,
        `left.sha256=${leftHash}`,
        `right.sha256=${rightHash}`,
      ].join("\n"),
    );
  }
  lines.push(`${extension}.sha256=${leftHash}`);
}

process.stdout.write(lines.join("\n") + "\n");
