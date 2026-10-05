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

  assert.equal(direct.natSubDemo(3n, 5n), reference.natSubDemo(3n, 5n));
  assert.equal(direct.natSubDemo(3n, 5n), 0n);
  assert.equal(direct.natSubDemo(9n, 4n), 5n);

  assert.equal(direct.natDivDemo(9n, 0n), reference.natDivDemo(9n, 0n));
  assert.equal(direct.natDivDemo(9n, 0n), 0n);
  assert.equal(direct.natDivDemo(9n, 4n), 2n);

  assert.equal(direct.natModDemo(9n, 0n), reference.natModDemo(9n, 0n));
  assert.equal(direct.natModDemo(9n, 0n), 9n);
  assert.equal(direct.natModDemo(9n, 4n), 1n);

  assert.equal(direct.intNegDemo(7n), reference.intNegDemo(7n));
  assert.equal(direct.intNegDemo(7n), -7n);

  assert.equal(direct.boolAndDemo(true, false), reference.boolAndDemo(true, false));
  assert.equal(direct.boolAndDemo(true, false), false);

  assert.equal(direct.stringLengthDemo("a😀"), reference.stringLengthDemo("a😀"));
  assert.equal(direct.stringLengthDemo("a😀"), 2n);

  assert.equal(
    direct.u8AddWrap(250, 10),
    reference.u8AddWrap(250, 10),
  );
  assert.equal(direct.u8AddWrap(250, 10), 4);

  assert.equal(
    direct.i8MulWrap(100, 2),
    reference.i8MulWrap(100, 2),
  );
  assert.equal(direct.i8MulWrap(100, 2), -56);

  assert.equal(
    direct.u64Xor(5n, 3n),
    reference.u64Xor(5n, 3n),
  );
  assert.equal(direct.u64Xor(5n, 3n), 6n);

  assert.equal(
    direct.u16Lt(10, 20),
    reference.u16Lt(10, 20),
  );
  assert.equal(direct.u16Lt(10, 20), true);

  assert.equal(
    direct.u8FromNat(300n),
    reference.u8FromNat(300n),
  );
  assert.equal(direct.u8FromNat(300n), 44);
  assert.equal(direct.u8Literal44, reference.u8Literal44);
  assert.equal(direct.u8Literal44, 44);

  assert.equal(
    direct.float32Mul(0.1, 0.2),
    reference.float32Mul(0.1, 0.2),
  );
  assert.equal(
    direct.float32Mul(0.1, 0.2),
    Math.fround(0.1 * 0.2),
  );

  assert.equal(
    direct.floatDiv(7.5, 2.5),
    reference.floatDiv(7.5, 2.5),
  );
  assert.equal(direct.floatDiv(7.5, 2.5), 3);

  assert.equal(direct.letNatDemo(4n), reference.letNatDemo(4n));
  assert.equal(direct.letNatDemo(4n), 10n);

  assert.equal(direct.applyLambda(4n), reference.applyLambda(4n));
  assert.equal(direct.applyLambda(4n), 6n);

  process.stdout.write(
    "PSC2_BACKEND_JS_DIFFERENTIAL: PASS\n",
  );
} finally {
  await rm(directory, { recursive: true, force: true });
}
