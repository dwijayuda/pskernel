import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const start = source.indexOf("def psElabDropForallBinders\n");
const end = source.indexOf("\ndef psElabTakeForallNames\n", start + 1);
if (start < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_DROP_FORALL_OPTION_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = source.slice(start, end);
if (!/Option\.some\s+type/.test(block)) {
  throw new Error(
    "PSC2_ELAB_DROP_FORALL_OPTION_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some type value",
  );
}
if (!/Option\.none/.test(block)) {
  throw new Error(
    "PSC2_ELAB_DROP_FORALL_OPTION_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.none value",
  );
}
if (/\n\s*some\s+type\b/.test(block) || /=>\s*none\b/.test(block)) {
  throw new Error(
    "PSC2_ELAB_DROP_FORALL_OPTION_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: unqualified Option value remains",
  );
}

process.stdout.write(
  "PSC2_ELAB_DROP_FORALL_OPTION_SELFHOST_SOURCE_SYNTAX: PASS (explicit Option.some/Option.none return values)\n",
);
