import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const workspaceRoot = fs.existsSync(path.join(root, "package.json"))
  ? root
  : path.resolve("selfhost");

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function workspaceDirectories() {
  const directories = [];
  const packagesRoot = path.join(workspaceRoot, "packages");
  if (fs.existsSync(packagesRoot)) {
    for (const entry of fs.readdirSync(packagesRoot, { withFileTypes: true })) {
      if (entry.isDirectory()) {
        directories.push(path.join(packagesRoot, entry.name));
      }
    }
  }
  for (const name of ["host", "stdlib"]) {
    const directory = path.join(workspaceRoot, name);
    if (fs.existsSync(directory)) directories.push(directory);
  }
  return directories;
}

const roots = [];
for (const directory of workspaceDirectories()) {
  const manifestPath = path.join(directory, "package.json");
  if (!fs.existsSync(manifestPath)) continue;
  const manifest = readJson(manifestPath);
  const config = manifest.proofscript;
  if (!config || config.portable === false) continue;
  for (const sourceRoot of config.sourceRoots ?? []) {
    roots.push(path.resolve(directory, sourceRoot));
  }
}

const files = [];

function walk(dir) {
  if (!fs.existsSync(dir)) return;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(file);
    } else if (entry.isFile() && entry.name.endsWith(".lean")) {
      files.push(file);
    }
  }
}

for (const sourceRoot of roots) walk(sourceRoot);

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
        continue;
      }
      if (char === "-" && next === "/") {
        blockDepth -= 1;
        output += "  ";
        index += 2;
        continue;
      }
      output += char === "\n" ? "\n" : " ";
      index += 1;
      continue;
    }

    if (inString) {
      if (escaped) {
        output += char === "\n" ? "\n" : " ";
        escaped = false;
        index += 1;
        continue;
      }
      if (char === "\\") {
        output += " ";
        escaped = true;
        index += 1;
        continue;
      }
      if (char === "\"") {
        output += " ";
        inString = false;
        index += 1;
        continue;
      }
      output += char === "\n" ? "\n" : " ";
      index += 1;
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
  [/\bIO(?:\.|\s|\b)/, "IO in portable semantic module"],
  [/\bLean\./, "Lean implementation API"],
  [/\bStd\./, "Std implementation API"],
];

let failed = false;
for (const file of files) {
  const source = fs.readFileSync(file, "utf8");
  const auditedSource = maskLeanNonCode(source);
  for (const [pattern, label] of forbidden) {
    if (pattern.test(auditedSource)) {
      console.error(
        `PSC1_SOURCE_PROFILE: ${path.relative(workspaceRoot, file)}: forbidden ${label}`,
      );
      failed = true;
    }
  }
}

if (files.length === 0) {
  console.error("PSC1_SOURCE_PROFILE: no portable Lean modules found");
  failed = true;
}
if (failed) process.exit(1);
console.log(
  `PSC1_SOURCE_PROFILE: PASS (${files.length} portable self-host modules across ${roots.length} source roots)`,
);
