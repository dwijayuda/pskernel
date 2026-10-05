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

assert.equal(exportedFunction("arrayMapTopLevelGet")(), 23);
assert.equal(exportedFunction("arrayMapLambdaGet")(), 22);
assert.equal(exportedFunction("arrayMapEmptySizeExact")(), 1);
assert.equal(exportedFunction("arrayFoldRange")(), 53);
assert.equal(exportedFunction("arrayFoldStopBeyond")(), 42);
assert.equal(exportedFunction("arrayFoldStartBeyond")(), 7);

console.log("PSC1_BACKEND_WASM_RUNTIME: PASS");
