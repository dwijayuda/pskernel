import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const sourceRoot = path.join(root, "packages", "pskernel-core", "src");

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
}
if (files.length === 0) {
  console.error("KERNEL_CORE_SOURCE_PROFILE: no KernelCore Lean modules found");
  failed = true;
}
if (failed) process.exit(1);

for (const file of files) {
  const relative = path.relative(root, file);
  const result = spawnSync("lake", ["exe", "psc1", "check", relative], {
    cwd: root,
    encoding: "utf8",
  });
  if (result.status !== 0) {
    process.stderr.write(result.stdout ?? "");
    process.stderr.write(result.stderr ?? "");
    console.error(`KERNEL_CORE_SELFHOST_CHECK: FAIL ${relative}`);
    process.exit(result.status ?? 1);
  }
  process.stdout.write(`KERNEL_CORE_SELFHOST_CHECK: PASS ${relative}\n`);
}

console.log(
  `KERNEL_CORE_SOURCE_PROFILE: PASS (${files.length} PSC1-portable, self-host-checkable modules)`,
);
