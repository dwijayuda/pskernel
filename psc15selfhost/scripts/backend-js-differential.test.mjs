import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { pathToFileURL, fileURLToPath } from "node:url";

import {
  pinnedTypeScriptVersionText,
  resolveTypeScriptCli,
} from "./typescript-cli.mjs";

const root = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
);

function emit(target) {
  const result = spawnSync(
    "lake",
    ["exe", "psc1_backend_js_diff_fixture", target],
    {
      cwd: root,
      encoding: "utf8",
      maxBuffer: 16 * 1024 * 1024,
      windowsHide: true,
    },
  );
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(
      [
        "PSC2_BACKEND_JS_DIFF_FIXTURE_FAILED",
        result.stdout,
        result.stderr,
      ].filter(Boolean).join("\n"),
    );
  }
  return result.stdout;
}

const tsc = resolveTypeScriptCli();
const version = spawnSync(
  process.execPath,
  [tsc, "--version"],
  { cwd: root, encoding: "utf8", timeout: 10000 },
);
assert.equal(version.error, undefined);
assert.equal(version.status, 0);
assert.equal(version.stdout.trim(), pinnedTypeScriptVersionText);

const directory = await mkdtemp(
  path.join(tmpdir(), "psc2-backend-js-diff-"),
);

try {
  await writeFile(
    path.join(directory, "package.json"),
    '{"type":"module"}\n',
  );
  const directPath = path.join(directory, "direct.js");
  const typeScriptPath = path.join(directory, "reference.ts");
  await writeFile(directPath, emit("js"));
  await writeFile(typeScriptPath, emit("ts"));

  const compile = spawnSync(
    process.execPath,
    [
      tsc,
      typeScriptPath,
      "--ignoreConfig",
      "--target", "ES2022",
      "--module", "ES2022",
      "--moduleResolution", "bundler",
      "--strict",
      "--skipLibCheck",
      "--pretty", "false",
    ],
    {
      cwd: directory,
      encoding: "utf8",
      maxBuffer: 16 * 1024 * 1024,
      windowsHide: true,
    },
  );
  if (compile.error) throw compile.error;
  assert.equal(
    compile.status,
    0,
    [compile.stdout, compile.stderr].filter(Boolean).join("\n"),
  );

  const direct = await import(
    pathToFileURL(directPath).href + "?direct"
  );
  const reference = await import(
    pathToFileURL(path.join(directory, "reference.js")).href +
      "?reference"
  );

  assert.equal(direct.answer, reference.answer);
  assert.equal(direct.answer, 42n);
  assert.equal(direct.idNat(9n), reference.idNat(9n));
  assert.equal(direct.idNat(9n), 9n);
  assert.equal(direct.plusOne(41n), reference.plusOne(41n));
  assert.equal(direct.plusOne(41n), 42n);
  assert.equal(
    direct.choose(true, 7n, 11n),
    reference.choose(true, 7n, 11n),
  );
  assert.equal(direct.choose(true, 7n, 11n), 7n);
  assert.equal(
    direct.choose(false, 7n, 11n),
    reference.choose(false, 7n, 11n),
  );
  assert.equal(direct.choose(false, 7n, 11n), 11n);
  assert.equal(
    direct.callPlusOne(10n),
    reference.callPlusOne(10n),
  );
  assert.equal(direct.callPlusOne(10n), 11n);
  assert.equal(direct.greeting, reference.greeting);
  assert.equal(direct.greeting, "hello");
  assert.equal(direct.truth, reference.truth);
  assert.equal(direct.truth, true);
  assert.equal(direct.unitValue, reference.unitValue);
  assert.equal(direct.unitValue, undefined);

  process.stdout.write(
    "PSC2_BACKEND_JS_DIFFERENTIAL: PASS\n",
  );
} finally {
  await rm(directory, { recursive: true, force: true });
}
