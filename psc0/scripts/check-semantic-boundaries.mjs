import { readdir, readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { assertSemanticBoundary } from "./semantic-boundaries.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");

async function collectLeanFiles(directory, output) {
  if (!existsSync(directory)) return;
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      await collectLeanFiles(absolute, output);
    } else if (entry.isFile() && entry.name.endsWith(".lean")) {
      output.push(absolute);
    }
  }
}

const files = [];
const packagesRoot = path.join(root, "packages");
for (const entry of await readdir(packagesRoot, { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  await collectLeanFiles(path.join(packagesRoot, entry.name, "src"), files);
}
await collectLeanFiles(path.join(root, "host", "src"), files);
await collectLeanFiles(path.join(root, "stdlib"), files);

files.sort();
for (const file of files) {
  const relative = path.relative(root, file).replaceAll(path.sep, "/");
  const source = await readFile(file, "utf8");
  assertSemanticBoundary(relative, source);
}

process.stdout.write(
  `PSC2_SEMANTIC_BOUNDARIES: PASS (${files.length} production Lean modules)\n`,
);
