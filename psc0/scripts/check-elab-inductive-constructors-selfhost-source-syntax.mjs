import "./check-elab-inductive-declaration-selfhost-source-syntax.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);
const start = source.indexOf("def psElabReverseDeclarationsAcc\n");
const workerStart = source.indexOf("\ndef psElabInductiveConstructorsWorker\n", start + 1);
const wrapperStart = source.indexOf("\ndef psElabInductiveConstructors\n", workerStart + 1);
const end = source.indexOf("\ndef psEnvironmentAddOwnedBootstrapDeclaration\n", wrapperStart + 1);
if (start < 0 || workerStart < 0 || wrapperStart < 0 || end < 0) {
  throw new Error("PSC2_ELAB_INDUCTIVE_CONSTRUCTORS_MISSING: reverse helper and structural worker/wrapper");
}

const reverse = source.slice(start, workerStart);
const worker = source.slice(workerStart, wrapperStart);
const wrapper = source.slice(wrapperStart, end);
const required = [
  [reverse, /\(declarations : List PsDeclaration\)\s*:\s*List PsDeclaration -> List PsDeclaration :=\s*match declarations with/],
  [reverse, /\| List\.nil =>\s*fun \(acc : List PsDeclaration\) => acc/],
  [reverse, /psElabReverseDeclarationsAcc rest;\s*fun \(acc : List PsDeclaration\) =>\s*smaller \(List\.cons declaration acc\)/],
  [reverse, /psElabReverseDeclarationsAcc declarations List\.nil/],
  [worker, /\(sources : List PsSyntaxInductiveConstructor\)\s*:\s*Nat ->\s*List PsDeclaration ->\s*Except PsElabError \(List PsDeclaration\) :=\s*match sources with/],
  [worker, /\| List\.nil =>\s*fun \(_index : Nat\) =>\s*fun \(declarationsRev : List PsDeclaration\) =>\s*Except\.ok \(psElabReverseDeclarations declarationsRev\)/],
  [worker, /psElabInductiveConstructorsWorker\s+context\s+parameterBindersRev\s+inductiveName\s+rest;/],
  [worker, /psElabInductiveConstructor\s+context\s+parameterBindersRev\s+inductiveName\s+source with\s*\| Except\.error error => Except\.error error/],
  [worker, /smaller\s*\(Nat\.succ index\)\s*\(List\.cons\s*\(psSetConstructorIndex index declaration\)\s+declarationsRev\)/],
  [wrapper, /psElabInductiveConstructorsWorker\s+context\s+parameterBindersRev\s+inductiveName\s+sources\s+index\s+declarationsRev/],
];
for (const [block, pattern] of required) {
  if (!pattern.test(block)) {
    throw new Error(`PSC2_ELAB_INDUCTIVE_CONSTRUCTORS_MISSING: ${pattern}`);
  }
}
if (/\.reverse\b|\|\s*index\s*,|\|\s*_\s*,/.test(worker + wrapper)) {
  throw new Error("PSC2_ELAB_INDUCTIVE_CONSTRUCTORS_FORBIDDEN: generic reverse or multi-argument equations");
}

process.stdout.write(
  "PSC2_ELAB_INDUCTIVE_CONSTRUCTORS: PASS (source-list recursion; index and accumulator applied afterward; ordered declaration reversal)\n",
);
