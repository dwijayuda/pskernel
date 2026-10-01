import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const workerStart = source.indexOf("def psElabSolvePendingInstancesWorker\n");
const wrapperStart = source.indexOf("def psElabSolvePendingInstances\n");
const end = source.indexOf("\ndef psElabFinishApplication\n", wrapperStart);
if (workerStart < 0 || wrapperStart < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_SOLVE_PENDING_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: worker/wrapper block",
  );
}

const worker = source.slice(workerStart, wrapperStart);
const wrapper = source.slice(wrapperStart, end);

if (!/\(pendingInstances\s*:\s*List\s+Nat\)\s*:\s*PsElabTermResult\s*->\s*Except\s+PsElabError\s+PsElabTermResult\s*:=\s*match\s+pendingInstances\s+with/ms.test(worker)) {
  throw new Error(
    "PSC2_ELAB_SOLVE_PENDING_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: pending-list recursive worker signature",
  );
}
if (!/let\s+smaller\s*:\s*PsElabTermResult\s*->\s*Except\s+PsElabError\s+PsElabTermResult\s*:=\s*psElabSolvePendingInstancesWorker\s+rest\s*;/ms.test(worker)) {
  throw new Error(
    "PSC2_ELAB_SOLVE_PENDING_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: post-recursion current closure",
  );
}
if (!/smaller\s+current/m.test(worker) || !/smaller\s+assignedResult/m.test(worker)) {
  throw new Error(
    "PSC2_ELAB_SOLVE_PENDING_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: current state applied after recursion",
  );
}
if (/psElabSolvePendingInstances\s+(?:current|assignedResult)\s+rest/m.test(worker)) {
  throw new Error(
    "PSC2_ELAB_SOLVE_PENDING_RECURSION_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: direct recursive wrapper call remains",
  );
}
if (!/psElabSolvePendingInstancesWorker\s+pendingInstances\s+current/m.test(wrapper)) {
  throw new Error(
    "PSC2_ELAB_SOLVE_PENDING_RECURSION_SELFHOST_SOURCE_SYNTAX_MISSING: thin public wrapper",
  );
}

process.stdout.write(
  "PSC2_ELAB_SOLVE_PENDING_RECURSION_SELFHOST_SOURCE_SYNTAX: PASS (pending-list-recursive worker; current applied post-recursion)\n",
);
