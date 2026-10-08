import "./check-elab-partial-declaration-selfhost-source-syntax.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);

const match = source.match(
  /def psElabStructureDeclaration[\s\S]*?(?=\ndef psElabPartialDeclaration)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_STRUCTURE_DECLARATION_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = match[0];
const required = [
  /match fields with\s*\| List\.nil =>\s*Except\.error PsElabError\.unsupportedTerm\s*\| List\.cons _ _ =>/,
  /let constructorName : PsSyntaxName :=\s*PsSyntaxName\.mk\s*\(List\.cons "mk" List\.nil\)\s*span;/,
  /let constructor : PsSyntaxInductiveConstructor :=\s*PsSyntaxInductiveConstructor\.mk\s*constructorName\s*fields\s*span;/,
  /psElabInductiveDeclaration\s+environment\s+name\s+params\s+Option\.none\s+\(List\.cons constructor List\.nil\)\s+true/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_STRUCTURE_DECLARATION_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /fields\.isEmpty\b/,
  /let constructorName\s*:\s*PsSyntaxName\s*:=\s*\{/,
  /let constructor\s*:\s*PsSyntaxInductiveConstructor\s*:=\s*\{/,
  /\["mk"\]/,
  /\[constructor\]/,
  /\n\s+none\s*\n/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_STRUCTURE_DECLARATION_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_STRUCTURE_DECLARATION_SELFHOST_SOURCE_SYNTAX: PASS (structural field match; explicit syntax constructors; explicit Option/List values)\n",
);
