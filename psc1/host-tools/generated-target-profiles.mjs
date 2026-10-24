// Closed trusted host target inventory. These are pure PSC1 source facades.
import assert from 'node:assert/strict';
const targets=Object.freeze({
 rust:Object.freeze({entry:'Ps.BackendRust.CompilerService',exportName:'psCompilerRustServiceCandidate',sourceFile:'module.rs',executable:'service.bin'}),
 ts:Object.freeze({entry:'Ps.BackendTs.CompilerService',exportName:'psCompilerTsServiceCandidate',sourceFile:'module.ts',executable:'module.js'}),
 js:Object.freeze({entry:'Ps.BackendJs.CompilerService',exportName:'psCompilerJsServiceCandidate',sourceFile:'module.js',executable:'module.js'}),
 python:Object.freeze({entry:'Ps.BackendPython.CompilerService',exportName:'psCompilerPythonServiceCandidate',sourceFile:'module.py',executable:'module.py'}),
 php:Object.freeze({entry:'Ps.BackendPhp.CompilerService',exportName:'psCompilerPhpServiceCandidate',sourceFile:'module.php',executable:'module.php'}),
 'wasm-core':Object.freeze({entry:'Ps.BackendWasm.CompilerService',exportName:'psCompilerWasmServiceCandidate',sourceFile:'module.wasm.hex',executable:'module.wasm'})
});
export function generatedTarget(target){assert.ok(Object.hasOwn(targets,target),'PSC1_GENERATED_TARGET_UNSUPPORTED');return targets[target];}
export const generatedTargets=Object.freeze(Object.keys(targets));
