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

const hasFieldStart = source.indexOf("def psSyntaxRecordHasField\n");
const hasFieldEnd = source.indexOf("\ndef psSyntaxRecordHasNamedField\n", hasFieldStart + 1);
if (hasFieldStart < 0 || hasFieldEnd < 0) {
  throw new Error(
    "PSC2_ELAB_RECORD_HAS_FIELD_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const hasField = source.slice(hasFieldStart, hasFieldEnd);
if (/List\.any/.test(hasField)) {
  throw new Error(
    "PSC2_ELAB_RECORD_HAS_FIELD_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: generic List.any remains",
  );
}
if (!/match\s+fields\s+with/.test(hasField)) {
  throw new Error(
    "PSC2_ELAB_RECORD_HAS_FIELD_SELFHOST_SOURCE_SYNTAX_MISSING: structural field-list match",
  );
}
if (!/psSyntaxRecordFieldMatchesName\s+name\s+field/.test(hasField)) {
  throw new Error(
    "PSC2_ELAB_RECORD_HAS_FIELD_SELFHOST_SOURCE_SYNTAX_MISSING: local field predicate",
  );
}
if (!/psSyntaxRecordHasField\s+rest\s+name/.test(hasField)) {
  throw new Error(
    "PSC2_ELAB_RECORD_HAS_FIELD_SELFHOST_SOURCE_SYNTAX_MISSING: structural recursion on rest with invariant name",
  );
}

process.stdout.write(
  "PSC2_ELAB_RECORD_HAS_FIELD_SELFHOST_SOURCE_SYNTAX: PASS (local structural traversal; no List.any)\n",
);

const fieldsMatchWorkerStart = source.indexOf("def psSyntaxRecordFieldsMatchWorker\n");
const fieldsMatchStart = source.indexOf("\ndef psSyntaxRecordFieldsMatch\n", fieldsMatchWorkerStart + 1);
const fieldsMatchEnd = source.indexOf("\ndef psSyntaxRecordFindField\n", fieldsMatchStart + 1);
if (fieldsMatchWorkerStart < 0 || fieldsMatchStart < 0 || fieldsMatchEnd < 0) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELDS_MATCH_SELFHOST_SOURCE_SYNTAX_MISSING: worker/wrapper declaration block",
  );
}

const fieldsMatchWorker = source.slice(fieldsMatchWorkerStart, fieldsMatchStart);
const fieldsMatch = source.slice(fieldsMatchStart, fieldsMatchEnd);
const fieldsMatchBlock = source.slice(fieldsMatchWorkerStart, fieldsMatchEnd);
if (/List\.all/.test(fieldsMatchBlock)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELDS_MATCH_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: generic List.all remains",
  );
}
if (!/\(names\s*:\s*List String\)\s*:\s*\n\s*List \(Prod PsSyntaxName PsSyntaxTerm\)\s*->\s*Bool\s*:=/.test(fieldsMatchWorker)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELDS_MATCH_SELFHOST_SOURCE_SYNTAX_MISSING: names-recursive worker returns fields closure",
  );
}
if (!/psSyntaxRecordFieldsMatchWorker\s+rest\s*;/.test(fieldsMatchWorker)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELDS_MATCH_SELFHOST_SOURCE_SYNTAX_MISSING: worker recurses only on rest",
  );
}
if (!/psSyntaxRecordHasNamedField\s+fields\s+name/.test(fieldsMatchWorker)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELDS_MATCH_SELFHOST_SOURCE_SYNTAX_MISSING: local named-field predicate",
  );
}
if (!/smaller\s+fields/.test(fieldsMatchWorker)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELDS_MATCH_SELFHOST_SOURCE_SYNTAX_MISSING: invariant fields applied after structural recursion",
  );
}
if (!/Nat\.beq\s+\(psElabListLength fields\)\s+\(psElabListLength names\)/.test(fieldsMatch)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELDS_MATCH_SELFHOST_SOURCE_SYNTAX_MISSING: wrapper preserves exact field-count check",
  );
}
if (!/psSyntaxRecordFieldsMatchWorker\s+names\s+fields/.test(fieldsMatch)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIELDS_MATCH_SELFHOST_SOURCE_SYNTAX_MISSING: wrapper delegates membership check to worker",
  );
}

process.stdout.write(
  "PSC2_ELAB_RECORD_FIELDS_MATCH_SELFHOST_SOURCE_SYNTAX: PASS (names-recursive closure worker; exact count preserved; no List.all)\n",
);

const findFieldStart = source.indexOf("def psSyntaxRecordFindField\n");
const findFieldEnd = source.indexOf("\ndef psSyntaxRecordOrderFields\n", findFieldStart + 1);
if (findFieldStart < 0 || findFieldEnd < 0) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIND_FIELD_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const findField = source.slice(findFieldStart, findFieldEnd);
if (!/match\s+fields\s+with/.test(findField)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIND_FIELD_SELFHOST_SOURCE_SYNTAX_MISSING: structural field-list match",
  );
}
if (!/psSyntaxRecordFindField\s+rest\s+name/.test(findField)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIND_FIELD_SELFHOST_SOURCE_SYNTAX_MISSING: structural recursion on rest with invariant name",
  );
}
if (!/Option\.none/.test(findField)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIND_FIELD_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.none value/pattern",
  );
}
if (!/Option\.some\s+fieldName/.test(findField)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIND_FIELD_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some field-name pattern",
  );
}
if (!/Option\.some\s+\(Prod\.snd field\)/.test(findField)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIND_FIELD_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some field value",
  );
}
if (/\|\s*none\s*=>/.test(findField) || /\|\s*some\s+/.test(findField) || /=>\s*none\b/.test(findField) || /\n\s*some\s+/.test(findField)) {
  throw new Error(
    "PSC2_ELAB_RECORD_FIND_FIELD_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: unqualified Option constructor remains",
  );
}

process.stdout.write(
  "PSC2_ELAB_RECORD_FIND_FIELD_SELFHOST_SOURCE_SYNTAX: PASS (structural field lookup; explicit Option constructors)\n",
);

const orderFieldsStart = source.indexOf("def psSyntaxRecordOrderFields\n");
const orderFieldsEnd = source.indexOf("\ndef psElabRecordCandidateForInfo\n", orderFieldsStart + 1);
if (orderFieldsStart < 0 || orderFieldsEnd < 0) {
  throw new Error(
    "PSC2_ELAB_RECORD_ORDER_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const orderFields = source.slice(orderFieldsStart, orderFieldsEnd);
if (!/Option \(List PsSyntaxTerm\)\s*:=/.test(orderFields)) {
  throw new Error(
    "PSC2_ELAB_RECORD_ORDER_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: Option List return type",
  );
}
if (!/match\s+names\s+with/.test(orderFields)) {
  throw new Error(
    "PSC2_ELAB_RECORD_ORDER_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: structural names match",
  );
}
if (!/psSyntaxRecordOrderFields\s+fields\s+rest/.test(orderFields)) {
  throw new Error(
    "PSC2_ELAB_RECORD_ORDER_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: structural recursion on rest with invariant fields",
  );
}
if (!/Option\.some\s+\[\]/.test(orderFields)) {
  throw new Error(
    "PSC2_ELAB_RECORD_ORDER_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some empty result",
  );
}
if (!/Option\.none/.test(orderFields)) {
  throw new Error(
    "PSC2_ELAB_RECORD_ORDER_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.none value/pattern",
  );
}
if (!/Option\.some\s+value/.test(orderFields)) {
  throw new Error(
    "PSC2_ELAB_RECORD_ORDER_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some field value pattern",
  );
}
if (!/Option\.some\s+values/.test(orderFields)) {
  throw new Error(
    "PSC2_ELAB_RECORD_ORDER_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some recursive values pattern",
  );
}
if (!/Option\.some\s+\(List\.cons\s+value\s+values\)/.test(orderFields)) {
  throw new Error(
    "PSC2_ELAB_RECORD_ORDER_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some ordered result",
  );
}
if (/\|\s*none\s*=>/.test(orderFields) || /\|\s*some\s+/.test(orderFields) || /=>\s*none\b/.test(orderFields) || /\n\s*some\s+/.test(orderFields)) {
  throw new Error(
    "PSC2_ELAB_RECORD_ORDER_FIELDS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: unqualified Option constructor remains",
  );
}

process.stdout.write(
  "PSC2_ELAB_RECORD_ORDER_FIELDS_SELFHOST_SOURCE_SYNTAX: PASS (structural name ordering; explicit Option constructors)\n",
);
const candidateInfoStart = source.indexOf("def psElabRecordCandidateForInfo\n");
const candidateInfoEnd = source.indexOf("\ndef psElabRecordCandidateFromExpected\n", candidateInfoStart + 1);
if (candidateInfoStart < 0 || candidateInfoEnd < 0) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATE_INFO_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const candidateInfo = source.slice(candidateInfoStart, candidateInfoEnd);
if (!/if\s+info\.isStructure\s+then/.test(candidateInfo)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATE_INFO_SELFHOST_SOURCE_SYNTAX_MISSING: structure guard",
  );
}
if (!/match\s+info\.constructors\s+with/.test(candidateInfo)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATE_INFO_SELFHOST_SOURCE_SYNTAX_MISSING: constructor-list match",
  );
}
if (!/Option\.none/.test(candidateInfo)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATE_INFO_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.none values",
  );
}
if (!/Option\.some\s+constructorInfo/.test(candidateInfo) || !/Option\.some\s+fieldsType/.test(candidateInfo) || !/Option\.some\s+fieldNames/.test(candidateInfo)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATE_INFO_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some matched values",
  );
}
if (!/Option\.some\s*\{/.test(candidateInfo)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATE_INFO_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some candidate value",
  );
}
if (/\|\s*none\s*=>/.test(candidateInfo) || /\|\s*some\s+/.test(candidateInfo) || /=>\s*none\b/.test(candidateInfo) || /\n\s*some\s+/.test(candidateInfo)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATE_INFO_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: unqualified Option constructor remains",
  );
}

process.stdout.write(
  "PSC2_ELAB_RECORD_CANDIDATE_INFO_SELFHOST_SOURCE_SYNTAX: PASS (structure candidate lookup; explicit Option constructors)\n",
);

const candidateExpectedStart = source.indexOf("def psElabRecordCandidateFromExpected\n");
const candidateExpectedEnd = source.indexOf("\ndef psElabRecordCandidates\n", candidateExpectedStart + 1);
if (candidateExpectedStart < 0 || candidateExpectedEnd < 0) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATE_EXPECTED_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const candidateExpected = source.slice(candidateExpectedStart, candidateExpectedEnd);
if (!/match\s+view\.head\s+with/.test(candidateExpected) || !/\.constE\s+typeName\s+_/.test(candidateExpected)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATE_EXPECTED_SELFHOST_SOURCE_SYNTAX_MISSING: head view match",
  );
}
if (!/psEnvironmentFindInductive/.test(candidateExpected)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATE_EXPECTED_SELFHOST_SOURCE_SYNTAX_MISSING: inductive lookup",
  );
}
if (!/Option\.none/.test(candidateExpected) || !/Option\.some\s+info/.test(candidateExpected)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATE_EXPECTED_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option values",
  );
}
if (/\|\s*none\s*=>/.test(candidateExpected) || /\|\s*some\s+/.test(candidateExpected) || /=>\s*none\b/.test(candidateExpected) || /\n\s*some\s+/.test(candidateExpected)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATE_EXPECTED_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: unqualified Option constructor remains",
  );
}

process.stdout.write(
  "PSC2_ELAB_RECORD_CANDIDATE_EXPECTED_SELFHOST_SOURCE_SYNTAX: PASS (expected-type candidate lookup; explicit Option constructors)\n",
);

const candidatesStart = source.indexOf("def psElabRecordCandidates\n");
const candidatesEnd = source.indexOf("\ndef psElabUniqueRecordCandidate\n", candidatesStart + 1);
if (candidatesStart < 0 || candidatesEnd < 0) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const candidates = source.slice(candidatesStart, candidatesEnd);
if (!/match\s+declarations\s+with/.test(candidates)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_MISSING: declaration-list match",
  );
}
if (!/psElabRecordCandidates\s+environment\s+fields\s+rest/.test(candidates)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_MISSING: structural recursion on rest",
  );
}
if (/\bList\.reverse\b/.test(candidates)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: generic List.reverse remains",
  );
}

process.stdout.write(
  "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX: PASS (structural declaration traversal; no List.reverse)\n",
);

if (!/let\s+candidates\s*:=\s*psElabRecordCandidates\s+environment\s+fields\s+rest\s+candidatesRev/.test(candidates)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_MISSING: post-recursion candidate result",
  );
}
if (/\(List\.cons\s+candidate\s+candidatesRev\)/.test(candidates)) {
  throw new Error(
    "PSC2_ELAB_RECORD_CANDIDATES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: varying recursive accumulator",
  );
}
