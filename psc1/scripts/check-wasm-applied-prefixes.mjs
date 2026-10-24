// Operational source invariant: recursive prefixes are admitted only after input binders.
import assert from 'node:assert/strict';import fs from 'node:fs';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {generatedTarget} from '../host-tools/generated-target-profiles.mjs';
const entries=[
  {path:"packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",name:"psWasmLowerExprWorker"},
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/RuntimeNat.lean",
    "name": "psWasmNatLiteralInstructionsWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/RuntimeString.lean",
    "name": "psWasmStringLiteralChunksWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Type.lean",
    "name": "psWasmIrTypeKeyWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/ValidateStructure.lean",
    "name": "psWasmIrAppend"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/ValidateStructure.lean",
    "name": "psWasmIrValueTypeListsEq"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/ValidateStructure.lean",
    "name": "psWasmIrValidateControl"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/ValidateTyping.lean",
    "name": "psWasmTypingHeapSubtypeWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/ValidateTyping.lean",
    "name": "psWasmTypingFieldsMatch"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/ValidateTyping.lean",
    "name": "psWasmTypingValidateParents"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/ValidateTyping.lean",
    "name": "psWasmTypingNth"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/ValidateTyping.lean",
    "name": "psWasmTypingPushValues"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/ValidateTyping.lean",
    "name": "psWasmTypingPopReversed"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/ValidateTyping.lean",
    "name": "psWasmTypingRepeatPop"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/ValidateTyping.lean",
    "name": "psWasmTypingInstructions"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmListFoldlWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmCollectFunctionTypesFromTypeWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmCollectFunctionTypesFromExprWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmCollectArrayTypesFromTypeWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmCollectArrayTypesFromExprWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmFindStructureFieldWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmFindConstructorFieldWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmParameterBindingsWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmCollectCapturesWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmParameterBindingsFromWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmLocalGetsForTypesWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmLowerExprListWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmLowerRecordFieldsWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmLowerConstructorValuesWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmLowerTypedArgumentsWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmLowerMatchBindingsWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmLowerMatchAlternativesWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmPrepareCaptureBindingsWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmGlobalFunctionParameters"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmLowerDeclarationsWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmTypeUsesNatWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmExprUsesNatWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmTypeUsesIntWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmExprUsesIntWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmTypeUsesStringWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "name": "psWasmExprUsesStringWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/BinaryBytes.lean",
    "name": "psWasmEncodeUlebWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/BinaryBytes.lean",
    "name": "psWasmEncodeSlebWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/BinaryBytes.lean",
    "name": "psWasmStringToListFromWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/BinaryBytes.lean",
    "name": "psWasmFindStructureIndexWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/BinaryBytes.lean",
    "name": "psWasmFindArrayIndexWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/BinaryBytes.lean",
    "name": "psWasmFindFunctionTypeIndexWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/BinaryBytes.lean",
    "name": "psWasmFindFunctionIndexWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/BinaryBytes.lean",
    "name": "psWasmEncodeFunctionTypeIndicesAcc"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/IntUtil.lean",
    "name": "psWasmIntDecimalMagnitudeWithFuel"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/TailCalls.lean",
    "name": "psWasmTailCallsWorker"
  },
  {
    "path": "packages/backend-wasm/src/Ps/BackendWasm/TailCalls.lean",
    "name": "psWasmDiscardUnitWorker"
  }
];
for(const entry of entries){
 const source=fs.readFileSync(entry.path,'utf8'),at=source.indexOf('def '+entry.name+'\n')>=0?source.indexOf('def '+entry.name+'\n'):source.indexOf('def '+entry.name+' ');
 assert.ok(at>=0,'missing worker '+entry.name);
 const next=source.indexOf('\ndef ',at+5),body=source.slice(at,next<0?source.length:next);
 const unsafe=new RegExp('let\\s+\\w+(?:(?!:=)[\\s\\S])*:=\\s*'+entry.name+'\\b[^;]*;\\s*fun\\b');
 assert.equal(unsafe.test(body),false,'eager recursive prefix before inputs: '+entry.name);
}

// Use the real owned import closure, not native-only helper files. Type annotations
// and applications can span arbitrary lines; do not hide them behind regex bounds.
const problems=[];let scanned=0;
for(const row of readOwnedCompilerSources(generatedTarget('wasm-core').entry)){
 if(!row.module.startsWith('Ps.BackendWasm.'))continue;
 for(const block of row.text.split(/(?=^def )/m)){
  const match=/^def\s+([A-Za-z0-9_]+)/.exec(block);if(!match)continue;scanned++;
  const name=match[1];
  const unsafe=new RegExp('let\\s+\\w+(?:(?!:=)[\\s\\S])*:=\\s*'+name+'\\b[^;]*;\\s*fun\\b');
  if(unsafe.test(block))problems.push({module:row.module,name});
 }
}
console.log('PSC1_WASM_OWNED_PREFIX_SCAN: '+JSON.stringify({scanned,problems}));
assert.deepEqual(problems,[],'owned Wasm recursive prefix before remaining inputs');

console.log('PSC1_WASM_APPLIED_PREFIXES: '+entries.length+' workers; no recursive prefix before remaining input binders');

const retained=fs.readFileSync('test/WasmLowerExprPrefixReference.lean','utf8');
assert.ok(new RegExp('let\\s+\\w+(?:(?!:=)[\\s\\S])*:=\\s*psWasmLowerExprWorker\\b[^;]*;\\s*fun\\b').test(retained),'regression detector must reject the actual retained multiline prefix');
