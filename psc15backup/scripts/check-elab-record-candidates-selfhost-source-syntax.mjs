import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const start = source.indexOf("def psElabRecordCandidates\n");
const end = source.indexOf("\ndef psElabUniqueRecordCandidate\n", start + 1);
if (start < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = source.slice(start, end);

if (!/match\s+declarations\s+with/.test(block)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_MISSING: declaration-list match",
  );
}
if (!/let\s+candidates\s*:=\s*psElabRecordCandidates\s+environment\s+fields\s+rest\s+candidatesRev\s*;/.test(block)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_MISSING: explicit semicolon after recursive candidate binding",
  );
}
if (!/match\s+declaration\s+with/.test(block)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_MISSING: declaration match after sequenced recursive binding",
  );
}
if (/\(List\.cons\s+candidate\s+candidatesRev\)/.test(block)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: varying recursive accumulator",
  );
}
if (/\bList\.reverse\b/.test(block)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: generic List.reverse remains",
  );
}

const uniqueStart = source.indexOf("def psElabUniqueRecordCandidate\n");
const uniqueEnd = source.indexOf("\ndef psElabRecord\n", uniqueStart + 1);
if (uniqueStart < 0 || uniqueEnd < 0) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_MISSING: unique candidate block",
  );
}
const unique = source.slice(uniqueStart, uniqueEnd);
const uniqueRequired = [
  /\| \[\] =>\s*Option\.none/,
  /\| candidate :: rest =>\s*match rest with\s*\| \[\] => Option\.some candidate\s*\| _ :: _ => Option\.none/,
];
for (const pattern of uniqueRequired) {
  if (!pattern.test(unique)) {
    throw new Error(
      `PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_MISSING: unique candidate ${pattern}`,
    );
  }
}
const uniqueForbidden = [
  /\| \[\] =>\s*none/,
  /\| \[\] => some candidate/,
  /\| _ :: _ => none/,
];
for (const pattern of uniqueForbidden) {
  if (pattern.test(unique)) {
    throw new Error(
      `PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: unique candidate ${pattern}`,
    );
  }
}

const recordStart = source.indexOf("def psElabRecord\n");
const recordEnd = source.indexOf("\ndef psElabSyntaxLocalId\n", recordStart + 1);
if (recordStart < 0 || recordEnd < 0) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_MISSING: record elaborator block",
  );
}
const record = source.slice(recordStart, recordEnd);
const recordRequired = [
  /let\s+candidate\s*:\s*Option PsElabRecordCandidate\s*:=\s*match expected with/,
  /if\s+psSyntaxRecordFieldsMatch\s+fields\s+found\.fieldNames\s+then\s+Option\.some found\s+else\s+Option\.none/,
  /psElabResolvedTerm\s+context\s*\(PsExpr\.constE\s+found\.constructorName\s+\[\]\)\s+Option\.none/,
];
for (const pattern of recordRequired) {
  if (!pattern.test(record)) {
    throw new Error(
      `PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_MISSING: psElabRecord ${pattern}`,
    );
  }
}
const recordForbidden = [
  /let\s+candidate\s*:=\s*match expected with/,
  /then\s+some found\s+else\s+none/,
  /psElabResolvedTerm\s+context\s*\(PsExpr\.constE\s+found\.constructorName\s+\[\]\)\s+none/,
];
for (const pattern of recordForbidden) {
  if (pattern.test(record)) {
    throw new Error(
      `PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: psElabRecord ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX: PASS (explicit recursive-let sequencing; structural declaration traversal; explicit unique-candidate Option constructors; typed record-candidate match)\n",
);
