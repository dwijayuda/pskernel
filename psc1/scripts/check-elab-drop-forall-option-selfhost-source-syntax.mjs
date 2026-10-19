import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const workerStart = source.indexOf("def psElabDropForallBindersWorker\n");
const wrapperStart = source.indexOf("\ndef psElabDropForallBinders\n", workerStart + 1);
const end = source.indexOf("\ndef psElabTakeForallNames\n", wrapperStart + 1);
if (workerStart < 0 || wrapperStart < 0 || end < 0) {
  throw new Error(
    "PSC2_ELAB_DROP_FORALL_OPTION_SELFHOST_SOURCE_SYNTAX_MISSING: worker/wrapper declaration block",
  );
}

const worker = source.slice(workerStart, wrapperStart);
const wrapper = source.slice(wrapperStart, end);
const block = source.slice(workerStart, end);

if (!/\(remaining\s*:\s*Nat\)\s*:\s*\n\s*PsExpr\s*->\s*Option PsExpr\s*:=/.test(worker)) {
  throw new Error(
    "PSC2_ELAB_DROP_FORALL_OPTION_SELFHOST_SOURCE_SYNTAX_MISSING: remaining-recursive worker returns PsExpr closure",
  );
}
if (!/psElabDropForallBindersWorker\s+nextRemaining\s*;/.test(worker)) {
  throw new Error(
    "PSC2_ELAB_DROP_FORALL_OPTION_SELFHOST_SOURCE_SYNTAX_MISSING: worker recurses only on nextRemaining",
  );
}
if (!/smaller\s+body/.test(worker)) {
  throw new Error(
    "PSC2_ELAB_DROP_FORALL_OPTION_SELFHOST_SOURCE_SYNTAX_MISSING: changed body applied after structural recursion",
  );
}
if (!/psElabDropForallBindersWorker\s+remaining\s+type/.test(wrapper)) {
  throw new Error(
    "PSC2_ELAB_DROP_FORALL_OPTION_SELFHOST_SOURCE_SYNTAX_MISSING: thin wrapper delegates to worker",
  );
}
if (/psElabDropForallBinders\s+nextRemaining\s+body/.test(block)) {
  throw new Error(
    "PSC2_ELAB_DROP_FORALL_OPTION_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: changing type argument crosses recursive call",
  );
}
if (!/Option\.some\s+type/.test(worker)) {
  throw new Error(
    "PSC2_ELAB_DROP_FORALL_OPTION_SELFHOST_SOURCE_SYNTAX_MISSING: explicit Option.some type value",
  );
}
if (!/Option\.none/.test(worker)) {
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
  "PSC2_ELAB_DROP_FORALL_OPTION_SELFHOST_SOURCE_SYNTAX: PASS (remaining-recursive worker; post-recursion PsExpr; explicit Option.some/Option.none values)\n",
);
