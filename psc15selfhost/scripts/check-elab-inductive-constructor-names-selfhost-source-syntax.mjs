import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);
const start = source.indexOf("def psElabInductiveConstructorNames\n");
const end = source.indexOf("\ndef psElabContextWithEnvironment\n", start + 1);
if (start < 0 || end < 0) {
  throw new Error("PSC2_ELAB_CONSTRUCTOR_NAMES_MISSING: declaration block");
}

const block = source.slice(start, end);
// PSC1 needs the expected result type before elaborating a local match.
if (!/let currentName\s*:\s*PsName\s*:=\s*match\s+psSyntaxConstructorCoreName\s+inductiveName\s+source\.name\s+with/.test(block)) {
  throw new Error("PSC2_ELAB_CONSTRUCTOR_NAMES_MISSING: typed constructor-name match");
}
if (/let currentName\s*:=/.test(block)) {
  throw new Error("PSC2_ELAB_CONSTRUCTOR_NAMES_FORBIDDEN: untyped constructor-name match");
}

process.stdout.write(
  "PSC2_ELAB_CONSTRUCTOR_NAMES: PASS (explicit PsName result type for constructor-name selection)\n",
);
