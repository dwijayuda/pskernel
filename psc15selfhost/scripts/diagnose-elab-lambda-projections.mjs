import { readFile, writeFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const termPath = path.join(root, "packages/elab/src/Ps/Elab/Term.lean");
const original = await readFile(termPath, "utf8");
const marker = "\ndef psElabLambda\n";

if (!original.includes(marker)) {
  throw new Error("PSC2_LAMBDA_DIAGNOSTIC: psElabLambda marker missing");
}

const probes = `
def psElabTypedBindersResultContextProjectionProbe
    (result : PsElabTypedBindersResult) : PsElabContext :=
  result.context

def psElabTypedBindersResultBindersProjectionProbe
    (result : PsElabTypedBindersResult) : List PsElabTypedBinder :=
  result.bindersRev

def psElabTermResultMetaContextProjectionProbe
    (result : PsElabTermResult) : PsMetaContext :=
  result.context.metaContext

def psElabTermResultTermProjectionProbe
    (result : PsElabTermResult) : PsExpr :=
  result.term

def psElabTermResultTypeProjectionProbe
    (result : PsElabTermResult) : PsExpr :=
  result.type

def psElabLambdaPrepareProbe
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (expected : Option PsExpr) :
    Except PsElabError (Prod PsElabContext (Option PsExpr)) :=
  match psElabTypedBinders elaborate context binders with
  | Except.error error => Except.error error
  | Except.ok binderResult =>
      psElabLambdaBodyExpected
        binderResult.context
        (List.reverse binderResult.bindersRev)
        expected

def psElabLambdaBodyProbe
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (body : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psElabTypedBinders elaborate context binders with
  | Except.error error => Except.error error
  | Except.ok binderResult =>
      match
          psElabLambdaBodyExpected
            binderResult.context
            (List.reverse binderResult.bindersRev)
            expected with
      | Except.error error => Except.error error
      | Except.ok prepared =>
          elaborate (Prod.fst prepared) body (Prod.snd prepared)

def psElabLambdaCloseProbe
    (metaContext : PsMetaContext)
    (binderResult : PsElabTypedBindersResult)
    (bodyResult : PsElabTermResult) : Prod PsExpr PsExpr :=
  psCloseElabTypedBinders
    metaContext
    binderResult.bindersRev
    (psMetaInstantiate metaContext bodyResult.term)
    (psMetaInstantiate metaContext bodyResult.type)

def psElabLambdaFinalizeProbe
    (context : PsElabContext)
    (metaContext : PsMetaContext)
    (closed : Prod PsExpr PsExpr)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult :=
  let outerContext :=
    psElabContextWithMeta context metaContext;
  let finalResult :=
    PsElabTermResult.mk
      outerContext
      (Prod.fst closed)
      (Prod.snd closed);
  psElabFinalizeExpected finalResult expected
`;

const instrumented = original.replace(marker, `${probes}${marker}`);
await writeFile(termPath, instrumented, "utf8");

try {
  const run = spawnSync(
    "lake",
    ["exe", "psc1", "check", "packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean"],
    {
      cwd: root,
      encoding: "utf8",
      env: process.env,
      maxBuffer: 32 * 1024 * 1024,
    },
  );

  const output = `${run.stdout ?? ""}\n${run.stderr ?? ""}`;
  const failure = output.match(/declaration=([^:\n]+):\s*([^\n]+)/);

  if (failure === null) {
    process.stdout.write(output);
    throw new Error(
      `PSC2_LAMBDA_DIAGNOSTIC_UNEXPECTED: exit=${run.status}`,
    );
  }

  const declaration = failure[1].trim();
  const error = failure[2].trim();
  process.stdout.write(
    `PSC2_LAMBDA_DIAGNOSTIC: firstFailure=${declaration}; error=${error}\n`,
  );

  const allowed = new Set([
    "psElabTypedBindersResultContextProjectionProbe",
    "psElabTypedBindersResultBindersProjectionProbe",
    "psElabTermResultMetaContextProjectionProbe",
    "psElabTermResultTermProjectionProbe",
    "psElabTermResultTypeProjectionProbe",
    "psElabLambdaPrepareProbe",
    "psElabLambdaBodyProbe",
    "psElabLambdaCloseProbe",
    "psElabLambdaFinalizeProbe",
    "psElabLambda",
  ]);
  if (!allowed.has(declaration)) {
    process.stdout.write(output);
    throw new Error(
      `PSC2_LAMBDA_DIAGNOSTIC_UNEXPECTED_DECLARATION: ${declaration}`,
    );
  }
} finally {
  await writeFile(termPath, original, "utf8");
}
