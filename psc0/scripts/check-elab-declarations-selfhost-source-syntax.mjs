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
  /def psElabDeclarationsWorker\s*\(sources : List PsSyntaxDeclaration\)\s*\(environment : PsEnvironment\)\s*\(declarationsRev : List PsDeclaration\) :\s*Except PsElabError PsElabModuleResult :=\s*match sources with/,
  /\| List\.nil =>\s*Except\.ok\s*\(PsElabModuleResult\.mk/,
  /PsElabModuleResult\.mk\s+environment\s+\(psElabReverseDeclarations declarationsRev\)/,
  /\| List\.cons source rest =>/,
  /match psElabDeclarationBatch environment source with\s*\| Except\.error error => Except\.error error\s*\| Except\.ok result =>\s*match\s+psAddDeclarationList\s+environment\s+result\.declarations with\s*\| Except\.error error => Except\.error error/,
  /\| Except\.ok nextEnvironment =>\s*psElabDeclarationsWorker\s+rest\s+nextEnvironment\s+\(psPrependBatchReverse\s+result\.declarations\s+declarationsRev\)/,
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
  "PSC2_ELAB_DECLARATIONS_SELFHOST_SOURCE_SYNTAX: PASS (source-list-recursive worker; ordinary environment/accumulator parameters; explicit module result; local declaration reverse)\n",
);

await import("./check-erasure-add-unique-string-selfhost-source-syntax.mjs");
