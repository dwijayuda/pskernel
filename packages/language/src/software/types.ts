import type {V061Declaration} from '@proofscript/syntax';

export type SoftwareType='Nat'|'Int'|'Bool'|'String'|'Unit';

export type CheckedSoftwareExpr =
  | {readonly kind:'nat';readonly value:bigint;readonly resultType:'Nat'|'Int'}
  | {readonly kind:'string';readonly value:string;readonly resultType:'String'}
  | {readonly kind:'bool';readonly value:boolean;readonly resultType:'Bool'}
  | {readonly kind:'unit';readonly resultType:'Unit'}
  | {readonly kind:'reference';readonly name:string;readonly resultType:SoftwareType}
  | {readonly kind:'call';readonly callee:string;readonly args:readonly CheckedSoftwareExpr[];readonly resultType:SoftwareType}
  | {readonly kind:'unary';readonly operator:'!';readonly operand:CheckedSoftwareExpr;readonly resultType:'Bool'}
  | {readonly kind:'binary';readonly operator:string;readonly left:CheckedSoftwareExpr;readonly right:CheckedSoftwareExpr;readonly resultType:SoftwareType}
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
