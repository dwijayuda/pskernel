import type {ProofScriptFeatureId} from '../features.js';
import type {SourceSpan} from '../source.js';
import type {V061TypeExpr} from './type-parser.js';
import type {V061Pattern} from './pattern-parser.js';

export interface V061Parameter {
  readonly name:string;
  readonly type:V061TypeExpr;
  readonly span:SourceSpan;
}

export interface V061MatchAlternative {
  readonly pattern:V061Pattern;
  readonly body:V061Expr;
  readonly span:SourceSpan;
}

export interface V061LambdaBinder {
  readonly name:string;
  readonly type?:V061TypeExpr;
  readonly span:SourceSpan;
}

export type V061Expr =
  | {readonly kind:'nat';readonly text:string;readonly span:SourceSpan}
  | {readonly kind:'string';readonly value:string;readonly span:SourceSpan}
  | {readonly kind:'bool';readonly value:boolean;readonly span:SourceSpan}
  | {readonly kind:'unit';readonly span:SourceSpan}
  | {readonly kind:'reference';readonly name:string;readonly span:SourceSpan}
  | {readonly kind:'group';readonly value:V061Expr;readonly span:SourceSpan}
  | {readonly kind:'call';readonly callee:string;readonly args:readonly V061Expr[];readonly span:SourceSpan}
  | {readonly kind:'unary';readonly operator:'!';readonly operand:V061Expr;readonly span:SourceSpan}
  | {readonly kind:'binary';readonly operator:string;readonly left:V061Expr;readonly right:V061Expr;readonly span:SourceSpan}
  | {readonly kind:'if';readonly condition:V061Expr;readonly thenBranch:V061Expr;readonly elseBranch:V061Expr;readonly span:SourceSpan}
  | {readonly kind:'lambda';readonly binders:readonly V061LambdaBinder[];readonly body:V061Expr;readonly span:SourceSpan}
  | {
      readonly kind:'match';
      readonly scrutinee:V061Expr;
      readonly alternatives:readonly V061MatchAlternative[];
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'let';
      readonly name:string;
      readonly declaredType?:V061TypeExpr;
      readonly value:V061Expr;
      readonly body:V061Expr;
      readonly span:SourceSpan;
    };

export interface V061Declaration {
  readonly kind:'const'|'def'|'function';
  readonly name:string;
  readonly params:readonly V061Parameter[];
  readonly resultType:V061TypeExpr;
  readonly body:V061Expr;
  readonly terminatedBySemicolon:boolean;
  readonly span:SourceSpan;
}

export interface V061Module {
  readonly kind:'v061-module';
  readonly declarations:readonly V061Declaration[];
  readonly featureIds:readonly ProofScriptFeatureId[];
}
