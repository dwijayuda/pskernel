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
const end = source.indexOf("\ndef psElabNatListAt\n", start + 1);
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

const natListAtStart = source.indexOf("def psElabNatListAt\n");
const natListAtEnd = source.indexOf("\ndef psElabValidateStructuralCall\n", natListAtStart + 1);
if (natListAtStart < 0 || natListAtEnd < 0) {
  throw new Error(
    "PSC2_ELAB_NAT_LIST_AT_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const natListAt = source.slice(natListAtStart, natListAtEnd);
const natListAtRequired = [
  /\| \[\] =>\s*Option\.none/,
  /\| 0 =>\s*Option\.some value/,
  /\| nextIndex \+ 1 =>\s*psElabNatListAt rest nextIndex/,
];
for (const pattern of natListAtRequired) {
  if (!pattern.test(natListAt)) {
    throw new Error(
      `PSC2_ELAB_NAT_LIST_AT_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const natListAtForbidden = [
  /=>\s*none\b/,
  /=>\s*some\s+/,
];
for (const pattern of natListAtForbidden) {
  if (pattern.test(natListAt)) {
    throw new Error(
      `PSC2_ELAB_NAT_LIST_AT_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_NAT_LIST_AT_SELFHOST_SOURCE_SYNTAX: PASS (structural Nat-list lookup; explicit Option constructors)\n",
);
