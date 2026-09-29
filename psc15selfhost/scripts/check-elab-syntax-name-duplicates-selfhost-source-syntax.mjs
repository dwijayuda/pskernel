import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const oldBlock = `def psSyntaxNameListHasDuplicate : List PsSyntaxName -> Bool
  | List.nil => false
  | List.cons name rest =>
      if psSyntaxNameIsWildcardBinder name then
        psSyntaxNameListHasDuplicate rest
      else
        let coreName := psSyntaxNameToName name;
        let duplicated :=
          List.any rest (psSyntaxNameMatchesCore coreName);
        if duplicated then
          true
        else
          psSyntaxNameListHasDuplicate rest`;

const newBlock = `def psSyntaxNameListContainsCore
    (coreName : Option PsName)
    (candidates : List PsSyntaxName) : Bool :=
  match candidates with
  | List.nil =>
      false
  | List.cons candidate rest =>
      if psSyntaxNameMatchesCore coreName candidate then
        true
      else
        psSyntaxNameListContainsCore coreName rest

def psSyntaxNameListHasDuplicate
    (names : List PsSyntaxName) : Bool :=
  match names with
  | List.nil =>
      false
  | List.cons name rest =>
      if psSyntaxNameIsWildcardBinder name then
        psSyntaxNameListHasDuplicate rest
      else
        let coreName := psSyntaxNameToName name;
        if psSyntaxNameListContainsCore coreName rest then
          true
        else
          psSyntaxNameListHasDuplicate rest`;

const match = source.match(
  /def psSyntaxNameListContainsCore([\s\S]*?)(?=\ndef psElabMatchFields)/,
);
if (match === null) {
  if (!source.includes(oldBlock)) {
    throw new Error(
      "PSC2_ELAB_SYNTAX_NAME_DUPLICATES_PATCH_SOURCE_MISMATCH",
    );
  }
  const patched = source.replace(oldBlock, newBlock);
  process.stdout.write(
    `PSC2_PATCHED_TERM_BASE64_BEGIN\n${Buffer.from(patched, "utf8").toString("base64")}\nPSC2_PATCHED_TERM_BASE64_END\n`,
  );
  throw new Error(
    "PSC2_ELAB_SYNTAX_NAME_DUPLICATES_SELFHOST_SOURCE_SYNTAX_MISSING: structural duplicate-name helper block",
  );
}

const block = match[0];
const required = [
  /def psSyntaxNameListContainsCore\s*\(coreName : Option PsName\)\s*\(candidates : List PsSyntaxName\) : Bool :=\s*match candidates with/,
  /psSyntaxNameListContainsCore\s+coreName\s+rest/,
  /def psSyntaxNameListHasDuplicate\s*\(names : List PsSyntaxName\) : Bool :=\s*match names with/,
  /psSyntaxNameListHasDuplicate\s+rest/,
  /psSyntaxNameListContainsCore\s+coreName\s+rest/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_SYNTAX_NAME_DUPLICATES_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /\bList\.any\b/,
  /def psSyntaxNameListHasDuplicate\s*:\s*List PsSyntaxName -> Bool/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_SYNTAX_NAME_DUPLICATES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_SYNTAX_NAME_DUPLICATES_SELFHOST_SOURCE_SYNTAX: PASS (explicit structural duplicate-name recursion; no unavailable List.any dependency)\n",
);
