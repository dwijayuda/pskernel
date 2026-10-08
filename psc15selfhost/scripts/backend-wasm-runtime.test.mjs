import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const filePath = process.argv[2];
assert.ok(filePath, "expected encoded Wasm byte file path");

const csv = readFileSync(filePath, "utf8").trim();
assert.ok(csv.length > 0, "encoded Wasm byte stream is empty");

const bytes = Uint8Array.from(
  csv.split(",").map((part) => {
    const value = Number(part.trim());
    assert.ok(Number.isInteger(value), `invalid byte: ${part}`);
    assert.ok(value >= 0 && value <= 255, `byte out of range: ${part}`);
    return value;
  }),
);

const { instance } = await WebAssembly.instantiate(bytes, {});
const exports = instance.exports;

function exportedFunction(name) {
  const value = exports[name];
  assert.equal(typeof value, "function", `missing function export: ${name}`);
  return value;
}

assert.equal(exportedFunction("intReprZeroExact")(), 1);
assert.equal(exportedFunction("intReprPositiveExact")(), 1);
assert.equal(exportedFunction("intReprNegativeExact")(), 1);
assert.equal(exportedFunction("intReprLargeExact")(), 1);

assert.equal(exportedFunction("stringLiteralLengthExact")(), 1);
assert.equal(exportedFunction("stringUtf8ByteSizeExact")(), 1);
assert.equal(exportedFunction("stringNextUnicodeExact")(), 1);
assert.equal(exportedFunction("stringNextMisalignedExact")(), 1);
assert.equal(exportedFunction("stringGetUnicode")(), 128512);
assert.equal(exportedFunction("stringGetMisaligned")(), 65);
assert.equal(exportedFunction("stringAtEndExact")(), 1);
assert.equal(exportedFunction("stringAppendExact")(), 1);
assert.equal(exportedFunction("stringPushExact")(), 1);
assert.equal(exportedFunction("stringSingletonExact")(), 1);
assert.equal(exportedFunction("stringExtractExact")(), 1);
assert.equal(exportedFunction("stringExtractMisalignedEmpty")(), 1);
assert.equal(exportedFunction("stringEqMismatch")(), 0);

assert.equal(exportedFunction("arrayMapTopLevelGet")(), 23);
assert.equal(exportedFunction("arrayMapLambdaGet")(), 22);
assert.equal(exportedFunction("arrayMapEmptySizeExact")(), 1);
assert.equal(exportedFunction("arrayFoldRange")(), 53);
assert.equal(exportedFunction("arrayFoldStopBeyond")(), 42);
assert.equal(exportedFunction("arrayFoldStartBeyond")(), 7);

assert.equal(exportedFunction("applySelectedFunction")(1, 2, 40), 42);
assert.equal(exportedFunction("applySelectedFunction")(0, 2, 40), 38);
assert.equal(exportedFunction("applyComputedFunction")(2, 40), 42);
assert.equal(exportedFunction("applyGlobalFunctionValue")(41), 42);

assert.equal(exportedFunction("tailCountdown")(200000, 0), 200000);
assert.equal(exportedFunction("longUtf8ByteSizeExact")(), 1);
assert.equal(exportedFunction("largeLiteralContentExact")(), 1);


for (const name of ['unitValue', 'unitLocal', 'unitRecord', 'unitFold'])
  assert.equal(exportedFunction(name)(), undefined, name + ' keeps zero-result ABI');
assert.equal(exportedFunction('unitIdentity')(0), undefined);
for (const choice of [0, 1]) {
  assert.equal(exportedFunction('unitIf')(choice, 0), undefined);
  assert.equal(exportedFunction('unitArgument')(choice), undefined);
  assert.equal(exportedFunction('unitMatch')(choice), undefined);
  assert.equal(exportedFunction('unitLambda')(choice), undefined);
}
assert.equal(exportedFunction('unitMapSize')(), 1);
assert.equal(exportedFunction('unitMapToU32')(), 42);
assert.equal(exportedFunction('unitEmptyMapSize')(), 1);
assert.throws(() => exportedFunction('unitTrappingMap')(), WebAssembly.RuntimeError);
assert.equal(exportedFunction('unitTailCountdown')(200000), undefined);
console.log("PSC1_BACKEND_WASM_RUNTIME: PASS");

