import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { maskLeanNonCode } from "./psc1-source-profile.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const sourceRoot = path.join(root, "packages", "pskernel-core", "src");
const files = [];

function walk(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const target = path.join(directory, entry.name);
    if (entry.isDirectory()) walk(target);
    else if (entry.isFile() && entry.name.endsWith(".lean")) files.push(target);
  }
}

const rules = [
  ["local-let-rec", /\blet\s+rec\b/gu],
  ["runtime-type-parameter", /:\s*Type\b/gu],
  ["record-update", /\{\s*[A-Za-z_][A-Za-z0-9_]*\s+with\b/gu],
  ["parenthesized-projection", /\)\.[A-Za-z_][A-Za-z0-9_]*/gu],
  ["operator-equality", /==|!=/gu],
  ["operator-append", /\+\+/gu],
  ["operator-arithmetic-or-order", /\s(?:\+|-|\*|\/|%|<=|>=|<|>)\s/gu],
  ["variable-match-branch", /^\s*\|\s+[a-z][A-Za-z0-9_]*\s*=>/gmu],
  [
    "nested-constructor-pattern",
    /^\s*\|\s+[A-Z][A-Za-z0-9_.]*\s+[A-Z][A-Za-z0-9_.]*\s*=>/gmu,
  ],
];

function lineOf(source, offset) {
  let line = 1;
  for (let index = 0; index < offset; index += 1) {
    if (source[index] === "\n") line += 1;
  }
  return line;
}

walk(sourceRoot);
files.sort();

let failures = 0;
for (const file of files) {
  const raw = fs.readFileSync(file, "utf8");
  const source = maskLeanNonCode(raw);
  const relative = path.relative(root, file).replaceAll(path.sep, "/");
  for (const [label, pattern] of rules) {
    const regex = new RegExp(pattern.source, pattern.flags);
    for (const match of source.matchAll(regex)) {
      failures += 1;
      console.error(
        `PSC1KERNEL_PORT_PATTERN: ${relative}:${lineOf(source, match.index ?? 0)}: ${label}`,
      );
    }
  }
}

if (failures > 0) {
  console.error(`PSC1KERNEL_PORT_PATTERN: FAIL count=${failures}`);
  process.exit(1);
}

console.log(
  `PSC1KERNEL_PORT_PATTERN: PASS files=${files.length}`,
);
