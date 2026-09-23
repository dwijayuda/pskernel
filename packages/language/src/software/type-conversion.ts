import type {V061TypeExpr} from '@proofscript/syntax';
import type {PrimitiveSoftwareType,SoftwareType} from './types.js';
import {softwareTypeToString} from './types.js';

const PRIMITIVES=new Set<PrimitiveSoftwareType>(['Nat','Int','Bool','String','Unit']);
const EMPTY_NOMINALS:ReadonlySet<string>=new Set();

export function asSoftwareType(
  type:V061TypeExpr,
  nominalTypes:ReadonlySet<string>=EMPTY_NOMINALS,
):SoftwareType {
  switch(type.kind){
    case 'nat':
    case 'binary':
      throw new Error(
        'PS_CHECK_DEPENDENT_TYPE_TERM_UNSUPPORTED: theorem/type terms require verified elaboration',
      );
    case 'group':
      return asSoftwareType(type.value,nominalTypes);
    case 'named':
      if(PRIMITIVES.has(type.name as PrimitiveSoftwareType)){
        return type.name as PrimitiveSoftwareType;
      }
      if(nominalTypes.has(type.name)){
        return {kind:'nominal',name:type.name};
      }
      throw new Error("PS_CHECK_UNKNOWN_TYPE: unsupported software type '"+type.name+"'");
    case 'application':
      throw new Error(
        'PS_CHECK_TYPE_APPLICATION_UNSUPPORTED: applied/generic types require elaboration',
      );
    case 'equality':
      throw new Error(
        'PS_CHECK_PROPOSITION_EQUALITY_UNSUPPORTED: proof propositions require verified elaboration',
      );
    case 'arrow':
      return {
        kind:'function',
        parameter:asSoftwareType(type.domain,nominalTypes),
        result:asSoftwareType(type.codomain,nominalTypes),
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
