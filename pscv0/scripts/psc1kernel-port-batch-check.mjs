import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const sourceRoot = path.join(root, "packages", "pskernel-core", "src");
const files = [];

function walk(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const target = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      walk(target);
    } else if (entry.isFile() && entry.name.endsWith(".lean")) {
      files.push(target);
    }
  }
}

walk(sourceRoot);
files.sort();

const failures = [];
let passed = 0;

for (const file of files) {
  const relative = path.relative(root, file).replaceAll(path.sep, "/");
  const result = spawnSync(
    "lake",
    ["exe", "psc1", "check", relative],
    {
      cwd: root,
      encoding: "utf8",
      timeout: 120000,
    },
  );

  if (result.error) {
    failures.push({
      file: relative,
      detail: result.error.message,
    });
    console.error(
      `PSC1KERNEL_PORT_CHECK: FAIL ${relative}: ${result.error.message}`,
    );
    continue;
  }

  if (result.status === 0) {
    passed += 1;
    console.log(`PSC1KERNEL_PORT_CHECK: PASS ${relative}`);
    continue;
  }

  const combined = `${result.stdout ?? ""}\n${result.stderr ?? ""}`.trim();
  const useful = combined
    .split(/\r?\n/u)
    .filter((line) =>
      /PSC1_PROJECT_|uncaught exception|unsupported|expected|unknown|structuralRecursion|error/u.test(line),
    )
    .slice(-12)
    .join("\n");
  failures.push({
    file: relative,
    detail: useful || combined.slice(-4000),
  });
  console.error(`PSC1KERNEL_PORT_CHECK: FAIL ${relative}`);
  console.error(useful || combined.slice(-4000));
}

console.log(
  `PSC1KERNEL_PORT_CHECK_SUMMARY: passed=${passed} failed=${failures.length} total=${files.length}`,
);

if (failures.length > 0) {
  process.exit(1);
}
