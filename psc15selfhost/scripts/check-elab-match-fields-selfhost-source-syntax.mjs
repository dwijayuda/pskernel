import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const oldBlock = `def psElabMatchFields
    (context : PsElabContext)
    (inductiveName : PsName)
    (cursor : PsExpr)
    (binderSyntaxes : List PsSyntaxName)
    (fieldsRev : List PsElabMatchField) :
    Except PsElabError PsElabMatchFieldsResult :=
  match binderSyntaxes with
  | [] =>
      Except.ok {
        context := context
        fieldsRev := fieldsRev
      }
  | binderSyntax :: rest =>
      match psInferEnsureForall
          context.environment
          context.metaContext
          context.localContext
          cursor with
      | Except.error error =>
          Except.error (PsElabError.infer error)
      | Except.ok forallView =>
          match psSyntaxNameToName binderSyntax with
          | none => Except.error PsElabError.emptyName
          | some binderName =>
              let pushed :=
                psLocalPushBinding
                  context.localContext
                  binderName
                  forallView.domain
                  forallView.binder;
              let nextContext :=
                psElabContextWithLocal context pushed.context;
              let field : PsElabMatchField := {
                id := pushed.id
                name := binderName
                type := forallView.domain
                binder := forallView.binder
              };
              psElabMatchFields
                nextContext
                inductiveName
                (psExprInstantiate1
                  forallView.body
                  (PsExpr.fvar pushed.id))
                rest
                (List.cons field fieldsRev)`;

const newBlock = `def psElabMatchFieldsWorker
    (inductiveName : PsName)
    (binderSyntaxes : List PsSyntaxName) :
    PsElabContext ->
    PsExpr ->
    List PsElabMatchField ->
    Except PsElabError PsElabMatchFieldsResult :=
  match binderSyntaxes with
  | [] =>
      fun (context : PsElabContext) =>
        fun (_cursor : PsExpr) =>
          fun (fieldsRev : List PsElabMatchField) =>
            Except.ok {
              context := context
              fieldsRev := fieldsRev
            }
  | binderSyntax :: rest =>
      let smaller :
          PsElabContext ->
          PsExpr ->
          List PsElabMatchField ->
          Except PsElabError PsElabMatchFieldsResult :=
        psElabMatchFieldsWorker
          inductiveName
          rest;
      fun (context : PsElabContext) =>
        fun (cursor : PsExpr) =>
          fun (fieldsRev : List PsElabMatchField) =>
            match psInferEnsureForall
                context.environment
                context.metaContext
                context.localContext
                cursor with
            | Except.error error =>
                Except.error (PsElabError.infer error)
            | Except.ok forallView =>
                match psSyntaxNameToName binderSyntax with
                | none => Except.error PsElabError.emptyName
                | some binderName =>
                    let pushed :=
                      psLocalPushBinding
                        context.localContext
                        binderName
                        forallView.domain
                        forallView.binder;
                    let nextContext :=
                      psElabContextWithLocal context pushed.context;
                    let field : PsElabMatchField := {
                      id := pushed.id
                      name := binderName
                      type := forallView.domain
                      binder := forallView.binder
                    };
                    smaller
                      nextContext
                      (psExprInstantiate1
                        forallView.body
                        (PsExpr.fvar pushed.id))
                      (List.cons field fieldsRev)

def psElabMatchFields
    (context : PsElabContext)
    (inductiveName : PsName)
    (cursor : PsExpr)
    (binderSyntaxes : List PsSyntaxName)
    (fieldsRev : List PsElabMatchField) :
    Except PsElabError PsElabMatchFieldsResult :=
  psElabMatchFieldsWorker
    inductiveName
    binderSyntaxes
    context
    cursor
    fieldsRev`;

const blockMatch = source.match(
  /def psElabMatchFieldsWorker([\s\S]*?)(?=\ndef psElabMatchFieldAt)/,
);
if (blockMatch === null) {
  if (!source.includes(oldBlock)) {
    throw new Error("PSC2_ELAB_MATCH_FIELDS_PATCH_SOURCE_MISMATCH");
  }
  const patched = source.replace(oldBlock, newBlock);
  const encoded = Buffer.from(patched, "utf8").toString("base64");
  const chunkSize = 24000;
  let index = 0;
  for (let offset = 0; offset < encoded.length; offset += chunkSize) {
    const label = String(index).padStart(3, "0");
    const chunk = encoded.slice(offset, offset + chunkSize);
    process.stdout.write(`::error title=PSC2_TERM_CHUNK_${label}::${chunk}\n`);
    index += 1;
  }
  process.stdout.write(`::error title=PSC2_TERM_CHUNK_COUNT::${index}\n`);
  throw new Error(
    "PSC2_ELAB_MATCH_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: invariant-safe match-fields worker block",
  );
}

const block = blockMatch[0];
const required = [
  /def psElabMatchFieldsWorker\s*\(inductiveName : PsName\)\s*\(binderSyntaxes : List PsSyntaxName\)\s*:\s*PsElabContext ->\s*PsExpr ->\s*List PsElabMatchField ->\s*Except PsElabError PsElabMatchFieldsResult :=\s*match binderSyntaxes with/,
  /let smaller[\s\S]*?psElabMatchFieldsWorker\s+inductiveName\s+rest/,
  /smaller\s+nextContext\s*\(psExprInstantiate1[\s\S]*?forallView\.body[\s\S]*?\(PsExpr\.fvar pushed\.id\)\)\s*\(List\.cons field fieldsRev\)/,
  /def psElabMatchFields\s*\(context : PsElabContext\)\s*\(inductiveName : PsName\)\s*\(cursor : PsExpr\)\s*\(binderSyntaxes : List PsSyntaxName\)\s*\(fieldsRev : List PsElabMatchField\)[\s\S]*?psElabMatchFieldsWorker\s+inductiveName\s+binderSyntaxes\s+context\s+cursor\s+fieldsRev/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_FIELDS_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /psElabMatchFields\s+nextContext/,
];
for (const pattern of forbidden) {
  if (pattern.test(block)) {
    throw new Error(
      `PSC2_ELAB_MATCH_FIELDS_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

process.stdout.write(
  "PSC2_ELAB_MATCH_FIELDS_SELFHOST_SOURCE_SYNTAX: PASS (binder-list-recursive worker with post-recursion context/cursor/field accumulator)\n",
);
