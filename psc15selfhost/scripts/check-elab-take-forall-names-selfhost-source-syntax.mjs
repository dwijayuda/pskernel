import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const workerStart = source.indexOf("def psElabTakeForallNamesWorker\n");
const wrapperStart = source.indexOf("\ndef psElabTakeForallNames\n", workerStart + 1);
const end = source.indexOf("\ndef psSyntaxRecordFieldName\n", wrapperStart + 1);
if (workerStart < 0 || wrapperStart < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_TAKE_FORALL_NAMES_SELFHOST_SOURCE_SYNTAX_MISSING: worker/wrapper declaration block",
  );
}

const worker = source.slice(workerStart, wrapperStart);
const wrapper = source.slice(wrapperStart, end);
const block = source.slice(workerStart, end);

if (!/\(remaining\s*:\s*Nat\)\s*:\s*\n\s*PsExpr\s*->\s*Option \(List String\)\s*:=/.test(worker)) {
  throw new Error(
    "PSC2_ELAB_TAKE_FORALL_NAMES_SELFHOST_SOURCE_SYNTAX_MISSING: remaining-recursive worker returns PsExpr closure",
  );
}
if (!/psElabTakeForallNamesWorker\s+nextRemaining\s*;/.test(worker)) {
  throw new Error(
    "PSC2_ELAB_TAKE_FORALL_NAMES_SELFHOST_SOURCE_SYNTAX_MISSING: worker recurses only on nextRemaining",
  );
}
if (!/smaller\s+body/.test(worker)) {
  throw new Error(
    "PSC2_ELAB_TAKE_FORALL_NAMES_SELFHOST_SOURCE_SYNTAX_MISSING: changed body applied after structural recursion",
  );
}
if (!/psElabTakeForallNamesWorker\s+remaining\s+type/.test(wrapper)) {
  throw new Error(
    "PSC2_ELAB_TAKE_FORALL_NAMES_SELFHOST_SOURCE_SYNTAX_MISSING: thin wrapper delegates to worker",
  );
}
if (/psElabTakeForallNames\s+nextRemaining\s+body/.test(block)) {
  throw new Error(
    "PSC2_ELAB_TAKE_FORALL_NAMES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: changing type argument crosses recursive call",
  );
}
if (!/Option\.some\s+\[\]/.test(worker)) {
  throw new Error(
    "PSC2_ELAB_TAKE_FORALL_NAMES_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some empty-list value",
  );
}
if (!/Option\.some\s+\(List\.cons/.test(worker)) {
  throw new Error(
    "PSC2_ELAB_TAKE_FORALL_NAMES_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some list value",
  );
}
if (!/Option\.none/.test(worker)) {
  throw new Error(
    "PSC2_ELAB_TAKE_FORALL_NAMES_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.none value",
  );
}
if (/\n\s*some\s+/.test(block) || /=>\s*none\b/.test(block)) {
  throw new Error(
    "PSC2_ELAB_TAKE_FORALL_NAMES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: unqualified Option value remains",
  );
}

process.stdout.write(
  "PSC2_ELAB_TAKE_FORALL_NAMES_SELFHOST_SOURCE_SYNTAX: PASS (remaining-recursive worker; post-recursion PsExpr; explicit Option values)\n",
);

const lastSegmentStart = source.indexOf("def psSyntaxRecordLastSegment\n");
const fieldNameStart = source.indexOf("\ndef psSyntaxRecordFieldName\n", lastSegmentStart + 1);
const fieldNameEnd = source.indexOf("\ndef psSyntaxRecordFieldMatchesName\n", fieldNameStart + 1);
if (lastSegmentStart < 0 || fieldNameStart < 0 || fieldNameEnd < 0) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELD_NAME_SELFHOST_SOURCE_SYNTAX_MISSING: local last-segment helper/field-name block",
  );
}

const lastSegment = source.slice(lastSegmentStart, fieldNameStart);
const fieldName = source.slice(fieldNameStart, fieldNameEnd);
const recordBlock = source.slice(lastSegmentStart, fieldNameEnd);

if (!/\(segments\s*:\s*List String\)\s*:\s*Option String\s*:=/.test(lastSegment)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELD_NAME_SELFHOST_SOURCE_SYNTAX_MISSING: local List String helper",
  );
}
if (!/psSyntaxRecordLastSegment\s+rest/.test(lastSegment)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELD_NAME_SELFHOST_SOURCE_SYNTAX_MISSING: structural recursion on rest",
  );
}
if (!/Option\.none/.test(lastSegment) || !/Option\.some\s+first/.test(lastSegment)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELD_NAME_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option values",
  );
}
if (/List\.reverse/.test(recordBlock)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELD_NAME_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: generic List.reverse remains",
  );
}
if (!/psSyntaxRecordLastSegment\s+syntaxName\.segments/.test(fieldName)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELD_NAME_SELFHOST_SOURCE_SYNTAX_MISSING: field-name delegates to local helper",
  );
}

process.stdout.write(
  "PSC2_ELAB_RECORD_FIELD_NAME_SELFHOST_SOURCE_SYNTAX: PASS (local structural last-segment helper; no List.reverse; explicit Option values)\n",
);
