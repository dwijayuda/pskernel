import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);

const match = source.match(
  /def psElabDeclarationsWithOriginsWorker[\s\S]*?(?=\ndef psElabModuleWithOrigins\n)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_DECLARATIONS_SELFHOST_SOURCE_SYNTAX_MISSING: worker block",
  );
}

const block = match[0];
const required = [
  /def psElabDeclarationsWithOriginsWorker\s*\(sources : List PsSyntaxDeclaration\)\s*\(environment : PsEnvironment\)\s*\(declarationsRev : List PsDeclaration\)\s*\(originsRev : List PsElabBatchOrigin\)\s*\(sourceIndex : Nat\) :\s*Except PsElabOriginError PsElabModuleWithOriginsResult :=\s*match sources with/,
  /\| List\.nil =>\s*Except\.ok\s*\(PsElabModuleWithOriginsResult\.mk\s*\(PsElabModuleResult\.mk/,
  /PsElabModuleResult\.mk\s+environment\s+\(psElabReverseDeclarations declarationsRev\)\)\s*\(psListReverse originsRev\)/,
  /\| List\.cons source rest =>/,
  /match psElabDeclarationBatchWithOrigins environment sourceIndex source with\s*\| Except\.error error => Except\.error error\s*\| Except\.ok batch =>\s*match\s+psAddDeclarationList\s+environment\s+batch\.result\.declarations with\s*\| Except\.error error =>\s*Except\.error\s*\(PsElabOriginError\.mk error batch\.origin\.sourceIndex\s+batch\.origin\.sourceName batch\.origin\.span\s+PsElabOriginPhase\.declarationInsertion\)/,
  /\| Except\.ok nextEnvironment =>\s*psElabDeclarationsWithOriginsWorker\s+rest\s+nextEnvironment\s+\(psPrependBatchReverse\s+batch\.result\.declarations\s+declarationsRev\)\s*\(List\.cons batch\.origin originsRev\)\s*\(Nat\.succ sourceIndex\)/,
  /def psElabDeclarationsWorker\s*\(sources : List PsSyntaxDeclaration\)\s*\(environment : PsEnvironment\)\s*\(declarationsRev : List PsDeclaration\) :\s*Except PsElabError PsElabModuleResult :=\s*match psElabDeclarationsWithOriginsWorker\s+sources environment declarationsRev List\.nil 0 with\s*\| Except\.error failure => Except\.error failure\.error\s*\| Except\.ok result => Except\.ok result\.result/,
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
  "PSC2_ELAB_DECLARATIONS_SELFHOST_SOURCE_SYNTAX: PASS (source-list-recursive origin worker; ordinary environment/accumulator parameters; explicit module result; local declaration reverse; unchanged raw API projections)\n",
);

await import("./check-erasure-add-unique-string-selfhost-source-syntax.mjs");
