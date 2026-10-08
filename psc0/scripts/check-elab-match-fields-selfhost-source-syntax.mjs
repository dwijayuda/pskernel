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
  const chunkSize = 3000;
  let index = 0;
  for (let offset = 0; offset < encoded.length; offset += chunkSize) {
    const label = String(index).padStart(3, "0");
    const chunk = encoded.slice(offset, offset + chunkSize);
    process.stdout.write(`PSC2_TERM_CHUNK_${label}=${chunk}\n`);
    index += 1;
  }
  process.stdout.write(`PSC2_TERM_CHUNK_COUNT=${index}\n`);
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

const matchFieldAtMatch = source.match(
  /def psElabMatchFieldAtWorker([\s\S]*?)(?=\nstructure PsElabMatchHypothesesResult)/,
);
if (matchFieldAtMatch === null) {
  throw new Error(
    "PSC2_ELAB_MATCH_FIELD_AT_SELFHOST_SOURCE_SYNTAX_MISSING: invariant-safe index-recursive worker",
  );
}
const matchFieldAt = matchFieldAtMatch[0];
for (const pattern of [
  /def psElabMatchFieldAtWorker\s*\(index : Nat\)\s*:\s*List PsElabMatchField -> Option PsElabMatchField :=\s*match index with/,
  /let smaller[\s\S]*?psElabMatchFieldAtWorker\s+nextIndex/,
  /\| \[\] =>\s*Option\.none/,
  /Option\.some field/,
  /smaller\s+rest/,
  /def psElabMatchFieldAt\s*\(fields : List PsElabMatchField\)\s*\(index : Nat\)\s*:\s*Option PsElabMatchField :=\s*psElabMatchFieldAtWorker\s+index\s+fields/,
]) {
  if (!pattern.test(matchFieldAt)) {
    throw new Error(
      `PSC2_ELAB_MATCH_FIELD_AT_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}
if (/psElabMatchFieldAt\s+rest\s+nextIndex/.test(matchFieldAt)) {
  throw new Error(
    "PSC2_ELAB_MATCH_FIELD_AT_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: direct recursion changes structural and invariant arguments",
  );
}

const recursiveHypothesesMatch = source.match(
  /def psElabPushRecursiveHypotheses([\s\S]*?)(?=\ndef psCloseElabMatchFields)/,
);
if (recursiveHypothesesMatch === null) {
  throw new Error(
    "PSC2_ELAB_PUSH_RECURSIVE_HYPOTHESES_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}
const recursiveHypotheses = recursiveHypothesesMatch[0];
if (!/let withRecursion\s*:\s*PsElabContext\s*:=\s*match context\.structuralRecursion with/.test(recursiveHypotheses)) {
  const oldLocalMatch = `          let withRecursion :=\n            match context.structuralRecursion with`;
  const newLocalMatch = `          let withRecursion : PsElabContext :=\n            match context.structuralRecursion with`;
  if (!source.includes(oldLocalMatch)) {
    throw new Error(
      "PSC2_ELAB_PUSH_RECURSIVE_HYPOTHESES_PATCH_SOURCE_MISMATCH",
    );
  }
  const patched = source.replace(oldLocalMatch, newLocalMatch);
  const encoded = Buffer.from(patched, "utf8").toString("base64");
  const chunkSize = 3000;
  let index = 0;
  for (let offset = 0; offset < encoded.length; offset += chunkSize) {
    const label = String(index).padStart(3, "0");
    const chunk = encoded.slice(offset, offset + chunkSize);
    process.stdout.write(`PSC2_TERM_CONTEXT_CHUNK_${label}=${chunk}\n`);
    index += 1;
  }
  process.stdout.write(`PSC2_TERM_CONTEXT_CHUNK_COUNT=${index}\n`);
  throw new Error(
    "PSC2_ELAB_PUSH_RECURSIVE_HYPOTHESES_SELFHOST_SOURCE_SYNTAX_MISSING: explicit PsElabContext expected type for local structural-recursion match",
  );
}

const recursiveHypothesesWorkerMatch = source.match(
  /def psElabPushRecursiveHypothesesWorker([\s\S]*?)(?=\ndef psCloseElabMatchFields)/,
);
if (recursiveHypothesesWorkerMatch === null) {
  const oldRecursiveHypotheses = `def psElabPushRecursiveHypotheses
    (expectedType : PsExpr)
    (fields : List PsElabMatchField)
    (fieldIndices : List Nat)
    (context : PsElabContext)
    (hypothesesRev : List PsElabMatchField) :
    Except PsElabError PsElabMatchHypothesesResult :=
  match fieldIndices with
  | [] =>
      Except.ok {
        context := context
        hypothesesRev := hypothesesRev
      }
  | fieldIndex :: rest =>
      match psElabMatchFieldAt fields fieldIndex with
      | none => Except.error PsElabError.structuralRecursionInternal
      | some field =>
          let hypothesisName :=
            psNameAppendNum
              (psRootName "_ih")
              fieldIndex;
          let pushed :=
            psLocalPushBinding
              context.localContext
              hypothesisName
              expectedType
              PsBinderInfo.explicit;
          let withLocal :=
            psElabContextWithLocal
              context
              pushed.context;
          let withRecursion : PsElabContext :=
            match context.structuralRecursion with
            | none =>
                withLocal
            | some recursion =>
                let nextRecursion : PsElabStructuralRecursion := {
                  functionName := recursion.functionName
                  explicitParameterIds := recursion.explicitParameterIds
                  recursiveParameterIndex := recursion.recursiveParameterIndex
                  calls :=
                    List.cons
                      (Prod.mk field.id pushed.id)
                      recursion.calls
                };
                psElabContextWithStructuralRecursion
                  withLocal
                  (Option.some nextRecursion);
          let hypothesis : PsElabMatchField := {
            id := pushed.id
            name := hypothesisName
            type := expectedType
            binder := PsBinderInfo.explicit
          };
          psElabPushRecursiveHypotheses
            expectedType
            fields
            rest
            withRecursion
            (List.cons hypothesis hypothesesRev)`;
  const newRecursiveHypotheses = `def psElabPushRecursiveHypothesesWorker
    (expectedType : PsExpr)
    (fields : List PsElabMatchField)
    (fieldIndices : List Nat) :
    PsElabContext ->
    List PsElabMatchField ->
    Except PsElabError PsElabMatchHypothesesResult :=
  match fieldIndices with
  | [] =>
      fun (context : PsElabContext) =>
        fun (hypothesesRev : List PsElabMatchField) =>
          Except.ok {
            context := context
            hypothesesRev := hypothesesRev
          }
  | fieldIndex :: rest =>
      let smaller :
          PsElabContext ->
          List PsElabMatchField ->
          Except PsElabError PsElabMatchHypothesesResult :=
        psElabPushRecursiveHypothesesWorker
          expectedType
          fields
          rest;
      fun (context : PsElabContext) =>
        fun (hypothesesRev : List PsElabMatchField) =>
          match psElabMatchFieldAt fields fieldIndex with
          | none => Except.error PsElabError.structuralRecursionInternal
          | some field =>
              let hypothesisName :=
                psNameAppendNum
                  (psRootName "_ih")
                  fieldIndex;
              let pushed :=
                psLocalPushBinding
                  context.localContext
                  hypothesisName
                  expectedType
                  PsBinderInfo.explicit;
              let withLocal :=
                psElabContextWithLocal
                  context
                  pushed.context;
              let withRecursion : PsElabContext :=
                match context.structuralRecursion with
                | none =>
                    withLocal
                | some recursion =>
                    let nextRecursion : PsElabStructuralRecursion := {
                      functionName := recursion.functionName
                      explicitParameterIds := recursion.explicitParameterIds
                      recursiveParameterIndex := recursion.recursiveParameterIndex
                      calls :=
                        List.cons
                          (Prod.mk field.id pushed.id)
                          recursion.calls
                    };
                    psElabContextWithStructuralRecursion
                      withLocal
                      (Option.some nextRecursion);
              let hypothesis : PsElabMatchField := {
                id := pushed.id
                name := hypothesisName
                type := expectedType
                binder := PsBinderInfo.explicit
              };
              smaller
                withRecursion
                (List.cons hypothesis hypothesesRev)

def psElabPushRecursiveHypotheses
    (expectedType : PsExpr)
    (fields : List PsElabMatchField)
    (fieldIndices : List Nat)
    (context : PsElabContext)
    (hypothesesRev : List PsElabMatchField) :
    Except PsElabError PsElabMatchHypothesesResult :=
  psElabPushRecursiveHypothesesWorker
    expectedType
    fields
    fieldIndices
    context
    hypothesesRev`;
  if (!source.includes(oldRecursiveHypotheses)) {
    throw new Error(
      "PSC2_ELAB_PUSH_RECURSIVE_HYPOTHESES_WORKER_PATCH_SOURCE_MISMATCH",
    );
  }
  const patched = source.replace(oldRecursiveHypotheses, newRecursiveHypotheses);
  const encoded = Buffer.from(patched, "utf8").toString("base64");
  const chunkSize = 3000;
  let index = 0;
  for (let offset = 0; offset < encoded.length; offset += chunkSize) {
    const label = String(index).padStart(3, "0");
    const chunk = encoded.slice(offset, offset + chunkSize);
    process.stdout.write(
      `PSC2_TERM_RECURSIVE_HYPOTHESES_CHUNK_${label}=${chunk}\n`,
    );
    index += 1;
  }
  process.stdout.write(
    `PSC2_TERM_RECURSIVE_HYPOTHESES_CHUNK_COUNT=${index}\n`,
  );
  throw new Error(
    "PSC2_ELAB_PUSH_RECURSIVE_HYPOTHESES_SELFHOST_SOURCE_SYNTAX_MISSING: field-index-recursive worker with post-recursion context and hypothesis accumulator",
  );
}
const recursiveHypothesesWorker = recursiveHypothesesWorkerMatch[0];
for (const pattern of [
  /def psElabPushRecursiveHypothesesWorker\s*\(expectedType : PsExpr\)\s*\(fields : List PsElabMatchField\)\s*\(fieldIndices : List Nat\)\s*:\s*PsElabContext ->\s*List PsElabMatchField ->\s*Except PsElabError PsElabMatchHypothesesResult :=\s*match fieldIndices with/,
  /let smaller[\s\S]*?psElabPushRecursiveHypothesesWorker\s+expectedType\s+fields\s+rest/,
  /fun \(context : PsElabContext\) =>\s*fun \(hypothesesRev : List PsElabMatchField\) =>/,
  /let withRecursion\s*:\s*PsElabContext\s*:=\s*match context\.structuralRecursion with/,
  /smaller\s+withRecursion\s*\(List\.cons hypothesis hypothesesRev\)/,
  /def psElabPushRecursiveHypotheses\s*\(expectedType : PsExpr\)\s*\(fields : List PsElabMatchField\)\s*\(fieldIndices : List Nat\)\s*\(context : PsElabContext\)\s*\(hypothesesRev : List PsElabMatchField\)[\s\S]*?psElabPushRecursiveHypothesesWorker\s+expectedType\s+fields\s+fieldIndices\s+context\s+hypothesesRev/,
]) {
  if (!pattern.test(recursiveHypothesesWorker)) {
    throw new Error(
      `PSC2_ELAB_PUSH_RECURSIVE_HYPOTHESES_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}
if (/psElabPushRecursiveHypotheses\s+expectedType\s+fields\s+rest/.test(recursiveHypothesesWorker)) {
  throw new Error(
    "PSC2_ELAB_PUSH_RECURSIVE_HYPOTHESES_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: direct recursion changes invariant context and hypothesis accumulator",
  );
}

process.stdout.write(
  "PSC2_ELAB_MATCH_FIELDS_SELFHOST_SOURCE_SYNTAX: PASS (binder-list-recursive worker with post-recursion context/cursor/field accumulator; invariant-safe index-recursive match-field lookup with explicit Option constructors; typed local structural-recursion match; field-index-recursive hypothesis worker with post-recursion context/accumulator)\n",
);
