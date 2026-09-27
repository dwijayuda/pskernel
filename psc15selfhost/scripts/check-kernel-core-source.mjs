import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const sourceRoot = path.join(root, "packages", "pskernel-core", "src");
const modulePrefix = "Ps.KernelCore";
const selfHostTimeoutMs = 120_000;

const files = [];
function walk(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) walk(file);
    else if (entry.isFile() && entry.name.endsWith(".lean")) files.push(file);
  }
}
walk(sourceRoot);
files.sort();

function maskLeanNonCode(source) {
  let output = "";
  let index = 0;
  let blockDepth = 0;
  let inString = false;
  let escaped = false;
  while (index < source.length) {
    const char = source[index];
    const next = index + 1 < source.length ? source[index + 1] : "";
    if (blockDepth > 0) {
      if (char === "/" && next === "-") {
        blockDepth += 1;
        output += "  ";
        index += 2;
      } else if (char === "-" && next === "/") {
        blockDepth -= 1;
        output += "  ";
        index += 2;
      } else {
        output += char === "\n" ? "\n" : " ";
        index += 1;
      }
      continue;
    }
    if (inString) {
      if (escaped) {
        output += char === "\n" ? "\n" : " ";
        escaped = false;
        index += 1;
      } else if (char === "\\") {
        output += " ";
        escaped = true;
        index += 1;
      } else if (char === "\"") {
        output += " ";
        inString = false;
        index += 1;
      } else {
        output += char === "\n" ? "\n" : " ";
        index += 1;
      }
      continue;
    }
    if (char === "-" && next === "-") {
      output += "  ";
      index += 2;
      while (index < source.length && source[index] !== "\n") {
        output += " ";
        index += 1;
      }
      continue;
    }
    if (char === "/" && next === "-") {
      blockDepth = 1;
      output += "  ";
      index += 2;
      continue;
    }
    if (char === "\"") {
      inString = true;
      output += " ";
      index += 1;
      continue;
    }
    output += char;
    index += 1;
  }
  return output;
}

const forbidden = [
  [/(^|\n)\s*import\s+Lean(?:\.|\s|$)/, "Lean implementation import"],
  [/(^|\n)\s*import\s+Std(?:\.|\s|$)/, "Std implementation import"],
  [/\bunsafe\b/, "unsafe"],
  [/\bimplemented_by\b/, "implemented_by"],
  [/\bextern\b/, "extern"],
  [/\bmacro_rules\b|\bmacro\b/, "macro"],
  [/(^|\s)syntax(?:\s|$)/, "custom syntax"],
  [/\belab_rules\b|\belab\b/, "custom elaborator"],
  [/\brun_tac\b/, "run_tac"],
  [/\bset_option\b/, "set_option"],
  [/\bopen\s+scoped\b/, "open scoped"],
  [/\bnamespace\b/, "namespace convenience"],
  [/\bsection\b/, "section convenience"],
  [/\babbrev\b/, "abbrev convenience"],
  [/\bopaque\b/, "opaque source convenience"],
  [/\bmutual\b/, "mutual declaration convenience"],
  [/\btermination_by\b|\bdecreasing_by\b/, "explicit termination machinery"],
  [/\bIO(?:\.|\s|\b)/, "IO in trusted kernel source"],
  [/\bLean\./, "Lean implementation API"],
  [/\bStd\./, "Std implementation API"],
];

function parseImports(source) {
  const imports = [];
  for (const line of source.split(/\r?\n/u)) {
    const match = line.match(/^\s*import\s+([A-Za-z0-9_.]+)\s*;?\s*$/u);
    if (match) imports.push(match[1]);
  }
  return imports;
}

function sourceForModule(moduleName) {
  if (moduleName === modulePrefix) {
    return path.join(sourceRoot, "Ps", "KernelCore.lean");
  }
  const prefix = `${modulePrefix}.`;
  if (!moduleName.startsWith(prefix)) {
    throw new Error(`KERNEL_CORE_EXTERNAL_IMPORT: ${moduleName}`);
  }
  const suffix = moduleName.slice(prefix.length).split(".");
  return path.join(sourceRoot, "Ps", "KernelCore", ...suffix) + ".lean";
}

function sourceWithoutImports(source) {
  return source
    .split(/\r?\n/u)
    .filter((line) => !/^\s*import\s+/u.test(line))
    .join("\n");
}

function flattenEntry(entry) {
  const visited = new Set();
  const chunks = [];
  function visit(file) {
    const absolute = path.resolve(file);
    if (visited.has(absolute)) return;
    if (!absolute.startsWith(path.resolve(sourceRoot) + path.sep)) {
      throw new Error(`KERNEL_CORE_SOURCE_ESCAPE: ${absolute}`);
    }
    if (!fs.existsSync(absolute)) {
      throw new Error(`KERNEL_CORE_SOURCE_MISSING: ${absolute}`);
    }
    visited.add(absolute);
    const source = fs.readFileSync(absolute, "utf8");
    for (const moduleName of parseImports(source)) {
      visit(sourceForModule(moduleName));
    }
    const body = sourceWithoutImports(source).trim();
    if (body.length > 0) chunks.push(body);
  }
  visit(entry);
  return chunks.join("\n\n") + "\n";
}

let failed = false;
for (const file of files) {
  const source = maskLeanNonCode(fs.readFileSync(file, "utf8"));
  for (const [pattern, label] of forbidden) {
    if (pattern.test(source)) {
      console.error(
        `KERNEL_CORE_SOURCE_PROFILE: ${path.relative(root, file)}: forbidden ${label}`,
      );
      failed = true;
    }
  }
  for (const moduleName of parseImports(fs.readFileSync(file, "utf8"))) {
    if (moduleName !== modulePrefix && !moduleName.startsWith(`${modulePrefix}.`)) {
      console.error(
        `KERNEL_CORE_SOURCE_PROFILE: ${path.relative(root, file)}: external import ${moduleName}`,
      );
      failed = true;
    }
  }
}
if (files.length === 0) {
  console.error("KERNEL_CORE_SOURCE_PROFILE: no KernelCore Lean modules found");
  failed = true;
}
if (failed) process.exit(1);

const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "proofscript-kernel-core-"));
try {
  for (let index = 0; index < files.length; index += 1) {
    const file = files[index];
    const relative = path.relative(root, file);
    const flatPath = path.join(tempRoot, `KernelCoreCheck${index}.lean`);
    fs.writeFileSync(flatPath, flattenEntry(file), "utf8");
    process.stdout.write(`KERNEL_CORE_SELFHOST_CHECK: START ${relative}\n`);
    const result = spawnSync("lake", ["exe", "psc1", "check", flatPath], {
      cwd: root,
      encoding: "utf8",
      timeout: selfHostTimeoutMs,
      killSignal: "SIGKILL",
    });
    if (result.error) {
      process.stderr.write(result.stdout ?? "");
      process.stderr.write(result.stderr ?? "");
      console.error(
        `KERNEL_CORE_SELFHOST_CHECK: ERROR ${relative}: ${result.error.message}`,
      );
      process.exit(1);
    }
    if (result.status !== 0) {
      process.stderr.write(result.stdout ?? "");
      process.stderr.write(result.stderr ?? "");
      console.error(`KERNEL_CORE_SELFHOST_CHECK: FAIL ${relative}`);
      process.exit(result.status ?? 1);
    }
    process.stdout.write(`KERNEL_CORE_SELFHOST_CHECK: PASS ${relative}\n`);
  }
} finally {
  fs.rmSync(tempRoot, { recursive: true, force: true });
}

console.log(
  `KERNEL_CORE_SOURCE_PROFILE: PASS (${files.length} PSC1-subset, self-host-checkable modules)`,
);
