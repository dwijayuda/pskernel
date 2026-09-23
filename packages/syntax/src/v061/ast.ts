import type {ProofScriptFeatureId} from '../features.js';
import type {SourceSpan} from '../source.js';
import type {V061TypeExpr} from './type-parser.js';
import type {V061Pattern} from './pattern-parser.js';

export type V061BinderInfo='default'|'implicit'|'strictImplicit'|'instImplicit';

export interface V061Parameter {
  readonly name:string;
  readonly type:V061TypeExpr;
  readonly binderInfo?:V061BinderInfo;
  readonly span:SourceSpan;
}

export interface V061RecordField {
  readonly name:string;
  readonly value:V061Expr;
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

export type V061Tactic =
  | {readonly kind:'exact';readonly proof:V061Expr;readonly span:SourceSpan}
  | {readonly kind:'assumption';readonly span:SourceSpan}
  | {readonly kind:'constructor';readonly span:SourceSpan}
  | {
      readonly kind:'cases';
      readonly target:string;
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'induction';
      readonly target:string;
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'rw';
      readonly proof:V061Expr;
      readonly symm:boolean;
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'simp';
      readonly rules:readonly {
        readonly proof:V061Expr;
        readonly symm:boolean;
        readonly span:SourceSpan;
      }[];
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'apply';
      readonly proof:V061Expr;
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'refine';
      readonly proof:V061Expr;
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'intro';
      readonly name:string;
      readonly span:SourceSpan;
    };

export type V061Expr =
  | {readonly kind:'nat';readonly text:string;readonly span:SourceSpan}
  | {readonly kind:'string';readonly value:string;readonly span:SourceSpan}
  | {readonly kind:'bool';readonly value:boolean;readonly span:SourceSpan}
  | {readonly kind:'unit';readonly span:SourceSpan}
  | {readonly kind:'syntheticHole';readonly span:SourceSpan}
  | {readonly kind:'reference';readonly name:string;readonly span:SourceSpan}
  | {readonly kind:'group';readonly value:V061Expr;readonly span:SourceSpan}
  | {readonly kind:'call';readonly callee:string;readonly args:readonly V061Expr[];readonly span:SourceSpan}
  | {readonly kind:'unary';readonly operator:'!';readonly operand:V061Expr;readonly span:SourceSpan}
  | {readonly kind:'binary';readonly operator:string;readonly left:V061Expr;readonly right:V061Expr;readonly span:SourceSpan}
  | {readonly kind:'if';readonly condition:V061Expr;readonly thenBranch:V061Expr;readonly elseBranch:V061Expr;readonly span:SourceSpan}
  | {readonly kind:'lambda';readonly binders:readonly V061LambdaBinder[];readonly body:V061Expr;readonly span:SourceSpan}
  | {readonly kind:'by';readonly tactics:readonly V061Tactic[];readonly span:SourceSpan}
  | {
      readonly kind:'record';
      readonly fields:readonly V061RecordField[];
      readonly type:V061TypeExpr;
      readonly span:SourceSpan;
    }
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

export interface V061InductiveConstructor {
  readonly name:string;
  readonly params:readonly V061Parameter[];
  readonly span:SourceSpan;
}

export interface V061InductiveDeclaration {
  readonly kind:'inductive';
  readonly name:string;
  readonly params:readonly V061Parameter[];
  readonly resultType?:V061TypeExpr;
  readonly constructors:readonly V061InductiveConstructor[];
  readonly terminatedBySemicolon:boolean;
  readonly span:SourceSpan;
}

export interface V061StructureField {
  readonly name:string;
  readonly type:V061TypeExpr;
  readonly binderKind:'explicit'|'implicit'|'instance';
  readonly span:SourceSpan;
}

export interface V061WhereDeclaration {
  readonly name:string;
  readonly params:readonly V061Parameter[];
  readonly resultType:V061TypeExpr;
  readonly body:V061Expr;
  readonly span:SourceSpan;
}

export interface V061ValueDeclaration {
  readonly kind:'const'|'def'|'function'|'theorem';
  readonly name:string;
  readonly params:readonly V061Parameter[];
  readonly resultType:V061TypeExpr;
  readonly body:V061Expr;
  readonly whereDeclarations?:readonly V061WhereDeclaration[];
  readonly terminatedBySemicolon:boolean;
  readonly span:SourceSpan;
}

export interface V061InstanceDeclaration {
  readonly kind:'instance';
  readonly name:string;
  readonly anonymous:boolean;
  readonly params:readonly V061Parameter[];
  readonly resultType:V061TypeExpr;
  readonly body:V061Expr;
  readonly terminatedBySemicolon:boolean;
  readonly span:SourceSpan;
}

export interface V061ClassDeclaration {
  readonly kind:'class';
  readonly name:string;
  readonly params:readonly V061Parameter[];
  readonly fields:readonly V061StructureField[];
  readonly terminatedBySemicolon:boolean;
  readonly span:SourceSpan;
}

export interface V061StructureDeclaration {
  readonly kind:'structure';
  readonly name:string;
  readonly params:readonly V061Parameter[];
  readonly fields:readonly V061StructureField[];
  readonly terminatedBySemicolon:boolean;
  readonly span:SourceSpan;
}

export type V061Declaration=
  | V061ValueDeclaration
  | V061StructureDeclaration
  | V061ClassDeclaration
  | V061InstanceDeclaration
  | V061InductiveDeclaration;

export interface V061Module {
  readonly kind:'v061-module';
  readonly declarations:readonly V061Declaration[];
  readonly featureIds:readonly ProofScriptFeatureId[];
}
