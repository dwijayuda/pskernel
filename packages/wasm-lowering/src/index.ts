import {
  validateVerifiedIrModule,
  type VerifiedIrModule,
} from '@proofscript/compiler-ir/verified';
import {
  validateWasmIrModule,
  type WasmIrFunction,
  type WasmIrModule,
} from '@proofscript/wasm-ir';
import {unsupported} from './errors.js';
import {lowerRuntimeExpr} from './expression-lowering.js';
import {
  signatureOf,
  wasmResultType,
  wasmValueType,
  type RuntimeType,
  type Signature,
} from './type-lowering.js';

export {
  WasmLoweringError,
} from './errors.js';
export {
  lowerRuntimeType,
  wasmResultType,
  wasmValueType,
} from './type-lowering.js';

export const PROOFSCRIPT_WASM_PROFILE=
  'proofscript-wasm32-gc-js-v1' as const;

export function lowerVerifiedIrToWasm(
  module:VerifiedIrModule,
):WasmIrModule {
  validateVerifiedIrModule(module);
  if((module.imports??[]).length!==0){
    return unsupported(
      'PS_WASM_UNSUPPORTED_EXTERNAL_IMPORTS',
      'W1 does not yet define the WebAssembly FFI import ABI',
    );
  }
  if((module.structures??[]).length!==0){
    return unsupported(
      'PS_WASM_UNSUPPORTED_STRUCTURE',
      'W1 does not yet lower runtime structures',
    );
  }
  if((module.inductives??[]).length!==0){
    return unsupported(
      'PS_WASM_UNSUPPORTED_ADT',
      'W1 does not yet lower runtime inductive types',
    );
  }

  const signatures=new Map<string,Signature>();
  for(const declaration of module.declarations){
    signatures.set(declaration.name,signatureOf(declaration));
  }

  const functions:WasmIrFunction[]=module.declarations.map(
    (declaration)=>{
      const signature=signatures.get(declaration.name)!;
      const locals=new Map<string,RuntimeType>();
      const parameters=declaration.parameters.map(
        (parameter,index)=>{
          const type=signature.parameters[index]!;
          locals.set(parameter.name,type);
          return {
            name:parameter.name,
            type:wasmValueType(type),
          };
        },
      );

      return {
        name:declaration.name,
        parameters,
        result:wasmResultType(signature.result),
        exportName:declaration.name,
        body:lowerRuntimeExpr(
          declaration.body,
          signature.result,
          locals,
          signatures,
        ),
      };
    },
  );

  const wasm:WasmIrModule={
    kind:'proofscript-wasm-ir',
    profile:PROOFSCRIPT_WASM_PROFILE,
    functions,
  };
  validateWasmIrModule(wasm);
  return wasm;
}
