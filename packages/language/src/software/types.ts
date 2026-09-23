import type {V061ValueDeclaration} from '@proofscript/syntax';

export type PrimitiveSoftwareType='Nat'|'Int'|'Bool'|'String'|'Unit';

export interface NominalSoftwareType {
  readonly kind:'nominal';
  readonly name:string;
}

export interface FunctionSoftwareType {
  readonly kind:'function';
  readonly parameter:SoftwareType;
  readonly result:SoftwareType;
}

export type SoftwareType=PrimitiveSoftwareType|NominalSoftwareType|FunctionSoftwareType;

export function isPrimitiveSoftwareType(type:SoftwareType):type is PrimitiveSoftwareType {
  return typeof type==='string';
}

export function isFunctionSoftwareType(type:SoftwareType):type is FunctionSoftwareType {
  return typeof type!=='string'&&type.kind==='function';
}

export function softwareTypeEquals(left:SoftwareType,right:SoftwareType):boolean {
  if(typeof left==='string'||typeof right==='string')return left===right;
  if(left.kind!==right.kind)return false;
  if(left.kind==='nominal'&&right.kind==='nominal')return left.name===right.name;
  if(left.kind==='function'&&right.kind==='function'){
    return softwareTypeEquals(left.parameter,right.parameter)
      &&softwareTypeEquals(left.result,right.result);
  }
  return false;
}

export function makeFunctionSoftwareType(
  parameters:readonly SoftwareType[],
  result:SoftwareType,
):SoftwareType {
  return [...parameters].reverse().reduce<SoftwareType>(
    (body,parameter)=>({kind:'function',parameter,result:body}),
    result,
  );
}

export function softwareTypeToString(type:SoftwareType):string {
  if(typeof type==='string')return type;
  if(type.kind==='nominal')return type.name;
  const domain=isPrimitiveSoftwareType(type.parameter)||type.parameter.kind==='nominal'
    ? softwareTypeToString(type.parameter)
    : '('+softwareTypeToString(type.parameter)+')';
  return domain+' -> '+softwareTypeToString(type.result);
}

export interface CheckedSoftwareStructureField {
  readonly name:string;
  readonly type:SoftwareType;
}

export interface CheckedSoftwareStructure {
  readonly name:string;
  readonly fields:readonly CheckedSoftwareStructureField[];
}

export interface CheckedSoftwareInductiveField {
  readonly name:string;
  readonly type:SoftwareType;
}

export interface CheckedSoftwareConstructor {
  readonly name:string;
  readonly qualifiedName:string;
  readonly fields:readonly CheckedSoftwareInductiveField[];
}

export interface CheckedSoftwareInductive {
  readonly name:string;
  readonly constructors:readonly CheckedSoftwareConstructor[];
}

export interface CheckedSoftwareConstructorRef {
  readonly inductive:CheckedSoftwareInductive;
  readonly constructor:CheckedSoftwareConstructor;
}

export type CheckedSoftwarePattern =
  | {readonly kind:'bool';readonly value:boolean}
  | {readonly kind:'wildcard'}
  | {
      readonly kind:'constructor';
      readonly inductive:string;
      readonly constructor:string;
      readonly binders:readonly {
        readonly name:string;
        readonly field:string;
        readonly type:SoftwareType;
      }[];
    };

export interface CheckedSoftwareMatchAlternative {
  readonly pattern:CheckedSoftwarePattern;
  readonly body:CheckedSoftwareExpr;
}

export type CheckedSoftwareExpr =
  | {readonly kind:'nat';readonly value:bigint;readonly resultType:'Nat'|'Int'}
  | {readonly kind:'string';readonly value:string;readonly resultType:'String'}
  | {readonly kind:'bool';readonly value:boolean;readonly resultType:'Bool'}
  | {readonly kind:'unit';readonly resultType:'Unit'}
  | {readonly kind:'reference';readonly name:string;readonly resultType:SoftwareType}
  | {
      readonly kind:'projection';
      readonly target:CheckedSoftwareExpr;
      readonly field:string;
      readonly resultType:SoftwareType;
    }
  | {
      readonly kind:'record';
      readonly structure:string;
      readonly fields:readonly {readonly name:string;readonly value:CheckedSoftwareExpr}[];
      readonly resultType:NominalSoftwareType;
    }
  | {
      readonly kind:'constructor';
      readonly inductive:string;
      readonly constructor:string;
      readonly fields:readonly {readonly name:string;readonly value:CheckedSoftwareExpr}[];
      readonly resultType:NominalSoftwareType;
    }
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
      readonly kind:'match';
      readonly scrutinee:CheckedSoftwareExpr;
      readonly alternatives:readonly CheckedSoftwareMatchAlternative[];
      readonly resultType:SoftwareType;
    }
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

export interface CheckedSoftwareLocalDeclaration {
  readonly name:string;
  readonly params:readonly CheckedSoftwareParameter[];
  readonly resultType:SoftwareType;
  readonly body:CheckedSoftwareExpr;
}

export interface CheckedSoftwareDeclaration {
  readonly kind:V061ValueDeclaration['kind'];
  readonly name:string;
  readonly params:readonly CheckedSoftwareParameter[];
  readonly resultType:SoftwareType;
  readonly body:CheckedSoftwareExpr;
  readonly whereDeclarations?:readonly CheckedSoftwareLocalDeclaration[];
}

export interface CheckedSoftwareModule {
  readonly kind:'checked-v061-software-module';
  readonly structures:readonly CheckedSoftwareStructure[];
  readonly inductives:readonly CheckedSoftwareInductive[];
  readonly declarations:readonly CheckedSoftwareDeclaration[];
}

export interface SoftwareSignature {
  readonly params:readonly SoftwareType[];
  readonly result:SoftwareType;
}
