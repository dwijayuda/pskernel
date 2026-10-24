// Closed trusted host target inventory. These are pure PSC1 source facades.
import assert from 'node:assert/strict';
const targets=Object.freeze({
 rust:Object.freeze({entry:'Ps.BackendRust.CompilerService',exportName:'psCompilerRustServiceCandidate',sourceFile:'module.rs',executable:'service.bin'}),
 ts:Object.freeze({entry:'Ps.BackendTs.CompilerService',exportName:'psCompilerTsServiceCandidate',sourceFile:'module.ts',executable:'module.js'}),
 js:Object.freeze({entry:'Ps.BackendJs.CompilerService',exportName:'psCompilerJsServiceCandidate',sourceFile:'module.js',executable:'module.js'}),
 python:Object.freeze({entry:'Ps.BackendPython.CompilerService',exportName:'psCompilerPythonServiceCandidate',sourceFile:'module.py',executable:'module.py',runtimeVersion:'Python 3.14.8'}),
 php:Object.freeze({entry:'Ps.BackendPhp.CompilerService',exportName:'psCompilerPhpServiceCandidate',sourceFile:'module.php',executable:'module.php',runtimeVersion:'8.5.12'}),
 'wasm-core':Object.freeze({entry:'Ps.BackendWasm.CompilerService',exportName:'psCompilerWasmServiceCandidate',sourceFile:'module.wasm.hex',executable:'module.wasm'})
});
export function generatedTarget(target){assert.ok(Object.hasOwn(targets,target),'PSC1_GENERATED_TARGET_UNSUPPORTED');return targets[target];}
export const generatedTargets=Object.freeze(Object.keys(targets));

export const unifiedOutputTargets=Object.freeze(['js','ts','rust','wasm-core']);
export const unifiedCompiler=Object.freeze({entry:'Ps.CompilerUnified.Service',exportName:'psCompilerServiceCandidate'});
export function compilerService(target,kind='single') {
 const definition=generatedTarget(target);
 assert.ok(kind==='single'||kind==='unified','PSC1_SERVICE_KIND_UNSUPPORTED');
 if(kind==='unified')assert.ok(unifiedOutputTargets.includes(target),'PSC1_UNIFIED_ENGINE_UNSUPPORTED');
 return kind==='unified'?{...definition,...unifiedCompiler}:definition;
}
