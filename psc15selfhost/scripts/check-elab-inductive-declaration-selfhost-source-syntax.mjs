import "./check-elab-structure-declaration-selfhost-source-syntax.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);

const match = source.match(
  /def psElabInductiveDeclaration[\s\S]*?(?=\ndef psElabStructureDeclaration)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_INDUCTIVE_DECLARATION_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = match[0];
const required = [
  /match psSyntaxNameToName nameSyntax with\s*\| Option\.none => Except\.error PsElabError\.emptyName\s*\| Option\.some name =>/,
  /match resultType with\s*\| Option\.none =>[\s\S]*?\| Option\.some sourceType =>/,
  /psElabTerm\s+parameters\.context\s+sourceType\s+Option\.none/,
  /let resultTypeIsSortOne\s*:\s*Bool\s*:=\s*match instantiatedResultType with/,
  /numParams := psElabListLength parameterArgs/,
  /match withInductiveResult with\s*\| Option\.none =>[\s\S]*?\| Option\.some withInductive =>/,
  /Except\.ok\s*\(PsElabDeclarationBatchResult\.mk\s*\(psElabAppendDeclarations/,
];

for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_INDUCTIVE_DECLARATION_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /\| none =>/,
  /\| some\s+/,
  /\n\s+none\s+with/,
  /let resultTypeIsSortOne\s*:=/,
  /parameterArgs\.length\b/,
  /Except\.ok\s*\{/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_INDUCTIVE_DECLARATION_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_INDUCTIVE_DECLARATION_SELFHOST_SOURCE_SYNTAX: PASS (explicit Option constructors, typed local matches, project-owned list counts, and explicit batch-result construction)\n",
);
