export type VerifiedIrType =
  | {readonly kind:'unknown'}
  | {readonly kind:'typeParameter';readonly name:string}
  | {
      readonly kind:'primitive';
      readonly name:'Nat'|'Int'|'Bool'|'String'|'Unit';
    }
  | {
      readonly kind:'function';
      readonly parameters:readonly VerifiedIrType[];
      readonly result:VerifiedIrType;
    }
  | {
      readonly kind:'named';
      readonly name:string;
      readonly args:readonly VerifiedIrType[];
    };

export type VerifiedIrLiteral=bigint|string|boolean|undefined;

export type VerifiedIrIntrinsicOperation =
  |'nat.add'|'nat.sub'|'nat.mul'|'nat.div'|'nat.mod'
  |'nat.eq'|'nat.ne'|'nat.le'|'nat.lt'
  |'bool.not'|'bool.and'|'bool.or'|'bool.eq'|'bool.ne';

export interface VerifiedIrStructureField {
  readonly name:string;
  readonly type:VerifiedIrType;
}

export interface VerifiedIrStructure {
  readonly name:string;
  readonly typeParameters?:readonly VerifiedIrTypeParameter[];
  readonly fields:readonly VerifiedIrStructureField[];
}

export interface VerifiedIrConstructorField {
  readonly name:string;
  readonly type:VerifiedIrType;
}

export interface VerifiedIrConstructor {
  readonly name:string;
  readonly fields:readonly VerifiedIrConstructorField[];
}

export interface VerifiedIrInductive {
  readonly name:string;
  readonly typeParameters?:readonly VerifiedIrTypeParameter[];
  readonly constructors:readonly VerifiedIrConstructor[];
}

export type VerifiedIrExpr =
  | {readonly kind:'literal';readonly value:VerifiedIrLiteral}
  | {readonly kind:'var';readonly name:string}
  | {
      readonly kind:'intrinsic';
      readonly operation:VerifiedIrIntrinsicOperation;
      readonly args:readonly VerifiedIrExpr[];
    }
  | {
      readonly kind:'lambda';
      readonly parameters:readonly {
        readonly name:string;
        readonly type:VerifiedIrType;
      }[];
      readonly body:VerifiedIrExpr;
    }
  | {
      readonly kind:'call';
      readonly fn:VerifiedIrExpr;
      readonly args:readonly VerifiedIrExpr[];
    }
  | {
      readonly kind:'let';
      readonly name:string;
      readonly value:VerifiedIrExpr;
      readonly body:VerifiedIrExpr;
    }
  | {
      readonly kind:'if';
      readonly condition:VerifiedIrExpr;
      readonly thenBranch:VerifiedIrExpr;
      readonly elseBranch:VerifiedIrExpr;
    }
  | {
      readonly kind:'record';
      readonly structure:string;
      readonly fields:readonly {
        readonly name:string;
        readonly value:VerifiedIrExpr;
      }[];
    }
  | {
      readonly kind:'projection';
      readonly target:VerifiedIrExpr;
      readonly field:string;
    }
  | {
      readonly kind:'constructor';
      readonly inductive:string;
      readonly constructor:string;
      readonly typeArgs?:readonly VerifiedIrType[];
      readonly fields:readonly {
        readonly name:string;
        readonly value:VerifiedIrExpr;
      }[];
    }
  | {
      readonly kind:'match';
      readonly inductive:string;
      readonly scrutinee:VerifiedIrExpr;
      readonly alternatives:readonly {
        readonly constructor:string;
        readonly bindings:readonly {
          readonly field:string;
          readonly name:string;
          readonly type:VerifiedIrType;
        }[];
        readonly body:VerifiedIrExpr;
      }[];
    };

export interface VerifiedIrTypeParameter {
  readonly name:string;
}

export interface VerifiedIrParameter {
  readonly name:string;
  readonly type:VerifiedIrType;
}

export interface VerifiedIrDeclaration {
  readonly name:string;
  readonly typeParameters:readonly VerifiedIrTypeParameter[];
  readonly parameters:readonly VerifiedIrParameter[];
  readonly resultType:VerifiedIrType;
  readonly body:VerifiedIrExpr;
}

export interface VerifiedIrModule {
  readonly kind:'proofscript-verified-ir';
  readonly structures?:readonly VerifiedIrStructure[];
  readonly inductives?:readonly VerifiedIrInductive[];
  readonly declarations:readonly VerifiedIrDeclaration[];
}
