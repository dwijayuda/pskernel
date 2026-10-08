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
  /def psReadFixedHex\s*\(count : Nat\) :\s*List Char ->\s*Nat ->\s*Option \(Prod Nat \(List Char\)\) :=\s*match count with/,
  /let smaller : List Char -> Nat -> Option \(Prod Nat \(List Char\)\) :=\s*psReadFixedHex nextCount;/,
  /smaller\s+rest\s*\(Nat\.add \(Nat\.mul value 16\) digit\)/,
  /def psStringFromReversedChars\s*\(charsRev : List Char\) : String :=\s*match charsRev with/,
  /\| \[\] =>\s*""/,
  /\| char :: rest =>\s*String\.push \(psStringFromReversedChars rest\) char/,
  /Option\.some \(psStringFromReversedChars charsRev\)/,
  /def psDecodeStringBodyWithFuel\s*\(fuel : Nat\) :\s*List Char ->\s*List Char ->\s*Option String :=\s*match fuel with/,
  /let smaller : List Char -> List Char -> Option String :=\s*psDecodeStringBodyWithFuel nextFuel;/,
  /smaller\s+rest\s*\(List\.cons \(Char\.ofNat 34\) charsRev\)/,
  /smaller\s+rest\s*\(List\.cons \(Char\.ofNat 92\) charsRev\)/,
  /smaller\s+\(Prod\.snd decoded\)\s*\(List\.cons \(Prod\.fst decoded\) charsRev\)/,
  /smaller\s+restAfterChar\s*\(List\.cons char charsRev\)/,
  /def psCharListLength\s*\(chars : List Char\) : Nat :=\s*match chars with/,
  /\| \[\] =>\s*0/,
  /\| _ :: rest =>\s*Nat\.succ \(psCharListLength rest\)/,
  /Nat\.succ \(psCharListLength rest\)/,
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
  /String\.ofList/,
  /List\.reverse/,
  /List\.length/,
  /'(?:\\.|[^'\\])+'/,                  // character literal syntax
  /def psParseNaturalChars\s*\(chars : List Char\)\s*\(value : Nat\)/,
  /psParseNaturalChars\s+rest\s+value/,
  /psParseNaturalChars\s+rest\s*\(Nat\.add/,
  /def psReadFixedHex\s*\(count : Nat\)\s*\(chars : List Char\)\s*\(value : Nat\)/,
  /psReadFixedHex\s+nextCount\s+rest/,
  /def psDecodeStringBodyWithFuel\s*\(fuel : Nat\)\s*\(chars : List Char\)\s*\(charsRev : List Char\)/,
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

const decodeFuelSelfReferences =
  source.match(/psDecodeStringBodyWithFuel\s+nextFuel/g) ?? [];
if (decodeFuelSelfReferences.length !== 1) {
  throw new Error(
    `PSC2_ELAB_LITERAL_SELFHOST_SOURCE_SYNTAX_RECURSION_REFERENCE_COUNT: ${decodeFuelSelfReferences.length}`,
  );
}

process.stdout.write(
  "PSC2_ELAB_LITERAL_SELFHOST_SOURCE_SYNTAX: PASS (bootstrap string traversal/rebuild/fuel, explicit Char/Nat/List operations, invariant-safe natural/fixed-hex/string-decode recursion)\n",
);
