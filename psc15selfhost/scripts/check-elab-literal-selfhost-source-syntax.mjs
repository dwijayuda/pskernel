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
  /import Ps\.Syntax\.Cursor/,
  /def psCharCodeEq\s*\(char : Char\)\s*\(code : Nat\) : Bool :=\s*Nat\.beq \(Char\.toNat char\) code/,
  /if psCharCodeEq char 48 then/,
  /if psCharCodeEq char 95 then/,
  /def psParseNaturalChars\s*\(chars : List Char\) :\s*Nat -> Option Nat :=\s*match chars with/,
  /let smaller : Nat -> Option Nat :=\s*psParseNaturalChars rest;/,
  /fun \(value : Nat\) =>/,
  /smaller value/,
  /smaller\s*\(Nat\.add \(Nat\.mul value 10\) digit\)/,
  /psParseNaturalChars \(psLexStringToList text\) 0/,
  /match psLexStringToList text with/,
  /Nat\.add \(Nat\.mul value 10\) digit/,
  /Nat\.add \(Nat\.mul value 16\) digit/,
  /if Nat\.blt value 55296 then/,
  /else if Nat\.blt 57343 value then/,
  /Nat\.blt value 1114112/,
  /List\.cons \(Char\.ofNat 34\) charsRev/,
  /List\.cons \(Char\.ofNat 92\) charsRev/,
  /List\.cons \(Char\.ofNat 10\) charsRev/,
  /List\.cons \(Char\.ofNat 13\) charsRev/,
  /List\.cons \(Char\.ofNat 9\) charsRev/,
  /List\.cons \(Char\.ofNat 0\) charsRev/,
  /List\.cons \(Prod\.fst decoded\) charsRev/,
  /List\.cons char charsRev/,
  /Char\.ofNat 39/,
];
for (const pattern of required) {
  if (!pattern.test(source)) {
    throw new Error(`PSC2_ELAB_LITERAL_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`);
  }
}

const forbidden = [
  /String\.toList/,
  /'(?:\\.|[^'\\])+'/,                  // character literal syntax
  /def psParseNaturalChars\s*\(chars : List Char\)\s*\(value : Nat\)/,
  /psParseNaturalChars\s+rest\s+value/,
  /psParseNaturalChars\s+rest\s*\(Nat\.add/,
  /value\s*\*\s*(?:10|16)/,             // arithmetic infix in literal accumulators
  /value\s*<\s*(?:55296|1114112)/,       // scalar-bound infix comparison
  /57343\s*<\s*value/,
  /Char\.ofNat\s+\d+\s*::\s*charsRev/, // term-level cons in decoded strings
  /Prod\.fst decoded\s*::\s*charsRev/,
  /\(char\s*::\s*charsRev\)/,
];
for (const pattern of forbidden) {
  if (pattern.test(source)) {
    throw new Error(`PSC2_ELAB_LITERAL_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`);
  }
}

process.stdout.write(
  "PSC2_ELAB_LITERAL_SELFHOST_SOURCE_SYNTAX: PASS (bootstrap string traversal, explicit Char/Nat/List operations, invariant-safe natural recursion)\n",
);
