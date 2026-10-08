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
  const supportTypeScriptPath = path.join(directory, "support.ts");
  await writeFile(
    supportTypeScriptPath,
    [
      "export function importedAdd(left: bigint, right: bigint): bigint { return left + right; }",
      "export function namedIdentity(value: bigint): bigint { return value; }",
      "export default function defaultIdentity(value: bigint): bigint { return value + 1n; }",
      "",
    ].join("\n"),
  );
  await writeFile(directPath, emit("js"));
  await writeFile(typeScriptPath, emit("ts"));
  const propertyTypeScriptPath = path.join(directory, "properties.ts");
  await writeFile(propertyTypeScriptPath, emit("properties-ts"));
  await writeFile(path.join(directory, "properties-direct.js"), emit("properties-js"));
  await writeFile(path.join(directory, "properties-stack.js"), emit("properties-js-stack"));

  const compile = spawnSync(
    process.execPath,
    [
      tsc,
      typeScriptPath,
      propertyTypeScriptPath,
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

  // Assert independent property semantics, rather than only backend agreement.
  // ECMAScript non-computed "__proto__" keys set the prototype or ignore scalars.
  for (const filename of ["properties.js", "properties-direct.js", "properties-stack.js"]) {
    const backend = await import(pathToFileURL(path.join(directory, filename)).href);
    const own = (object, key, expected) => {
      assert.equal(Object.getPrototypeOf(object), Object.prototype, filename);
      const descriptor = Object.getOwnPropertyDescriptor(object, key);
      assert.ok(descriptor, `${filename}: missing own field ${key}`);
      assert.equal(descriptor.value, expected);
      assert.equal(descriptor.enumerable, true);
      assert.equal(descriptor.get, undefined);
    };
    const record = backend.primitiveRecord(42n);
    for (const key of ["__proto__", "constructor", "prototype", "toString"])
      own(record, key, 42n);
    assert.equal(backend.readRecord(42n), 42n);
    const objectRecord = backend.objectRecord(17n);
    assert.ok(Object.hasOwn(objectRecord, "__proto__"));
    own(objectRecord, "__proto__", objectRecord.__proto__);
    own(objectRecord.__proto__, "__proto__", 17n);
    const payload = backend.payload(23n);
    const fields = Object.hasOwn(payload, "$ps$fields") ? payload.$ps$fields : payload;
    own(fields, "__proto__", 23n);
    assert.equal(backend.readPayload(23n), 23n);
    for (const value of [backend.emptyPayload, backend.emptyProto]) {
      assert.equal(Object.getPrototypeOf(value), Object.prototype);
      assert.ok(Reflect.ownKeys(value).length > 0, "constructor value must carry its own tag");
    }
    if (Object.hasOwn(backend, "PropertySum")) {
      assert.equal(Object.getPrototypeOf(backend.PropertySum), Object.prototype);
      assert.equal(Object.hasOwn(backend.PropertySum, "__proto__"), true);
      assert.equal(Object.hasOwn(backend.PropertyEmpty, "__proto__"), true);
    }
    const order = [];
    const ordered = backend.orderedRecord(value => { order.push(value); return value * 10n; });
    assert.deepEqual(order, [1n, 2n, 3n, 4n]);
    for (const [key, value] of [["__proto__", 10n], ["constructor", 20n],
      ["prototype", 30n], ["toString", 40n]]) own(ordered, key, value);
  }

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

  const unicodeText = "Aé😀";
  assert.equal(
    direct.stringUtf8ByteSizeDemo(unicodeText),
    reference.stringUtf8ByteSizeDemo(unicodeText),
  );
  assert.equal(direct.stringUtf8ByteSizeDemo(unicodeText), 7n);

  assert.equal(
    direct.stringNextDemo(unicodeText, 1n),
    reference.stringNextDemo(unicodeText, 1n),
  );
  assert.equal(direct.stringNextDemo(unicodeText, 1n), 3n);
  assert.equal(
    direct.stringNextDemo(unicodeText, 2n),
    reference.stringNextDemo(unicodeText, 2n),
  );
  assert.equal(direct.stringNextDemo(unicodeText, 2n), 3n);

  assert.equal(
    direct.stringGetDemo(unicodeText, 3n),
    reference.stringGetDemo(unicodeText, 3n),
  );
  assert.equal(direct.stringGetDemo(unicodeText, 3n), "😀");
  assert.equal(
    direct.stringGetDemo(unicodeText, 2n),
    reference.stringGetDemo(unicodeText, 2n),
  );
  assert.equal(direct.stringGetDemo(unicodeText, 2n), "A");

  assert.equal(
    direct.stringAtEndDemo(unicodeText, 7n),
    reference.stringAtEndDemo(unicodeText, 7n),
  );
  assert.equal(direct.stringAtEndDemo(unicodeText, 7n), true);
  assert.equal(direct.stringAtEndDemo(unicodeText, 6n), false);
  for (const text of ["", "ASCII", "é😀A", "another", "é😀A"]) {
    const size = reference.stringUtf8ByteSizeDemo(text);
    for (let offset = 0n; offset <= size + 2n; offset++) {
      assert.equal(direct.stringGetDemo(text, offset), reference.stringGetDemo(text, offset));
      assert.equal(direct.stringNextDemo(text, offset), reference.stringNextDemo(text, offset));
      assert.equal(direct.stringAtEndDemo(text, offset), reference.stringAtEndDemo(text, offset));
    }
    assert.equal(direct.stringUtf8ByteSizeDemo(text), size);
  }
  const longText = "Aé😀".repeat(10000);
  assert.equal(direct.stringUtf8ByteSizeDemo(longText), 70000n);
  for (let offset = 0n; offset < 70000n; offset += 7n) {
    assert.equal(direct.stringGetDemo(longText, offset + 3n), "😀");
    assert.equal(direct.stringNextDemo(longText, offset + 3n), offset + 7n);
  }

  assert.equal(
    direct.stringExtractDemo(unicodeText, 1n, 7n),
    reference.stringExtractDemo(unicodeText, 1n, 7n),
  );
  assert.equal(direct.stringExtractDemo(unicodeText, 1n, 7n), "é😀");
  assert.equal(
    direct.stringExtractDemo(unicodeText, 2n, 7n),
    reference.stringExtractDemo(unicodeText, 2n, 7n),
  );
  assert.equal(direct.stringExtractDemo(unicodeText, 2n, 7n), "");

  const arraySource = [20n, 22n];

  assert.deepEqual(
    direct.arrayEmptyDemo(100n),
    reference.arrayEmptyDemo(100n),
  );
  assert.deepEqual(direct.arrayEmptyDemo(100n), []);

  assert.equal(
    direct.arraySizeDemo(arraySource),
    reference.arraySizeDemo(arraySource),
  );
  assert.equal(direct.arraySizeDemo(arraySource), 2n);

  const directPushed = direct.arrayPushDemo(arraySource, 30n);
  const referencePushed = reference.arrayPushDemo(arraySource, 30n);
  assert.deepEqual(directPushed, referencePushed);
  assert.deepEqual(directPushed, [20n, 22n, 30n]);
  assert.deepEqual(arraySource, [20n, 22n]);

  assert.equal(
    direct.arrayGetDemo(arraySource, 1n),
    reference.arrayGetDemo(arraySource, 1n),
  );
  assert.equal(direct.arrayGetDemo(arraySource, 1n), 22n);

  assert.equal(
    direct.arrayGetDDemo(arraySource, 1n, 99n),
    reference.arrayGetDDemo(arraySource, 1n, 99n),
  );
  assert.equal(direct.arrayGetDDemo(arraySource, 1n, 99n), 22n);
  assert.equal(
    direct.arrayGetDDemo(arraySource, 7n, 99n),
    reference.arrayGetDDemo(arraySource, 7n, 99n),
  );
  assert.equal(direct.arrayGetDDemo(arraySource, 7n, 99n), 99n);

  const directSetSource = [20n, 22n];
  const referenceSetSource = [20n, 22n];
  const directSet = direct.arraySetDemo(directSetSource, 1n, 42n);
  const referenceSet = reference.arraySetDemo(referenceSetSource, 1n, 42n);
  assert.deepEqual(directSet, referenceSet);
  assert.deepEqual(directSet, [20n, 42n]);
  assert.deepEqual(directSetSource, [20n, 22n]);
  assert.deepEqual(referenceSetSource, [20n, 22n]);

  const directSetIfSource = [20n, 22n];
  const referenceSetIfSource = [20n, 22n];
  const directSetIf = direct.arraySetIfInBoundsDemo(
    directSetIfSource,
    1n,
    42n,
  );
  const referenceSetIf = reference.arraySetIfInBoundsDemo(
    referenceSetIfSource,
    1n,
    42n,
  );
  assert.deepEqual(directSetIf, referenceSetIf);
  assert.deepEqual(directSetIf, [20n, 42n]);
  assert.deepEqual(directSetIfSource, [20n, 22n]);
  assert.deepEqual(referenceSetIfSource, [20n, 22n]);

  const directOobSource = [20n, 22n];
  const referenceOobSource = [20n, 22n];
  assert.equal(
    direct.arraySetIfInBoundsDemo(directOobSource, 7n, 99n),
    directOobSource,
  );
  assert.equal(
    reference.arraySetIfInBoundsDemo(referenceOobSource, 7n, 99n),
    referenceOobSource,
  );

  assert.deepEqual(
    direct.arrayMapDemo((value) => value + 1n, arraySource),
    reference.arrayMapDemo((value) => value + 1n, arraySource),
  );
  assert.deepEqual(
    direct.arrayMapDemo((value) => value + 1n, arraySource),
    [21n, 23n],
  );

  const foldFunction = (acc, value) => acc + value;
  assert.equal(
    direct.arrayFoldDemo(
      foldFunction,
      1n,
      [20n, 22n, 30n],
      1n,
      3n,
    ),
    reference.arrayFoldDemo(
      foldFunction,
      1n,
      [20n, 22n, 30n],
      1n,
      3n,
    ),
  );
  assert.equal(
    direct.arrayFoldDemo(
      foldFunction,
      1n,
      [20n, 22n, 30n],
      1n,
      3n,
    ),
    53n,
  );

  assert.equal(
    direct.externalAddDemo(20n, 22n),
    reference.externalAddDemo(20n, 22n),
  );
  assert.equal(direct.externalAddDemo(20n, 22n), 42n);

  assert.equal(
    direct.externalNamedDemo(42n),
    reference.externalNamedDemo(42n),
  );
  assert.equal(direct.externalNamedDemo(42n), 42n);

  assert.equal(
    direct.externalDefaultDemo(41n),
    reference.externalDefaultDemo(41n),
  );
  assert.equal(direct.externalDefaultDemo(41n), 42n);

  assert.equal(
    direct.genericIdNat(42n),
    reference.genericIdNat(42n),
  );
  assert.equal(direct.genericIdNat(42n), 42n);

  assert.equal(
    direct.pointSum(20n, 22n),
    reference.pointSum(20n, 22n),
  );
  assert.equal(direct.pointSum(20n, 22n), 42n);

  assert.equal(
    direct.boxNatGet(42n),
    reference.boxNatGet(42n),
  );
  assert.equal(direct.boxNatGet(42n), 42n);

  assert.equal(
    direct.maybeSomeOrZero(42n),
    reference.maybeSomeOrZero(42n),
  );
  assert.equal(direct.maybeSomeOrZero(42n), 42n);

  assert.equal(
    direct.maybeNoneOr(7n),
    reference.maybeNoneOr(7n),
  );
  assert.equal(direct.maybeNoneOr(7n), 7n);

  assert.equal(
    direct.optionNatSome(42n),
    reference.optionNatSome(42n),
  );
  assert.equal(direct.optionNatSome(42n), 42n);

  assert.equal(
    direct.matchTempCollision(20n, 22n),
    reference.matchTempCollision(20n, 22n),
  );
  assert.equal(direct.matchTempCollision(20n, 22n), 42n);

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
