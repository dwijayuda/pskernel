import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const start = source.indexOf("def psElabSyntaxLocalId\n");
const end = source.indexOf("\ndef psElabNatListAt", start + 1);
if (start < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_SYNTAX_LOCAL_ID_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = source.slice(start, end);
const required = [
  /match\s+psSyntaxNameToName sourceName\s+with\s*\| Option\.none => Option\.none\s*\| Option\.some name =>/,
  /match\s+psResolveName\s+context\.localContext\s+context\.environment\s+name\s+with\s*\| Option\.none => Option\.none\s*\| Option\.some resolved =>/,
  /\| \.local id => Option\.some id/,
  /\| \.global _ => Option\.none/,
  /\| _ => Option\.none/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_SYNTAX_LOCAL_ID_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /\|\s*none\s*=>/,
  /\|\s*some\s+/,
  /=>\s*none\b/,
  /=>\s*some\s+/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_SYNTAX_LOCAL_ID_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_SYNTAX_LOCAL_ID_SELFHOST_SOURCE_SYNTAX: PASS (explicit Option constructors across local-id resolution)\n",
);

const natListAtWorkerStart = source.indexOf("def psElabNatListAtWorker\n");
const natListAtStart = source.indexOf("\ndef psElabNatListAt\n", natListAtWorkerStart + 1);
const natListAtEnd = source.indexOf("\ndef psElabValidateStructuralCall\n", natListAtStart + 1);
if (natListAtWorkerStart < 0 || natListAtStart < 0 || natListAtEnd < 0) {
  throw new Error(
    "PSC2_ELAB_NAT_LIST_AT_SELFHOST_SOURCE_SYNTAX_MISSING: worker/wrapper declaration block",
  );
}

const natListAtWorker = source.slice(natListAtWorkerStart, natListAtStart);
const natListAt = source.slice(natListAtStart, natListAtEnd);
const natListAtBlock = source.slice(natListAtWorkerStart, natListAtEnd);

const workerRequired = [
  /\(index\s*:\s*Nat\)\s*:\s*\n\s*List Nat\s*->\s*Option Nat\s*:=/,
  /match\s+index\s+with/,
  /let smaller\s*:\s*\n?\s*List Nat\s*->\s*Option Nat\s*:=\s*\n?\s*psElabNatListAtWorker nextIndex\s*;/,
  /fun \(values\s*:\s*List Nat\) =>/,
  /\| \[\] =>\s*Option\.none/,
  /\| value :: _ =>\s*Option\.some value/,
  /\| _ :: rest =>\s*smaller rest/,
];
for (const pattern of workerRequired) {
  if (!pattern.test(natListAtWorker)) {
    throw new Error(
      `PSC2_ELAB_NAT_LIST_AT_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

if (!/psElabNatListAtWorker\s+index\s+values/.test(natListAt)) {
  throw new Error(
    "PSC2_ELAB_NAT_LIST_AT_SELFHOST_SOURCE_SYNTAX_MISSING: thin wrapper delegates to worker",
  );
}
if (/psElabNatListAt\s+rest\s+nextIndex/.test(natListAtBlock)) {
  throw new Error(
    "PSC2_ELAB_NAT_LIST_AT_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: direct two-argument recursion remains",
  );
}
if (/=>\s*none\b/.test(natListAtBlock) || /=>\s*some\s+/.test(natListAtBlock)) {
  throw new Error(
    "PSC2_ELAB_NAT_LIST_AT_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: unqualified Option constructor remains",
  );
}

process.stdout.write(
  "PSC2_ELAB_NAT_LIST_AT_SELFHOST_SOURCE_SYNTAX: PASS (index-recursive worker; values applied post-recursion; explicit Option constructors)\n",
);
