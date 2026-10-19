// Keep changing elaboration context behind the function returned by constructorNames recursion; direct recursion may only vary the structural list.
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const workerMatch = source.match(
  /def psElabMatchMinorsWorker([\s\S]*?)(?=\ndef psElabMatchMinors\n)/,
);
if (workerMatch === null) {
  throw new Error(
    "PSC2_ELAB_MATCH_MINORS_SELFHOST_SOURCE_SYNTAX_MISSING: structurally recursive worker",
  );
}

const worker = workerMatch[0];
const requiredWorker = [
  /\(constructorNames : List PsName\)\s*:\s*\n\s*PsElabContext ->\s*\n\s*Except PsElabError PsElabMatchMinorsResult/,
  /let smaller\s*:\s*PsElabContext ->\s*\n\s*Except PsElabError PsElabMatchMinorsResult\s*:=\s*\n\s*psElabMatchMinorsWorker/,
  /match smaller minor\.context with/,
];
for (const pattern of requiredWorker) {
  if (!pattern.test(worker)) {
    throw new Error(
      `PSC2_ELAB_MATCH_MINORS_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const wrapperMatch = source.match(
  /def psElabMatchMinors\n([\s\S]*?)(?=\ndef psElabMatch\n)/,
);
if (wrapperMatch === null) {
  throw new Error(
    "PSC2_ELAB_MATCH_MINORS_SELFHOST_SOURCE_SYNTAX_MISSING: wrapper",
  );
}

const wrapper = wrapperMatch[0];
if (!/psElabMatchMinorsWorker[\s\S]*constructorNames[\s\S]*context/.test(wrapper)) {
  throw new Error(
    "PSC2_ELAB_MATCH_MINORS_SELFHOST_SOURCE_SYNTAX_MISSING: worker wrapper call",
  );
}
if (/match constructorNames with/.test(wrapper)) {
  throw new Error(
    "PSC2_ELAB_MATCH_MINORS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: direct recursion remains in wrapper",
  );
}

process.stdout.write(
  "PSC2_ELAB_MATCH_MINORS_SELFHOST_SOURCE_SYNTAX: PASS (constructorNames-recursive worker; post-recursion context)\n",
);
