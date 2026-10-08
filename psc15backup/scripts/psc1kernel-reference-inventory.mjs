import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  auditPsc1Source,
  maskLeanNonCode,
} from "./psc1-source-profile.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const kernelRoot = path.join(root, "packages", "pskernel", "PSC1Kernel");

const semanticFiles = [
  "Name.lean",
  "Level.lean",
  "Expr.lean",
  "Instantiate.lean",
  "Declaration.lean",
  "Environment.lean",
  "LocalContext.lean",
  "TypeChecker.lean",
  "CheckerState.lean",
  "CheckerStateful.lean",
  "CheckerReductionStateful.lean",
  "CheckerLazyDeltaStateful.lean",
  "CheckerDefEqStateful.lean",
  "CheckerDefEqStatefulClosed.lean",
  "CheckerDefEqStatefulReduced.lean",
  "CheckerRecursorStateful.lean",
  "CheckerSession.lean",
  "Quot.lean",
  "Kernel.lean",
  "Inductive.lean",
  "MutualInductive.lean",
  "NestedInductive.lean",
];

const migrationRules = [
  {
    key: "partial-def",
    class: "recursion-totality",
    pattern: /\bpartial\s+def\b/g,
  },
  {
    key: "private-def",
    class: "mechanical-name-scope",
    pattern: /\bprivate\s+(?:partial\s+)?def\b/g,
  },
  {
    key: "namespace",
    class: "mechanical-name-scope",
    pattern: /\bnamespace\b/g,
  },
  {
    key: "abbrev",
    class: "semantic-alias-rewrite",
    pattern: /\babbrev\b/g,
  },
  {
    key: "mutual",
    class: "recursion-architecture",
    pattern: /\bmutual\b/g,
  },
  {
    key: "let-rec",
    class: "recursion-review",
    pattern: /\blet\s+rec\b/g,
  },
  {
    key: "instance",
    class: "typeclass-review",
    pattern: /(^|\n)\s*instance\b/g,
  },
];

function lineOf(source, offset) {
  let line = 1;
  for (let index = 0; index < offset; index += 1) {
    if (source[index] === "\n") line += 1;
  }
  return line;
}

function allMatches(source, pattern) {
  const matches = [];
  const regex = new RegExp(pattern.source, pattern.flags.includes("g")
    ? pattern.flags
    : pattern.flags + "g");
  for (const match of source.matchAll(regex)) {
    matches.push(lineOf(source, match.index ?? 0));
  }
  return matches;
}

const result = {
  schemaVersion: 1,
  semanticFileCount: semanticFiles.length,
  files: [],
  totals: {},
  profileViolationFiles: 0,
};

for (const relative of semanticFiles) {
  const file = path.join(kernelRoot, relative);
  const source = fs.readFileSync(file, "utf8");
  const audited = maskLeanNonCode(source);
  const violations = auditPsc1Source(source).map((rule) => rule.key);
  if (violations.length > 0) result.profileViolationFiles += 1;

  const categories = {};
  for (const rule of migrationRules) {
    const lines = allMatches(audited, rule.pattern);
    if (lines.length === 0) continue;
    categories[rule.key] = {
      class: rule.class,
      count: lines.length,
      lines,
    };
    result.totals[rule.key] = (result.totals[rule.key] ?? 0) + lines.length;
  }

  result.files.push({
    file: relative,
    profileViolations: violations,
    categories,
  });
}

if (process.argv.includes("--json")) {
  process.stdout.write(JSON.stringify(result, null, 2) + "\n");
} else {
  console.log(
    `PSC1KERNEL_REFERENCE_INVENTORY: ${result.semanticFileCount} semantic modules; ${result.profileViolationFiles} violate the proven PSC1 profile`,
  );
  for (const [key, count] of Object.entries(result.totals).sort()) {
    console.log(`PSC1KERNEL_REFERENCE_INVENTORY_COUNT: ${key}=${count}`);
  }
  for (const file of result.files) {
    const entries = Object.entries(file.categories);
    if (file.profileViolations.length === 0 && entries.length === 0) continue;
    const summary = entries
      .map(([key, value]) => `${key}:${value.count}`)
      .join(",");
    console.log(
      `PSC1KERNEL_REFERENCE_INVENTORY_FILE: ${file.file} profile=[${file.profileViolations.join(",")}] migration=[${summary}]`,
    );
  }
}
