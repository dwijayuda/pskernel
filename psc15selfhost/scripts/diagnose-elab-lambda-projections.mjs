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
  throw new Error("PSC2_LAMBDA_PROJECTION_DIAGNOSTIC: psElabLambda marker missing");
}

const probes = `
def psElabTypedBindersResultContextProjectionProbe
    (result : PsElabTypedBindersResult) : PsElabContext :=
  result.context

def psElabTypedBindersResultBindersProjectionProbe
    (result : PsElabTypedBindersResult) : List PsElabTypedBinder :=
  result.bindersRev
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
      `PSC2_LAMBDA_PROJECTION_DIAGNOSTIC_UNEXPECTED: exit=${run.status}`,
    );
  }

  const declaration = failure[1].trim();
  const error = failure[2].trim();
  process.stdout.write(
    `PSC2_LAMBDA_PROJECTION_DIAGNOSTIC: firstFailure=${declaration}; error=${error}\n`,
  );

  const allowed = new Set([
    "psElabTypedBindersResultContextProjectionProbe",
    "psElabTypedBindersResultBindersProjectionProbe",
    "psElabLambda",
  ]);
  if (!allowed.has(declaration)) {
    process.stdout.write(output);
    throw new Error(
      `PSC2_LAMBDA_PROJECTION_DIAGNOSTIC_UNEXPECTED_DECLARATION: ${declaration}`,
    );
  }
} finally {
  await writeFile(termPath, original, "utf8");
}
