import type {
  CheckedSoftwareExpr,
  CheckedSoftwareModule,
  SoftwareType,
} from '@proofscript/language';

export type SoftwareIrType=SoftwareType;

export interface SoftwareIrStructure {
  readonly name:string;
  readonly fields:readonly {readonly name:string;readonly type:SoftwareIrType}[];
}

export interface SoftwareIrConstructor {
  readonly name:string;
  readonly fields:readonly {readonly name:string;readonly type:SoftwareIrType}[];
}

export interface SoftwareIrInductive {
  readonly name:string;
  readonly constructors:readonly SoftwareIrConstructor[];
}

export type SoftwareIrPattern =
  | {readonly kind:'bool';readonly value:boolean}
  | {readonly kind:'wildcard'}
  | {
      readonly kind:'constructor';
      readonly inductive:string;
      readonly constructor:string;
      readonly binders:readonly {
        readonly name:string;
        readonly field:string;
        readonly type:SoftwareIrType;
      }[];
    };

export interface SoftwareIrMatchAlternative {
  readonly pattern:SoftwareIrPattern;
  readonly body:SoftwareIrExpr;
}

export type SoftwareIrExpr =
  | {readonly kind:'literal';readonly value:bigint|string|boolean|undefined;readonly type:SoftwareIrType}
  | {readonly kind:'var';readonly name:string;readonly type:SoftwareIrType}
  | {
      readonly kind:'projection';
      readonly target:SoftwareIrExpr;
      readonly field:string;
      readonly type:SoftwareIrType;
    }
  | {
      readonly kind:'record';
      readonly structure:string;
      readonly fields:readonly {readonly name:string;readonly value:SoftwareIrExpr}[];
      readonly type:SoftwareIrType;
    }
  | {
      readonly kind:'constructor';
      readonly inductive:string;
      readonly constructor:string;
      readonly fields:readonly {readonly name:string;readonly value:SoftwareIrExpr}[];
      readonly type:SoftwareIrType;
    }
  | {
      readonly kind:'call';
      readonly callee:string;
      readonly args:readonly SoftwareIrExpr[];
      readonly callStyle:'direct'|'curried';
      readonly type:SoftwareIrType;
    }
  | {
      readonly kind:'lambda';
      readonly binders:readonly {readonly name:string;readonly type:SoftwareIrType}[];
      readonly body:SoftwareIrExpr;
      readonly type:SoftwareIrType;
    }
  | {readonly kind:'unary';readonly operator:'!';readonly operand:SoftwareIrExpr;readonly type:'Bool'}
  | {readonly kind:'binary';readonly operator:string;readonly left:SoftwareIrExpr;readonly right:SoftwareIrExpr;readonly type:SoftwareIrType}
  | {readonly kind:'if';readonly condition:SoftwareIrExpr;readonly thenBranch:SoftwareIrExpr;readonly elseBranch:SoftwareIrExpr;readonly type:SoftwareIrType}
  | {
      readonly kind:'match';
      readonly scrutinee:SoftwareIrExpr;
      readonly alternatives:readonly SoftwareIrMatchAlternative[];
      readonly type:SoftwareIrType;
    }
  | {
      readonly kind:'let';
      readonly name:string;
      readonly bindingType:SoftwareIrType;
      readonly value:SoftwareIrExpr;
      readonly body:SoftwareIrExpr;
      readonly type:SoftwareIrType;
    };

export interface SoftwareIrParameter {
  readonly name:string;
  readonly type:SoftwareIrType;
}

export interface SoftwareIrLocalDeclaration {
  readonly name:string;
  readonly params:readonly SoftwareIrParameter[];
  readonly resultType:SoftwareIrType;
  readonly body:SoftwareIrExpr;
}

export interface SoftwareIrDeclaration {
  readonly name:string;
  readonly params:readonly SoftwareIrParameter[];
  readonly resultType:SoftwareIrType;
  readonly body:SoftwareIrExpr;
  readonly whereDeclarations?:readonly SoftwareIrLocalDeclaration[];
}

export interface SoftwareIrModule {
  readonly kind:'proofscript-software-ir';
  readonly structures:readonly SoftwareIrStructure[];
  readonly inductives:readonly SoftwareIrInductive[];
  readonly declarations:readonly SoftwareIrDeclaration[];
}

function lowerExpr(expr:CheckedSoftwareExpr):SoftwareIrExpr {
  switch(expr.kind){
    case 'nat':return {kind:'literal',value:expr.value,type:expr.resultType};
    case 'string':return {kind:'literal',value:expr.value,type:'String'};
    case 'bool':return {kind:'literal',value:expr.value,type:'Bool'};
    case 'unit':return {kind:'literal',value:undefined,type:'Unit'};
    case 'reference':return {kind:'var',name:expr.name,type:expr.resultType};
    case 'projection':
      return {kind:'projection',target:lowerExpr(expr.target),field:expr.field,type:expr.resultType};
    case 'record':
      return {
        kind:'record',
        structure:expr.structure,
        fields:expr.fields.map((field)=>({name:field.name,value:lowerExpr(field.value)})),
        type:expr.resultType,
      };
    case 'constructor':
      return {
        kind:'constructor',
        inductive:expr.inductive,
        constructor:expr.constructor,
        fields:expr.fields.map((field)=>({name:field.name,value:lowerExpr(field.value)})),
        type:expr.resultType,
      };
    case 'call':
      return {
        kind:'call',
        callee:expr.callee,
        args:expr.args.map(lowerExpr),
        callStyle:expr.callStyle,
        type:expr.resultType,
      };
    case 'match':
      return {
        kind:'match',
        scrutinee:lowerExpr(expr.scrutinee),
        alternatives:expr.alternatives.map((alternative)=>({
          pattern:alternative.pattern,
          body:lowerExpr(alternative.body),
        })),
        type:expr.resultType,
      };
    case 'lambda':
      return {
        kind:'lambda',
        binders:expr.binders.map((binder)=>({name:binder.name,type:binder.type})),
        body:lowerExpr(expr.body),
        type:expr.resultType,
      };
    case 'unary':
      return {kind:'unary',operator:expr.operator,operand:lowerExpr(expr.operand),type:'Bool'};
    case 'binary':
      return {kind:'binary',operator:expr.operator,left:lowerExpr(expr.left),right:lowerExpr(expr.right),type:expr.resultType};
    case 'if':
      return {
        kind:'if',
        condition:lowerExpr(expr.condition),
        thenBranch:lowerExpr(expr.thenBranch),
        elseBranch:lowerExpr(expr.elseBranch),
        type:expr.resultType,
      };
    case 'let':
      return {
        kind:'let',
        name:expr.name,
        bindingType:expr.declaredType??expr.value.resultType,
        value:lowerExpr(expr.value),
        body:lowerExpr(expr.body),
        type:expr.resultType,
      };
  }
}

export function lowerCheckedSoftwareModule(module:CheckedSoftwareModule):SoftwareIrModule {
  return {
    kind:'proofscript-software-ir',
    structures:module.structures.map((structure)=>({
      name:structure.name,
      fields:structure.fields.map((field)=>({name:field.name,type:field.type})),
    })),
    inductives:module.inductives.map((inductive)=>({
      name:inductive.name,
      constructors:inductive.constructors.map((constructor)=>({
        name:constructor.name,
        fields:constructor.fields.map((field)=>({name:field.name,type:field.type})),
      })),
    })),
    declarations:module.declarations.map((decl)=>({
      name:decl.name,
      params:decl.params.map((param)=>({name:param.name,type:param.type})),
      resultType:decl.resultType,
      body:lowerExpr(decl.body),
      whereDeclarations:(decl.whereDeclarations??[]).map((local)=>({
        name:local.name,
        params:local.params.map((param)=>({name:param.name,type:param.type})),
        resultType:local.resultType,
        body:lowerExpr(local.body),
      })),
    })),
  };
}
