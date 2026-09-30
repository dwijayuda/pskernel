import "./check-elab-term-with-fuel-selfhost-source-syntax.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const start = source.indexOf("def psTryElabStructuralSelfCall\n");
const end = source.indexOf("\ndef psElabTermWithFuel\n", start + 1);
if (start < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_TRY_STRUCTURAL_SELF_CALL_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = source.slice(start, end);
const required = [
  /match\s+context\.structuralRecursion\s+with\s*\| Option\.none =>\s*Except\.ok Option\.none\s*\| Option\.some recursion =>/,
  /match\s+psSyntaxNameToName sourceName\s+with\s*\| Option\.some calledName =>/,
  /psElabValidateStructuralCall\s+context\s+recursion\s+0\s+arguments\s+Option\.none/,
  /\| Except\.ok result => Except\.ok \(Option\.some result\)/,
  /\| Option\.none => Except\.ok Option\.none/,
  /\| _ =>\s*Except\.ok Option\.none/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_TRY_STRUCTURAL_SELF_CALL_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /\|\s*none\s*=>/,
  /\|\s*some\s+/,
  /Except\.ok\s+none\b/,
  /Except\.ok\s*\(some\s+/,
  /arguments\s+none\s+with/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_TRY_STRUCTURAL_SELF_CALL_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_TRY_STRUCTURAL_SELF_CALL_SELFHOST_SOURCE_SYNTAX: PASS (explicit Option constructors across structural self-call detection)\n",
);
