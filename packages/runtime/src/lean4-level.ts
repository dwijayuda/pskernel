import {
  levelIMaxRaw,
  levelMVar,
  levelMaxRaw,
  levelParam,
  levelSucc,
  levelZero,
  type Level,
} from 'lean-ts-kernel';
import type {
  Lean434ConstructorValue,
  Lean434RuntimeValue,
} from './lean4-eval.js';
import {
  kernelNameToLean434Runtime,
  lean434RuntimeNameToKernel,
} from './lean4-name.js';

export class Lean434LevelBridgeError extends Error{
  constructor(message:string){
    super(message);
    this.name='Lean434LevelBridgeError';
  }
}

function runtimeCtor(
  value:Lean434RuntimeValue,
  expected:string,
  fields:number,
):Lean434ConstructorValue{
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
    ||!('kind' in value)
    ||value.kind!=='constructor'
    ||value.name!==expected
    ||value.fields.length!==fields
  ){
    throw new Lean434LevelBridgeError(
      "expected Lean runtime constructor '"+expected+
      "' with "+String(fields)+' fields',
    );
  }
  return value;
}

function runtimeMVarName(value:Lean434RuntimeValue){
  const mvar=runtimeCtor(value,'Lean.LevelMVarId.mk',1);
  return lean434RuntimeNameToKernel(mvar.fields[0]!);
}

/**
 * Convert an executable Lean.Level value into pskernel's structurally matching
 * universe-level model.
 *
 * This is runtime plumbing only. Kernel level checking and equivalence remain
 * implemented exclusively by pskernel.
 */
export function lean434RuntimeLevelToKernel(
  value:Lean434RuntimeValue,
):Level{
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
    ||!('kind' in value)
    ||value.kind!=='constructor'
  ){
    throw new Lean434LevelBridgeError(
      'runtime Lean.Level is not a constructor',
    );
  }

  switch(value.name){
    case 'Lean.Level.zero':
      if(value.fields.length!==0){
        throw new Lean434LevelBridgeError(
          'Lean.Level.zero has unexpected runtime fields',
        );
      }
      return levelZero;
    case 'Lean.Level.succ':{
      const ctor=runtimeCtor(value,'Lean.Level.succ',1);
      return levelSucc(
        lean434RuntimeLevelToKernel(ctor.fields[0]!),
      );
    }
    case 'Lean.Level.max':{
      const ctor=runtimeCtor(value,'Lean.Level.max',2);
      return levelMaxRaw(
        lean434RuntimeLevelToKernel(ctor.fields[0]!),
        lean434RuntimeLevelToKernel(ctor.fields[1]!),
      );
    }
    case 'Lean.Level.imax':{
      const ctor=runtimeCtor(value,'Lean.Level.imax',2);
      return levelIMaxRaw(
        lean434RuntimeLevelToKernel(ctor.fields[0]!),
        lean434RuntimeLevelToKernel(ctor.fields[1]!),
      );
    }
    case 'Lean.Level.param':{
      const ctor=runtimeCtor(value,'Lean.Level.param',1);
      return levelParam(
        lean434RuntimeNameToKernel(ctor.fields[0]!),
      );
    }
    case 'Lean.Level.mvar':{
      const ctor=runtimeCtor(value,'Lean.Level.mvar',1);
      return levelMVar(runtimeMVarName(ctor.fields[0]!));
    }
    default:
      throw new Lean434LevelBridgeError(
        "unexpected runtime Lean.Level constructor '"+value.name+"'",
      );
  }
}

export function kernelLevelToLean434Runtime(
  level:Level,
):Lean434ConstructorValue{
  switch(level.kind){
    case 'zero':
      return {
        kind:'constructor',
        name:'Lean.Level.zero',
        fields:[],
      };
    case 'succ':
      return {
        kind:'constructor',
        name:'Lean.Level.succ',
        fields:[kernelLevelToLean434Runtime(level.of)],
      };
    case 'max':
      return {
        kind:'constructor',
        name:'Lean.Level.max',
        fields:[
          kernelLevelToLean434Runtime(level.left),
          kernelLevelToLean434Runtime(level.right),
        ],
      };
    case 'imax':
      return {
        kind:'constructor',
        name:'Lean.Level.imax',
        fields:[
          kernelLevelToLean434Runtime(level.left),
          kernelLevelToLean434Runtime(level.right),
        ],
      };
    case 'param':
      return {
        kind:'constructor',
        name:'Lean.Level.param',
        fields:[kernelNameToLean434Runtime(level.name)],
      };
    case 'mvar':
      return {
        kind:'constructor',
        name:'Lean.Level.mvar',
        fields:[{
          kind:'constructor',
          name:'Lean.LevelMVarId.mk',
          fields:[kernelNameToLean434Runtime(level.name)],
        }],
      };
  }
}
