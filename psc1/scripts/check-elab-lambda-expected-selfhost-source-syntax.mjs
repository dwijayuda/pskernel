import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const source = await readFile(
  path.join(root, "packages/elab/src/Ps/Elab/Term.lean"),
  "utf8",
);

const lambdaExpectedMatch = source.match(
  /def psElabLambdaExpectedBody([\s\S]*?)(?=\ndef psElabLambdaBodyExpected)/,
);
if (lambdaExpectedMatch === null) {
  throw new Error(
    "PSC2_ELAB_LAMBDA_EXPECTED_SELFHOST_SOURCE_SYNTAX_MISSING: psElabLambdaExpectedBody block",
  );
}
const lambdaExpected = lambdaExpectedMatch[0];

const required = [
  /\(binders : List PsElabTypedBinder\)\s*:\s*PsElabContext ->\s*PsExpr ->\s*Except PsElabError \(Prod PsElabContext PsExpr\) :=/,
  /match binders with/,
  /\| \[\] =>\s*fun \(context : PsElabContext\) =>\s*fun \(expectedType : PsExpr\) =>/,
  /let smaller\s*:\s*PsElabContext ->\s*PsExpr ->\s*Except PsElabError \(Prod PsElabContext PsExpr\) :=\s*psElabLambdaExpectedBody rest;/,
  /fun \(context : PsElabContext\) =>\s*fun \(expectedType : PsExpr\) =>/,
  /smaller\s+nextContext\s+nextExpected/,
];
for (const pattern of required) {
  if (!pattern.test(lambdaExpected)) {
    throw new Error(
      `PSC2_ELAB_LAMBDA_EXPECTED_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

const forbidden = [
  /PsExpr\s*->\s*Except PsElabError \(Prod PsElabContext PsExpr\)\s*\| expectedType =>/,
  /psElabLambdaExpectedBody\s+nextContext\s+rest\s+nextExpected/,
];
for (const pattern of forbidden) {
  if (pattern.test(lambdaExpected)) {
    throw new Error(
      `PSC2_ELAB_LAMBDA_EXPECTED_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ${pattern}`,
    );
  }
}

const wrapperMatch = source.match(
  /def psElabLambdaBodyExpected([\s\S]*?)(?=\ndef psElabLambda)/,
);
if (wrapperMatch === null) {
  throw new Error(
    "PSC2_ELAB_LAMBDA_EXPECTED_SELFHOST_SOURCE_SYNTAX_MISSING: psElabLambdaBodyExpected block",
  );
}
if (!/psElabLambdaExpectedBody\s+binders\s+context\s+expectedType/.test(wrapperMatch[0])) {
  throw new Error(
    "PSC2_ELAB_LAMBDA_EXPECTED_SELFHOST_SOURCE_SYNTAX_MISSING: worker call order",
  );
}

process.stdout.write(
  "PSC2_ELAB_LAMBDA_EXPECTED_SELFHOST_SOURCE_SYNTAX: PASS (explicit lambda argument and invariant-safe binder recursion)\n",
);
