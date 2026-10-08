import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const start = source.indexOf("def psElabTermWithFuel\n");
const end = source.indexOf("\ndef psElabTerm\n", start + 1);
if (start < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_TERM_WITH_FUEL_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = source.slice(start, end);
const required = [
  /\(fuel\s*:\s*Nat\)\s*:\s*\n\s*PsElabContext\s*->\s*\n\s*PsSyntaxTerm\s*->\s*\n\s*Option PsExpr\s*->\s*\n\s*Except PsElabError PsElabTermResult\s*:=/,
  /\| remaining \+ 1 =>\s*let smaller\s*:\s*\n\s*PsElabContext\s*->\s*\n\s*PsSyntaxTerm\s*->\s*\n\s*Option PsExpr\s*->\s*\n\s*Except PsElabError PsElabTermResult\s*:=\s*\n\s*psElabTermWithFuel remaining\s*;/,
  /fun \(context\s*:\s*PsElabContext\) =>/,
  /fun \(term\s*:\s*PsSyntaxTerm\) =>/,
  /fun \(expected\s*:\s*Option PsExpr\) =>/,
  /psElabReference\s+context\s+name\s+Option\.none/,
  /psElabApplyArgs\s+smaller\s+reference/,
  /psElabRecord\s+smaller\s+context/,
  /\| Option\.some result => Except\.ok result/,
  /\| Option\.none =>\s*match smaller\s+context\s+fn\s+Option\.none with/,
  /psElabApplyArgs\s+smaller\s+elaboratedFn/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_TERM_WITH_FUEL_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /psElabReference\s+context\s+name\s+none\b/,
  /\|\s*some\s+result\s*=>/,
  /\|\s*none\s*=>/,
  /\(psElabTermWithFuel\s+remaining\)/,
  /psElabTermWithFuel\s+remaining\s+context\b/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_TERM_WITH_FUEL_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_TERM_WITH_FUEL_SELFHOST_SOURCE_SYNTAX: PASS (fuel-recursive closure worker; context/term/expected applied post-recursion; explicit Option constructors)\n",
);
