import type {V061Declaration} from '@proofscript/syntax';

export type PrimitiveSoftwareType='Nat'|'Int'|'Bool'|'String'|'Unit';
export interface FunctionSoftwareType {
  readonly kind:'function';
  readonly parameter:SoftwareType;
  readonly result:SoftwareType;
}
export type SoftwareType=PrimitiveSoftwareType|FunctionSoftwareType;

export function isPrimitiveSoftwareType(type:SoftwareType):type is PrimitiveSoftwareType {
  return typeof type==='string';
}

export function softwareTypeEquals(left:SoftwareType,right:SoftwareType):boolean {
  if(typeof left==='string'||typeof right==='string')return left===right;
  return left.kind==='function'&&right.kind==='function'
    &&softwareTypeEquals(left.parameter,right.parameter)
    &&softwareTypeEquals(left.result,right.result);
}

export function makeFunctionSoftwareType(parameters:readonly SoftwareType[],result:SoftwareType):SoftwareType {
  return [...parameters].reverse().reduce<SoftwareType>(
    (body,parameter)=>({kind:'function',parameter,result:body}),
    result,
  );
}

export function softwareTypeToString(type:SoftwareType):string {
  if(typeof type==='string')return type;
  const domain=typeof type.parameter==='string'
    ? softwareTypeToString(type.parameter)
    : '('+softwareTypeToString(type.parameter)+')';
  return domain+' -> '+softwareTypeToString(type.result);
}

export type CheckedSoftwareExpr =
  | {readonly kind:'nat';readonly value:bigint;readonly resultType:'Nat'|'Int'}
  | {readonly kind:'string';readonly value:string;readonly resultType:'String'}
  | {readonly kind:'bool';readonly value:boolean;readonly resultType:'Bool'}
  | {readonly kind:'unit';readonly resultType:'Unit'}
  | {readonly kind:'reference';readonly name:string;readonly resultType:SoftwareType}
  | {
      readonly kind:'call';
      readonly callee:string;
      readonly args:readonly CheckedSoftwareExpr[];
      readonly callStyle:'direct'|'curried';
      readonly resultType:SoftwareType;
    }
  | {
      readonly kind:'lambda';
      readonly binders:readonly {readonly name:string;readonly type:SoftwareType}[];
      readonly body:CheckedSoftwareExpr;
      readonly resultType:SoftwareType;
    }
  | {readonly kind:'unary';readonly operator:'!';readonly operand:CheckedSoftwareExpr;readonly resultType:'Bool'}
  | {readonly kind:'binary';readonly operator:string;readonly left:CheckedSoftwareExpr;readonly right:CheckedSoftwareExpr;readonly resultType:PrimitiveSoftwareType}
  | {readonly kind:'if';readonly condition:CheckedSoftwareExpr;readonly thenBranch:CheckedSoftwareExpr;readonly elseBranch:CheckedSoftwareExpr;readonly resultType:SoftwareType}
  | {
      readonly kind:'let';
      readonly name:string;
      readonly declaredType?:SoftwareType;
      readonly value:CheckedSoftwareExpr;
      readonly body:CheckedSoftwareExpr;
      readonly resultType:SoftwareType;
    };

export interface CheckedSoftwareParameter {
  readonly name:string;
  readonly type:SoftwareType;
}

export interface CheckedSoftwareDeclaration {
  readonly kind:V061Declaration['kind'];
  readonly name:string;
  readonly params:readonly CheckedSoftwareParameter[];
  readonly resultType:SoftwareType;
  readonly body:CheckedSoftwareExpr;
}

export interface CheckedSoftwareModule {
  readonly kind:'checked-v061-software-module';
  readonly declarations:readonly CheckedSoftwareDeclaration[];
}

export interface SoftwareSignature {
  readonly params:readonly SoftwareType[];
  readonly result:SoftwareType;
}
