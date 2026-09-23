import {
  normalizesToZero,
  type Expr,
  type LocalContext,
  type TypeChecker,
} from 'lean-ts-kernel';
import type {
  VerifiedIrExpr,
  VerifiedIrType,
} from '@proofscript/compiler-ir/verified';

export type ErasedBinderKind='type'|'proof'|'runtime';

export interface RuntimeStructureField {
  readonly sourceIndex:number;
  readonly name:string;
  readonly type:VerifiedIrType;
}

export interface RuntimeStructureInfo {
  readonly name:string;
  readonly typeKey:string;
  readonly constructorKey:string;
  readonly fields:readonly RuntimeStructureField[];
}

export interface RuntimeConstructorField extends RuntimeStructureField {
  readonly recursive:boolean;
}

export interface RuntimeConstructorInfo {
  readonly inductive:string;
  readonly name:string;
  readonly constructorKey:string;
  readonly numParams:number;
  readonly fields:readonly RuntimeConstructorField[];
}

export interface RuntimeInductiveInfo {
  readonly name:string;
  readonly typeKey:string;
  readonly recursorKey:string;
  readonly numParams:number;
  readonly typeParameters:readonly import('@proofscript/compiler-ir/verified').VerifiedIrTypeParameter[];
  readonly constructors:readonly RuntimeConstructorInfo[];
}

export interface ErasureScope {
  readonly localContext:LocalContext;
  readonly runtimeExpressions?:ReadonlyMap<string,VerifiedIrExpr>;
  readonly currentDefinition?:{
    readonly name:string;
    readonly runtimeParameters:readonly string[];
  };
  readonly runtimeLocals:ReadonlyMap<string,string>;
  readonly typeLocals:ReadonlyMap<string,string>;
  readonly erasedLocals:ReadonlySet<string>;
  readonly declarationNames:ReadonlyMap<string,string>;
  readonly structuresByType:ReadonlyMap<string,RuntimeStructureInfo>;
  readonly structuresByConstructor:ReadonlyMap<string,RuntimeStructureInfo>;
  readonly inductivesByType:ReadonlyMap<string,RuntimeInductiveInfo>;
  readonly inductivesByConstructor:ReadonlyMap<string,RuntimeConstructorInfo>;
  readonly inductivesByRecursor:ReadonlyMap<string,RuntimeInductiveInfo>;
}

export function classifyBinder(
  type:Expr,
  checker:TypeChecker,
):ErasedBinderKind {
  const whnf=checker.whnf(type);
  if(whnf.kind==='sort'){
    return normalizesToZero(whnf.level)?'proof':'type';
  }
  if(checker.isProp(type))return 'proof';
  return 'runtime';
}

export function runtimeTypeUnknown():VerifiedIrType {
  return {kind:'unknown'};
}
