import {
  anonymous,
  numName,
  strName,
  type Name,
} from 'lean-ts-kernel';
import type {
  Lean434ConstructorValue,
  Lean434RuntimeValue,
} from './lean4-eval.js';

export class Lean434NameBridgeError extends Error{
  constructor(message:string){
    super(message);
    this.name='Lean434NameBridgeError';
  }
}

function constructor(
  value:Lean434RuntimeValue,
  expected:string,
):Lean434ConstructorValue{
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
    ||!('kind' in value)
    ||value.kind!=='constructor'
    ||value.name!==expected
  ){
    throw new Lean434NameBridgeError(
      "expected Lean runtime constructor '"+expected+"'",
    );
  }
  return value;
}

/**
 * Convert an executable Lean.Name value produced by the JS evaluator into the
 * structurally identical pskernel Name model.
 *
 * This conversion is untrusted runtime plumbing, not declaration admission.
 */
export function lean434RuntimeNameToKernel(
  value:Lean434RuntimeValue,
):Name{
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
    ||!('kind' in value)
    ||value.kind!=='constructor'
  ){
    throw new Lean434NameBridgeError('runtime Lean.Name is not a constructor');
  }

  switch(value.name){
    case 'Lean.Name.anonymous':
      if(value.fields.length!==0){
        throw new Lean434NameBridgeError(
          'Lean.Name.anonymous has unexpected runtime fields',
        );
      }
      return anonymous;
    case 'Lean.Name.str':{
      if(value.fields.length!==2){
        throw new Lean434NameBridgeError(
          'Lean.Name.str has unexpected runtime fields',
        );
      }
      const prefix=lean434RuntimeNameToKernel(value.fields[0]!);
      const text=value.fields[1];
      if(typeof text!=='string'){
        throw new Lean434NameBridgeError(
          'Lean.Name.str suffix is not a runtime String',
        );
      }
      return strName(prefix,text);
    }
    case 'Lean.Name.num':{
      if(value.fields.length!==2){
        throw new Lean434NameBridgeError(
          'Lean.Name.num has unexpected runtime fields',
        );
      }
      const prefix=lean434RuntimeNameToKernel(value.fields[0]!);
      const index=value.fields[1];
      if(typeof index!=='bigint'||index<0n){
        throw new Lean434NameBridgeError(
          'Lean.Name.num index is not a runtime Nat',
        );
      }
      return numName(prefix,index);
    }
    default:
      throw new Lean434NameBridgeError(
        "unexpected runtime Lean.Name constructor '"+value.name+"'",
      );
  }
}

/**
 * Convert a pskernel Name into the canonical executable Lean.Name constructor
 * representation expected by reused Lean source.
 */
export function kernelNameToLean434Runtime(
  name:Name,
):Lean434ConstructorValue{
  switch(name.kind){
    case 'anonymous':
      return {
        kind:'constructor',
        name:'Lean.Name.anonymous',
        fields:[],
      };
    case 'str':
      return {
        kind:'constructor',
        name:'Lean.Name.str',
        fields:[
          kernelNameToLean434Runtime(name.prefix),
          name.value,
        ],
      };
    case 'num':
      return {
        kind:'constructor',
        name:'Lean.Name.num',
        fields:[
          kernelNameToLean434Runtime(name.prefix),
          name.value,
        ],
      };
  }
}

/** Validate that a runtime value is a Lean.Name without allocating a kernel copy. */
export function assertLean434RuntimeName(
  value:Lean434RuntimeValue,
):Lean434ConstructorValue{
  const name=lean434RuntimeNameToKernel(value);
  return constructor(
    kernelNameToLean434Runtime(name),
    kernelNameToLean434Runtime(name).name,
  );
}
