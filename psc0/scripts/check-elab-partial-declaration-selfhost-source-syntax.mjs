import "./check-elab-declaration-batch-selfhost-source-syntax.mjs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Declaration.lean"),
  "utf8",
);

const match = source.match(
  /def psElabPartialDeclaration[\s\S]*?(?=\ndef psElabDeclaration\n)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ELAB_PARTIAL_DECLARATION_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = match[0];
const required = [
  /match psSyntaxNameToName nameSyntax with\s*\| Option\.none => Except\.error PsElabError\.emptyName\s*\| Option\.some name =>/,
  /psElabTerm\s+binderResult\.context\s+typeSyntax\s+Option\.none/,
  /PsDeclaration\.axiomDecl\s+name\s+List\.nil\s+closedType/,
  /match psEnvironmentAdd environment selfHeader with\s*\| Option\.none =>[\s\S]*?\| Option\.some withSelf =>/,
  /psElabTerm\s+valueContext\s+valueSyntax\s+\(Option\.some openType\)/,
  /Except\.ok\s*\(PsElabDeclarationResult\.mk\s*\(PsDeclaration\.partialDecl\s+name\s+List\.nil\s+\(Prod\.snd closed\)\s+\(Prod\.fst closed\)\)\s+metaContext\)/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_PARTIAL_DECLARATION_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /\| none =>/,
  /\| some\s+/,
  /\n\s+none\s+with/,
  /\(some\s+/,
  /PsDeclaration\.axiomDecl\s+name\s+\[\]/,
  /PsDeclaration\.partialDecl\s+name\s+\[\]/,
  /Except\.ok\s*\{/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_PARTIAL_DECLARATION_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_PARTIAL_DECLARATION_SELFHOST_SOURCE_SYNTAX: PASS (explicit Option/List values and explicit declaration result construction)\n",
);
