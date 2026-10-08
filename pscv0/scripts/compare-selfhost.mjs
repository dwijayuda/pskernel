import { readFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const selfhostRoot = path.resolve(scriptDir, "..");

if (process.argv.length < 4) {
  throw new Error(
    "usage: node scripts/compare-selfhost.mjs <bootstrap.ts> <next.ts>",
  );
}

const leftPath = path.resolve(selfhostRoot, process.argv[2]);
const rightPath = path.resolve(selfhostRoot, process.argv[3]);
const [left, right] = await Promise.all([
  readFile(leftPath, "utf8"),
  readFile(rightPath, "utf8"),
]);

const hash = (value) =>
  createHash("sha256").update(value, "utf8").digest("hex");

const leftHash = hash(left);
const rightHash = hash(right);

if (left !== right) {
  throw new Error(
    [
      "PSC1_SELFHOST_FIXED_POINT_MISMATCH",
      `bootstrap.sha256=${leftHash}`,
      `next.sha256=${rightHash}`,
    ].join("\n"),
  );
}

process.stdout.write(
  [
    "PSC1_SELFHOST_FIXED_POINT: PASS",
    `sha256=${leftHash}`,
  ].join("\n") + "\n",
);
