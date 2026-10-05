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

const allFiles = collect(proofRoot).sort();

if (allFiles.length === 0) {
  throw new Error("PSKERNEL_CORE_PROOFS_EMPTY");
}

function changedProofs() {
  const result = spawnSync(
    "git",
    [
      "diff",
      "--name-only",
      "--relative",
      "HEAD^",
      "HEAD",
      "--",
      "packages/pskernel-core/proof",
    ],
    {
      cwd: root,
      encoding: "utf8",
      shell: process.platform === "win32",
    },
  );

  if (result.status !== 0 || result.error) {
    return [];
  }

  const changed = new Set(
    result.stdout
      .split(/\r?\n/)
      .map((value) => value.trim().replaceAll("\\", "/"))
      .filter((value) => value.endsWith(".proof.lean")),
  );

  return allFiles.filter((file) =>
    changed.has(relative(root, file).replaceAll("\\", "/")),
  );
}

const changed = changedProofs();
const changedSet = new Set(changed);
const files = [
  ...changed,
  ...allFiles.filter((file) => !changedSet.has(file)),
];

if (changed.length > 0) {
  process.stdout.write(
    `PSKERNEL_CORE_PROOFS_CHANGED_FIRST: files=${changed.length}\n`,
  );
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
