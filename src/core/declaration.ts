import { Expr } from './expr.js';
import { Level } from './level.js';
import { Name } from './name.js';

export type DefinitionSafety = 'unsafe' | 'safe' | 'partial';

export type ReducibilityHints =
  | { readonly kind: 'opaque' }
  | { readonly kind: 'abbrev' }
  | { readonly kind: 'regular'; readonly height: bigint };

interface BaseInfo { readonly name: Name; readonly levelParams: readonly Name[]; readonly type: Expr }
export interface AxiomInfo extends BaseInfo { readonly kind: 'axiom'; readonly isUnsafe?: boolean }
export interface DefinitionInfo extends BaseInfo { readonly kind: 'definition'; readonly value: Expr; readonly hints: ReducibilityHints; readonly safety: DefinitionSafety }
export interface TheoremInfo extends BaseInfo { readonly kind: 'theorem'; readonly value: Expr }
export interface OpaqueInfo extends BaseInfo { readonly kind: 'opaque'; readonly value: Expr; readonly isUnsafe?: boolean }
export interface InductiveInfo extends BaseInfo {
  readonly kind: 'inductive'; readonly numParams: number; readonly numIndices: number; readonly all: readonly Name[];
  readonly ctors: readonly Name[]; readonly numNested: number; readonly isRec: boolean; readonly isReflexive: boolean; readonly isUnsafe?: boolean;
}
export interface ConstructorInfo extends BaseInfo {
  readonly kind: 'constructor'; readonly induct: Name; readonly cidx: number; readonly numParams: number; readonly numFields: number; readonly isUnsafe?: boolean;
}
export interface RecursorRule { readonly ctor: Name; readonly nFields: number; readonly rhs: Expr }
export interface RecursorInfo extends BaseInfo {
  readonly kind: 'recursor'; readonly all: readonly Name[]; readonly numParams: number; readonly numIndices: number; readonly numMotives: number;
  readonly numMinors: number; readonly rules: readonly RecursorRule[]; readonly k: boolean; readonly isUnsafe?: boolean;
}
export interface QuotInfo extends BaseInfo { readonly kind: 'quot'; readonly quotKind: 'type'|'ctor'|'lift'|'ind' }
export type ConstantInfo = AxiomInfo|DefinitionInfo|TheoremInfo|OpaqueInfo|InductiveInfo|ConstructorInfo|RecursorInfo|QuotInfo;
export function hasValue(i: ConstantInfo): i is DefinitionInfo|TheoremInfo|OpaqueInfo { return i.kind==='definition'||i.kind==='theorem'||i.kind==='opaque'; }
export function isUnsafeConstant(i: ConstantInfo): boolean {
  switch(i.kind){
    case 'definition': return i.safety==='unsafe';
    case 'axiom': case 'opaque': case 'inductive': case 'constructor': case 'recursor': return i.isUnsafe===true;
    case 'theorem': case 'quot': return false;
  }
}
