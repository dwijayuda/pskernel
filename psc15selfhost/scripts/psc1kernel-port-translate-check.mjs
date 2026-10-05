import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const sourceRoot = path.join(root, "packages", "pskernel-core", "src");
const outRoot = fs.mkdtempSync(path.join(os.tmpdir(), "psc1kernel-port-ps-"));
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

function useful(output) {
  return output
    .split(/\r?\n/u)
    .filter((line) =>
      /PSC1_|uncaught exception|unsupported|expected|unknown|structuralRecursion|error/u.test(line),
    )
    .slice(-14)
    .join("\n");
}

walk(sourceRoot);
files.sort();

let passed = 0;
const failures = [];

try {
  for (const sourcePath of files) {
    const relative = path.relative(root, sourcePath).replaceAll(path.sep, "/");
    const output = path.join(
      outRoot,
      path.relative(sourceRoot, sourcePath).replace(/\.lean$/u, ".ps"),
    );
    fs.mkdirSync(path.dirname(output), { recursive: true });

    const translated = spawnSync(
      "lake",
      ["exe", "psc1", "translate", relative, "--to", "ps", "--out", output],
      { cwd: root, encoding: "utf8", timeout: 120000 },
    );
    const translatedText =
      `${translated.stdout ?? ""}\n${translated.stderr ?? ""}`.trim();

    if (translated.error || translated.status !== 0 || !fs.existsSync(output)) {
      const detail = translated.error?.message ?? useful(translatedText) ?? translatedText;
      failures.push({ file: relative, phase: "translate", detail });
      console.error(`PSC1KERNEL_PORT_TRANSLATE: FAIL ${relative}`);
      if (detail) console.error(detail);
      continue;
    }

    const checked = spawnSync(
      "lake",
      ["exe", "psc1", "check", output],
      { cwd: root, encoding: "utf8", timeout: 120000 },
    );
    const checkedText =
      `${checked.stdout ?? ""}\n${checked.stderr ?? ""}`.trim();

    if (checked.error || checked.status !== 0) {
      const detail = checked.error?.message ?? useful(checkedText) ?? checkedText;
      failures.push({ file: relative, phase: "recheck", detail });
      console.error(`PSC1KERNEL_PORT_TRANSLATE: FAIL ${relative} phase=recheck`);
      if (detail) console.error(detail);
      continue;
    }

    passed += 1;
    console.log(`PSC1KERNEL_PORT_TRANSLATE: PASS ${relative}`);
  }

  console.log(
    `PSC1KERNEL_PORT_TRANSLATE_SUMMARY: passed=${passed} failed=${failures.length} total=${files.length}`,
  );
  if (failures.length > 0) process.exitCode = 1;
} finally {
  fs.rmSync(outRoot, { recursive: true, force: true });
}
