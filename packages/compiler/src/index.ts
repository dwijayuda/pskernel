import type {CheckedCoreModule} from '@proofscript/checked-core';
import {eraseCheckedCoreModule} from '@proofscript/erasure';
import {validateVerifiedIrModule} from '@proofscript/compiler-ir/verified';
import {
  compileTypeScript,
  emitVerifiedTypeScript,
  type TypeScriptCompileResult,
} from '@proofscript/backend-ts/verified';
import {lowerVerifiedIrToWasm} from '@proofscript/wasm-lowering';
import {
  emitBinaryenWasm,
  instantiateProofScriptWasm,
  type ProofScriptWasmHostInstance,
  type ProofScriptWasmHostValue,
  type WasmEmitOptions,
  type WasmEmitResult,
} from '@proofscript/backend-wasm';

export {instantiateProofScriptWasm};
export type {
  ProofScriptWasmHostInstance,
  ProofScriptWasmHostValue,
  WasmEmitResult,
};

export interface VerifiedCompileResult {
  readonly checkedCore:CheckedCoreModule;
  readonly ir:ReturnType<typeof eraseCheckedCoreModule>;
  readonly typeScript:string;
  readonly emitted:TypeScriptCompileResult;
}

export function compileCheckedCore(
  checkedCore:CheckedCoreModule,
  fileName='module.ts',
):VerifiedCompileResult {
  const ir=eraseCheckedCoreModule(checkedCore);
  validateVerifiedIrModule(ir);
  const typeScript=emitVerifiedTypeScript(ir);
  const emitted=compileTypeScript(typeScript,fileName);
  return {checkedCore,ir,typeScript,emitted};
}

export interface VerifiedWasmCompileResult {
  readonly checkedCore:CheckedCoreModule;
  readonly ir:ReturnType<typeof eraseCheckedCoreModule>;
  readonly wasmIr:ReturnType<typeof lowerVerifiedIrToWasm>;
  readonly wasm:WasmEmitResult;
}

export function compileCheckedCoreToWasm(
  checkedCore:CheckedCoreModule,
  options:WasmEmitOptions={},
):VerifiedWasmCompileResult {
  const ir=eraseCheckedCoreModule(checkedCore);
  validateVerifiedIrModule(ir);
  const wasmIr=lowerVerifiedIrToWasm(ir);
  const wasm=emitBinaryenWasm(wasmIr,options);
  return {checkedCore,ir,wasmIr,wasm};
}
