import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);

const match = source.match(
  /def psElabDeclarationsWorker[\s\S]*?(?=\ndef psElabModule)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_DECLARATIONS_SELFHOST_SOURCE_SYNTAX_MISSING: worker block",
  );
}

const block = match[0];
const required = [
  /def psElabDeclarationsWorker\s*\(sources : List PsSyntaxDeclaration\)\s*:\s*PsEnvironment ->\s*List PsDeclaration ->\s*Except PsElabError PsElabModuleResult :=\s*match sources with/,
  /\| List\.nil =>\s*fun \(environment : PsEnvironment\) =>\s*fun \(declarationsRev : List PsDeclaration\) =>/,
  /PsElabModuleResult\.mk\s+environment\s+\(psElabReverseDeclarations declarationsRev\)/,
  /\| List\.cons source rest =>/,
  /psElabDeclarationsWorker rest;/,
  /smaller\s+nextEnvironment\s+\(psPrependBatchReverse\s+result\.declarations\s+declarationsRev\)/,
  /def psElabDeclarations\s*\(environment : PsEnvironment\)\s*\(sources : List PsSyntaxDeclaration\)\s*\(declarationsRev : List PsDeclaration\)[\s\S]*?psElabDeclarationsWorker\s+sources\s+environment\s+declarationsRev/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_DECLARATIONS_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /\| \[\], declarationsRev =>/,
  /\| source :: rest, declarationsRev =>/,
  /declarationsRev\.reverse\b/,
  /Except\.ok\s*\{/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_DECLARATIONS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_DECLARATIONS_SELFHOST_SOURCE_SYNTAX: PASS (source-list-recursive worker; environment/accumulator applied post-recursion; explicit module result; local declaration reverse)\n",
);

await import("./check-erasure-add-unique-string-selfhost-source-syntax.mjs");
