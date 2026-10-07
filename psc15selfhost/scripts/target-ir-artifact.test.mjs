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

test('target schemas preserve exact Nat and Int domains without numeric coercion', () => {
  const jsValue = literal => Buffer.from(JSON.stringify([jsIrEncodingContract, [], [['f', [], ['literal', literal]]]]));
  const wasmInstruction = instruction => Buffer.from(JSON.stringify([wasmIrEncodingContract, [], [], [],
    [['f', ['none'], [], [], [], [instruction]]], [], []]));
  const invalid = ["","+1","01","-0","1.0","1e3"," 1","1\n","1\r\n","NaN"];
  for (const value of invalid) {
    for (const literal of [['natural', value], ['integer', value], ['machineInteger', 'int64', value]])
      assert.throws(() => decodeJsIrArtifact(jsValue(literal)), /NATURAL|DECIMAL/);
    for (const instruction of [['i32Const', value], ['i64Const', value], ['localGet', value],
      ['localSet', value], ['structGet', 'S', value], ['structGetS', 'S', value],
      ['structGetU', 'S', value], ['arrayNewFixed', 'A', value]])
      assert.throws(() => decodeWasmIrArtifact(wasmInstruction(instruction)), /NATURAL|DECIMAL/);
  }
  assert.throws(() => decodeJsIrArtifact(jsValue(['natural', '-1'])), /NATURAL/);
  for (const instruction of [['localGet', '-1'], ['localSet', '-1'], ['structGet', 'S', '-1'],
    ['structGetS', 'S', '-1'], ['structGetU', 'S', '-1'], ['arrayNewFixed', 'A', '-1']])
    assert.throws(() => decodeWasmIrArtifact(wasmInstruction(instruction)), /NATURAL/);
  const large = '9'.repeat(200);
  for (const value of ['0', '1', large]) {
    assert.equal(decodeJsIrArtifact(jsValue(['natural', value]))[2][0][2][1][1], value);
    assert.equal(decodeWasmIrArtifact(wasmInstruction(['localGet', value]))[4][0][5][0][1], value);
  }
  for (const value of ['0', '-1', large, '-' + large]) {
    assert.equal(decodeJsIrArtifact(jsValue(['integer', value]))[2][0][2][1][1], value);
    assert.equal(decodeWasmIrArtifact(wasmInstruction(['i64Const', value]))[4][0][5][0][1], value);
  }
  // Schema decoding is deliberately separate from target typing: large natural
  // indices and integer literals may decode and still fail the typing gate.
});
