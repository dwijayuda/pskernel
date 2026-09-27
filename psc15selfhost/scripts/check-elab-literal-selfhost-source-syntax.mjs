import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Literal.lean"),
  "utf8",
);

const required = [
  /def psCharCodeEq\s*\(char : Char\)\s*\(code : Nat\) : Bool :=\s*Nat\.beq \(Char\.toNat char\) code/,
  /if psCharCodeEq char 48 then/,
  /if psCharCodeEq char 95 then/,
  /Char\.ofNat 34/,
  /Char\.ofNat 39/,
  /Char\.ofNat 92/,
  /Char\.ofNat 10/,
  /Char\.ofNat 13/,
  /Char\.ofNat 9/,
];
for (const pattern of required) {
  if (!pattern.test(source)) {
    throw new Error(`PSC2_ELAB_LITERAL_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`);
  }
}

const characterLiteral = /'(?:\\.|[^'\\])+'/;
if (characterLiteral.test(source)) {
  throw new Error("PSC2_ELAB_LITERAL_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: character literal syntax");
}

process.stdout.write(
  "PSC2_ELAB_LITERAL_SELFHOST_SOURCE_SYNTAX: PASS (explicit Char.toNat comparisons and Char.ofNat construction)\n",
);
