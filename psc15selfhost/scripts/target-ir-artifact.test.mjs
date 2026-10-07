import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  checkedTargetIrStageArtifacts,
  decodeJsIrArtifact,
  decodeWasmIrArtifact,
  jsIrEncodingContract,
  wasmIrEncodingContract,
} from './target-ir-artifact.mjs';

const js = '["psc-js-ir-json/1",[],[["answer",[],["literal",["natural","42"]]]]]';
const wasm = '["psc-wasm-ir-json/1",[],[],[],[["answer",["none"],[],[["i32"]],[],[["i32Const","42"]]]],[],[["answer","answer"]]]';

test('canonical target stages decode and receive distinct target identities', () => {
  assert.equal(decodeJsIrArtifact(Buffer.from(js))[0], jsIrEncodingContract);
  assert.equal(decodeWasmIrArtifact(Buffer.from(wasm))[0], wasmIrEncodingContract);
  const artifacts = checkedTargetIrStageArtifacts({ jsIr: js, wasmIr: wasm });
  assert.equal(artifacts.jsIr.identity.domain, 'js-ir');
  assert.equal(artifacts.jsIr.identity.contract, jsIrEncodingContract);
  assert.equal(artifacts.wasmIr.identity.domain, 'wasm-ir');
  assert.equal(artifacts.wasmIr.identity.contract, wasmIrEncodingContract);
  assert.notEqual(artifacts.jsIr.identity.digest, artifacts.wasmIr.identity.digest);
});

test('target decoder rejects malformed tags, instructions, and byte budgets', () => {
  assert.throws(() => decodeJsIrArtifact(Buffer.from('["psc-js-ir-json/1",[],[["answer",[],["bogus"]]]]')), /JS_EXPR/);
  assert.throws(() => decodeWasmIrArtifact(Buffer.from('["psc-wasm-ir-json/1",[],[],[],[["answer",["none"],[],[["i32"]],[],[["bogus"]]]],[],[]]')), /WASM_INSTRUCTION/);
  assert.throws(() => checkedTargetIrStageArtifacts({ jsIr: js }, { maxBytes: 1 }), /BYTES_LIMIT/);
});
