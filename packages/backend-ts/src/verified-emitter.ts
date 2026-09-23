import {
  validateVerifiedIrModule,
  type VerifiedIrModule,
} from '@proofscript/compiler-ir/verified';
import {
  buildBrandMap,
  buildTagMap,
  emitVerifiedInductives,
  emitVerifiedStructures,
} from './verified-symbols.js';
import {emitVerifiedExpr} from './verified-expr-emitter.js';
import {emitVerifiedType} from './verified-type-emitter.js';

export function emitVerifiedTypeScript(
  module:VerifiedIrModule,
):string {
  validateVerifiedIrModule(module);
  const brands=buildBrandMap(module);
  const tags=buildTagMap(module);
  const lines=[
    '// generated from pskernel-admitted ProofScript checked core',
    ...emitVerifiedStructures(module,brands),
    ...emitVerifiedInductives(module,tags),
  ];

  for(const declaration of module.declarations){
    const generics=declaration.typeParameters.length===0
      ?''
      :'<'+declaration.typeParameters
        .map((item)=>item.name).join(', ')+'>';

    if(declaration.parameters.length===0){
      if(declaration.typeParameters.length>0){
        throw new Error(
          "PS_TS_GENERIC_VALUE_UNSUPPORTED: '"+
          declaration.name+
          "' has erased type parameters but no runtime parameters",
        );
      }
      lines.push(
        'export const '+declaration.name+': '+
        emitVerifiedType(declaration.resultType)+' = '+
        emitVerifiedExpr(declaration.body,brands,tags)+';',
      );
      continue;
    }

    const parameters=declaration.parameters.map((parameter)=>
      parameter.name+': '+emitVerifiedType(parameter.type)
    ).join(', ');
    lines.push(
      'export function '+declaration.name+generics+
      '('+parameters+'): '+
      emitVerifiedType(declaration.resultType)+
      ' { return '+
      emitVerifiedExpr(declaration.body,brands,tags)+'; }',
    );
  }

  return lines.join('\n')+'\n';
}
