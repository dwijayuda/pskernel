import { readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const files = [path.join(root, "check-psc1-source.mjs")];

async function collect(directory) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      await collect(file);
    } else if (entry.isFile() && entry.name.endsWith(".mjs")) {
      files.push(file);
    }
  }
}

await collect(path.join(root, "scripts"));
await collect(path.join(root, "packages", "cli", "bin"));
files.sort();

for (const file of files) {
  const result = spawnSync(process.execPath, ["--check", file], {
    cwd: root,
    encoding: "utf8",
  });
  if (result.status !== 0) {
    process.stderr.write(result.stdout ?? "");
    process.stderr.write(result.stderr ?? "");
    throw new Error(
      `PSC2_NODE_SYNTAX_FAIL: ${path.relative(root, file)}`,
    );
  }
}

process.stdout.write(
  `PSC2_NODE_SYNTAX: PASS (${files.length} bootstrap/orchestration scripts)\n`,
);
