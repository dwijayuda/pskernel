import { readdirSync } from "node:fs";
import { join, relative } from "node:path";
import { spawnSync } from "node:child_process";

const root = process.cwd();
const proofRoot = join(root, "packages/pskernel-core/proof");

function collect(dir) {
  const out = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      out.push(...collect(full));
    } else if (entry.isFile() && entry.name.endsWith(".proof.lean")) {
      out.push(full);
    }
  }
  return out;
}

const files = collect(proofRoot).sort();

if (files.length === 0) {
  throw new Error("PSKERNEL_CORE_PROOFS_EMPTY");
}

for (const file of files) {
  const display = relative(root, file).replaceAll("\\", "/");
  process.stdout.write(`CHECK ${display}\n`);
  const result = spawnSync("lake", ["env", "lean", display], {
    cwd: root,
    stdio: "inherit",
    shell: process.platform === "win32",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

process.stdout.write(`PSKERNEL_CORE_PROOFS: PASS files=${files.length}\n`);
