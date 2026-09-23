import type {V061TypeExpr} from '@proofscript/syntax';
import type {PrimitiveSoftwareType,SoftwareType} from './types.js';
import {softwareTypeToString} from './types.js';

const PRIMITIVES=new Set<PrimitiveSoftwareType>(['Nat','Int','Bool','String','Unit']);

export function asSoftwareType(type:V061TypeExpr):SoftwareType {
  switch(type.kind){
    case 'group':
      return asSoftwareType(type.value);
    case 'named':
      if(!PRIMITIVES.has(type.name as PrimitiveSoftwareType)){
        throw new Error("PS_CHECK_UNKNOWN_TYPE: unsupported software type '"+type.name+"'");
      }
      return type.name as PrimitiveSoftwareType;
    case 'arrow':
      return {
        kind:'function',
        parameter:asSoftwareType(type.domain),
        result:asSoftwareType(type.codomain),
      };
  }
}

export function requirePrimitiveSoftwareType(
  type:SoftwareType,
  context:string,
):PrimitiveSoftwareType {
  if(typeof type!=='string'){
    throw new Error(context+' expects a primitive software type, got '+softwareTypeToString(type));
  }
  return type;
}
