import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
);
const sourceRoot = path.join(
  root,
  "packages",
  "backend-wasm",
  "src",
  "Ps",
  "BackendWasm",
);

const files = [
  "Binary.lean",
  "Lower.lean",
  "LowerFloat.lean",
  "LowerInt.lean",
  "Model.lean",
  "RuntimeInt.lean",
  "RuntimeNat.lean",
  "Support.lean",
  "Type.lean",
];

const totals = {
  termCons: 0,
  singletonPattern: 0,
  map: 0,
  any: 0,
  foldl: 0,
  append: 0,
  numericProjection: 0,
  multiEquationAlternative: 0,
};

const perFile = [];

for (const file of files) {
  const source = await readFile(path.join(sourceRoot, file), "utf8");
  const lines = source.split(/\r?\n/u);
  const counts = {
    termCons: 0,
    singletonPattern: 0,
    map: (source.match(/\.map\b/gu) ?? []).length,
    any: (source.match(/\.any\b/gu) ?? []).length,
    foldl: (source.match(/\.foldl\b/gu) ?? []).length,
    append: (source.match(/\+\+/gu) ?? []).length,
    numericProjection: 0,
    multiEquationAlternative: 0,
  };

  for (const line of lines) {
    if (line.includes("::") && !/^\s*\|/u.test(line)) {
      counts.termCons += 1;
    }
    if (/^\s*\|\s*\[[A-Za-z_][A-Za-z0-9_]*\]\s*=>/u.test(line)) {
      counts.singletonPattern += 1;
    }
    if (/\.\d\b/u.test(line)) {
      counts.numericProjection += 1;
    }
    if (/^\s*\|[^=\n]*,/u.test(line)) {
      counts.multiEquationAlternative += 1;
    }
  }

  for (const key of Object.keys(totals)) {
    totals[key] += counts[key];
  }
  perFile.push({ file, counts });
}

const closed = [
  "termCons",
  "singletonPattern",
  "map",
  "any",
  "foldl",
  "numericProjection",
];

for (const key of closed) {
  if (totals[key] !== 0) {
    throw new Error(
      `PSC2_WASM_SELFHOST_STYLE_REGRESSION: ${key}=${totals[key]}`,
    );
  }
}

for (const entry of perFile) {
  const active = Object.entries(entry.counts)
    .filter(([, value]) => value !== 0)
    .map(([key, value]) => `${key}=${value}`)
    .join(" ");
  if (active) {
    process.stdout.write(
      `PSC2_WASM_SELFHOST_REMAINING: ${entry.file} ${active}\n`,
    );
  }
}

process.stdout.write(
  [
    "PSC2_WASM_SELFHOST_STYLE: PASS",
    ...closed.map(key => `${key}=0`),
    `supported.appendNotation=${totals.append}`,
    `supported.equationAlternatives=${totals.multiEquationAlternative}`,
  ].join(" ") + "\n",
);
