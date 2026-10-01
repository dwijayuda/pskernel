import type {
  VerifiedIrExpr,
  VerifiedIrModule,
  VerifiedIrType,
} from './verified-model.js';
import {verifiedIrIntrinsicArity} from './verified-intrinsics.js';

const identifierPattern=/^[A-Za-z_$][A-Za-z0-9_$]*$/u;

export function assertVerifiedIrIdentifier(name:string):void {
  if(!identifierPattern.test(name)){
    throw new Error("invalid verified IR identifier '"+name+"'");
  }
}

function validateType(type:VerifiedIrType):void {
  switch(type.kind){
    case 'unknown':
    case 'primitive':
      return;
    case 'typeParameter':
      assertVerifiedIrIdentifier(type.name);
      return;
    case 'named':
      assertVerifiedIrIdentifier(type.name);
      for(const arg of type.args)validateType(arg);
      return;
    case 'function':
      for(const parameter of type.parameters)validateType(parameter);
      validateType(type.result);
      return;
  }
}

function validateNamedFields(
  fields:readonly {readonly name:string;readonly type:VerifiedIrType}[],
  label:string,
):void {
  const names=new Set<string>();
  for(const field of fields){
    assertVerifiedIrIdentifier(field.name);
    if(names.has(field.name)){
      throw new Error(
        "duplicate verified IR "+label+" field '"+field.name+"'",
      );
    }
    names.add(field.name);
    validateType(field.type);
  }
}

export function validateVerifiedIrModule(
  module:VerifiedIrModule,
):true {
  const valueNames=new Set<string>();
  for(const item of module.imports??[]){
    assertVerifiedIrIdentifier(item.localName);
    assertVerifiedIrIdentifier(item.importedName);
    if(item.source.length===0){
      throw new Error('verified IR external import source must be non-empty');
    }
    if(valueNames.has(item.localName)){
      throw new Error(
        "duplicate verified IR value '"+item.localName+"'",
      );
    }
    valueNames.add(item.localName);
    validateType(item.type);
  }

    const typeNames=new Set<string>();
  for(const structure of module.structures??[]){
    assertVerifiedIrIdentifier(structure.name);
    if(typeNames.has(structure.name)){
      throw new Error(
        "duplicate verified IR type '"+structure.name+"'",
      );
    }
    typeNames.add(structure.name);
    const structureTypeParameters=new Set<string>();
    for(const parameter of structure.typeParameters??[]){
      assertVerifiedIrIdentifier(parameter.name);
      if(structureTypeParameters.has(parameter.name)){
        throw new Error(
          "duplicate verified IR structure type parameter '"+
          parameter.name+"'",
        );
      }
      structureTypeParameters.add(parameter.name);
    }
    validateNamedFields(structure.fields,'structure');
  }

  for(const inductive of module.inductives??[]){
    assertVerifiedIrIdentifier(inductive.name);
    if(typeNames.has(inductive.name)){
      throw new Error(
        "duplicate verified IR type '"+inductive.name+"'",
      );
    }
    typeNames.add(inductive.name);
    const typeParameters=new Set<string>();
    for(const parameter of inductive.typeParameters??[]){
      assertVerifiedIrIdentifier(parameter.name);
      if(typeParameters.has(parameter.name)){
        throw new Error(
          "duplicate verified IR inductive type parameter '"+
          parameter.name+"'",
        );
      }
      typeParameters.add(parameter.name);
    }
    const constructors=new Set<string>();
    for(const constructor of inductive.constructors){
      assertVerifiedIrIdentifier(constructor.name);
      if(constructors.has(constructor.name)){
        throw new Error(
          "duplicate verified IR constructor '"+constructor.name+"'",
        );
      }
      constructors.add(constructor.name);
      validateNamedFields(constructor.fields,'constructor');
    }
  }

  const declarations=new Set<string>();
  for(const declaration of module.declarations){
    assertVerifiedIrIdentifier(declaration.name);
    if(declarations.has(declaration.name)||valueNames.has(declaration.name)){
      throw new Error(
        "duplicate verified IR value '"+declaration.name+"'",
      );
    }
    declarations.add(declaration.name);
    valueNames.add(declaration.name);
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
      validateType(parameter.type);
    }
    validateType(declaration.resultType);
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
    case 'intrinsic':{
      const expectedArity=verifiedIrIntrinsicArity(expr.operation);
      if(expr.args.length!==expectedArity){
        throw new Error(
          "verified IR intrinsic '"+expr.operation+
          "' expects "+expectedArity+" argument"+
          (expectedArity===1?'':'s'),
        );
      }
      for(const arg of expr.args)validateVerifiedIrExpr(arg);
      return;
    }
    case 'lambda':
      for(const parameter of expr.parameters){
        assertVerifiedIrIdentifier(parameter.name);
        validateType(parameter.type);
      }
      validateVerifiedIrExpr(expr.body);
      return;
    case 'call':
      validateVerifiedIrExpr(expr.fn);
      for(const typeArg of expr.typeArgs??[])validateType(typeArg);
      for(const arg of expr.args)validateVerifiedIrExpr(arg);
      return;
    case 'let':
      assertVerifiedIrIdentifier(expr.name);
      validateVerifiedIrExpr(expr.value);
      validateVerifiedIrExpr(expr.body);
      return;
    case 'if':
      validateVerifiedIrExpr(expr.condition);
      validateVerifiedIrExpr(expr.thenBranch);
      validateVerifiedIrExpr(expr.elseBranch);
      return;
    case 'record':
      assertVerifiedIrIdentifier(expr.structure);
      validateValueFields(expr.fields,'record');
      return;
    case 'projection':
      assertVerifiedIrIdentifier(expr.field);
      validateVerifiedIrExpr(expr.target);
      return;
    case 'constructor':
      assertVerifiedIrIdentifier(expr.inductive);
      assertVerifiedIrIdentifier(expr.constructor);
      for(const typeArg of expr.typeArgs??[])validateType(typeArg);
      validateValueFields(expr.fields,'constructor value');
      return;
    case 'match':{
      assertVerifiedIrIdentifier(expr.inductive);
      validateVerifiedIrExpr(expr.scrutinee);
      const constructors=new Set<string>();
      for(const alternative of expr.alternatives){
        assertVerifiedIrIdentifier(alternative.constructor);
        if(constructors.has(alternative.constructor)){
          throw new Error(
            "duplicate verified IR match constructor '"+
            alternative.constructor+"'",
          );
        }
        constructors.add(alternative.constructor);
        const names=new Set<string>();
        for(const binding of alternative.bindings){
          assertVerifiedIrIdentifier(binding.field);
          assertVerifiedIrIdentifier(binding.name);
          validateType(binding.type);
          if(names.has(binding.name)){
            throw new Error(
              "duplicate verified IR match binder '"+binding.name+"'",
            );
          }
          names.add(binding.name);
        }
        validateVerifiedIrExpr(alternative.body);
      }
      return;
    }
  }
}

function validateValueFields(
  fields:readonly {readonly name:string;readonly value:VerifiedIrExpr}[],
  label:string,
):void {
  const names=new Set<string>();
  for(const field of fields){
    assertVerifiedIrIdentifier(field.name);
    if(names.has(field.name)){
      throw new Error(
        "duplicate verified IR "+label+" field '"+field.name+"'",
      );
    }
    names.add(field.name);
    validateVerifiedIrExpr(field.value);
  }
}
