export type VerifiedIrType =
  | {readonly kind:'unknown'}
  | {readonly kind:'typeParameter';readonly name:string}
  | {
      readonly kind:'primitive';
      readonly name:'bigint'|'boolean'|'string'|'undefined';
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

export type VerifiedIrExpr =
  | {readonly kind:'literal';readonly value:VerifiedIrLiteral}
  | {readonly kind:'var';readonly name:string}
  | {
      readonly kind:'intrinsic';
      readonly operation:'nat.add'|'nat.sub'|'nat.mul';
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
  readonly declarations:readonly VerifiedIrDeclaration[];
}

const identifierPattern=/^[A-Za-z_$][A-Za-z0-9_$]*$/u;

export function assertVerifiedIrIdentifier(name:string):void {
  if(!identifierPattern.test(name)){
    throw new Error("invalid verified IR identifier '"+name+"'");
  }
}

export function validateVerifiedIrModule(module:VerifiedIrModule):true {
  const declarations=new Set<string>();
  for(const declaration of module.declarations){
    assertVerifiedIrIdentifier(declaration.name);
    if(declarations.has(declaration.name)){
      throw new Error(
        "duplicate verified IR declaration '"+declaration.name+"'",
      );
    }
    declarations.add(declaration.name);

    const typeParameters=new Set<string>();
    for(const parameter of declaration.typeParameters){
      assertVerifiedIrIdentifier(parameter.name);
      if(typeParameters.has(parameter.name)){
        throw new Error(
          "duplicate verified IR type parameter '"+parameter.name+"'",
        );
      }
      typeParameters.add(parameter.name);
    }

    const runtimeParameters=new Set<string>();
    for(const parameter of declaration.parameters){
      assertVerifiedIrIdentifier(parameter.name);
      if(runtimeParameters.has(parameter.name)){
        throw new Error(
          "duplicate verified IR runtime parameter '"+parameter.name+"'",
        );
      }
      runtimeParameters.add(parameter.name);
    }
    validateVerifiedIrExpr(declaration.body);
  }
  return true;
}

export function validateVerifiedIrExpr(expr:VerifiedIrExpr):void {
  switch(expr.kind){
    case 'literal':
      return;
    case 'var':
      assertVerifiedIrIdentifier(expr.name);
      return;
    case 'intrinsic':
      if(expr.args.length!==2){
        throw new Error(
          "verified IR intrinsic '"+expr.operation+"' expects two arguments",
        );
      }
      for(const arg of expr.args)validateVerifiedIrExpr(arg);
      return;
    case 'lambda':
      for(const parameter of expr.parameters){
        assertVerifiedIrIdentifier(parameter.name);
      }
      validateVerifiedIrExpr(expr.body);
      return;
    case 'call':
      validateVerifiedIrExpr(expr.fn);
      for(const arg of expr.args)validateVerifiedIrExpr(arg);
      return;
    case 'let':
      assertVerifiedIrIdentifier(expr.name);
      validateVerifiedIrExpr(expr.value);
      validateVerifiedIrExpr(expr.body);
      return;
  }
}
