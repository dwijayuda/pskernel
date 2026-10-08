import "./check-elab-close-implicit-binders-selfhost-source-syntax.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);

const helperStart = source.indexOf("def psElabBinderArgumentsInOrder\n");
const wrapperStart = source.indexOf("\ndef psElabBinderArguments\n", helperStart + 1);
const end = source.indexOf("\ndef psCloseElabImplicitBinders\n", wrapperStart + 1);
if (helperStart < 0 || wrapperStart < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_BINDER_ARGUMENTS_SELFHOST_SOURCE_SYNTAX_MISSING: helper/wrapper declaration block",
  );
}

const helper = source.slice(helperStart, wrapperStart);
const wrapper = source.slice(wrapperStart, end);
const required = [
  /\(binders\s*:\s*List PsElabTypedBinder\)\s*:\s*List PsExpr\s*:=/,
  /match\s+binders\s+with/,
  /\| List\.nil => List\.nil/,
  /\| List\.cons binder rest =>\s*List\.cons\s*\n\s*\(psElabBinderArgument binder\)\s*\n\s*\(psElabBinderArgumentsInOrder rest\)/,
];
for (const pattern of required) {
  if (!pattern.test(helper)) {
    throw new Error(
      `PSC2_ELAB_BINDER_ARGUMENTS_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

if (!/psElabBinderArgumentsInOrder\s*\n\s*\(psElabTypedBinderListReverse bindersRev\)/.test(wrapper)) {
  throw new Error(
    "PSC2_ELAB_BINDER_ARGUMENTS_SELFHOST_SOURCE_SYNTAX_MISSING: shared typed-binder reverse followed by local mapping",
  );
}

const block = source.slice(helperStart, end);
const forbidden = [
  /\.reverse/,
  /\.map\b/,
  /List\.reverse/,
  /List\.map/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_BINDER_ARGUMENTS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_BINDER_ARGUMENTS_SELFHOST_SOURCE_SYNTAX: PASS (shared typed-binder reverse; local structural binder-to-expression mapping; generic reverse/map excluded)\n",
);