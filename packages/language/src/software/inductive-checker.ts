import type {V061Expr,V061InductiveDeclaration,V061TypeExpr} from '@proofscript/syntax';
import type {CheckSoftwareExpr,SoftwareExpressionContext} from './check-context.js';
import type {
  CheckedSoftwareConstructorRef,
  CheckedSoftwareExpr,
  CheckedSoftwareInductive,
  NominalSoftwareType,
} from './types.js';
import {softwareTypeEquals,softwareTypeToString} from './types.js';
import {asSoftwareType} from './type-conversion.js';

function isTypeSort(type:V061TypeExpr):boolean {
  if(type.kind==='group')return isTypeSort(type.value);
  return type.kind==='named'&&type.name==='Type';
}

export function collectInductives(
  declarations:readonly V061InductiveDeclaration[],
  nominalNames:ReadonlySet<string>,
):Map<string,CheckedSoftwareInductive> {
  const inductives=new Map<string,CheckedSoftwareInductive>();

  for(const declaration of declarations){
    if(declaration.params.length>0){
      throw new Error(
        "PS_CHECK_INDUCTIVE_PARAMS_UNSUPPORTED: '"+declaration.name+
        "' has type parameters; the executable ADT subset is monomorphic",
      );
    }
    if(declaration.resultType!==undefined&&!isTypeSort(declaration.resultType)){
      throw new Error(
        "PS_CHECK_INDEXED_INDUCTIVE_UNSUPPORTED: '"+declaration.name+
        "' has a non-Type result sort",
      );
    }

    const seenConstructors=new Set<string>();
    const constructors=declaration.constructors.map((constructor)=>{
      if(seenConstructors.has(constructor.name)){
        throw new Error(
          "PS_CHECK_DUPLICATE_CONSTRUCTOR: duplicate constructor '"+constructor.name+
          "' in inductive '"+declaration.name+"'",
        );
      }
      seenConstructors.add(constructor.name);

      const seenFields=new Set<string>();
      const fields=constructor.params.map((field)=>{
        if(seenFields.has(field.name)){
          throw new Error(
            "PS_CHECK_DUPLICATE_CONSTRUCTOR_FIELD: duplicate field '"+field.name+
            "' in constructor '"+declaration.name+'.'+constructor.name+"'",
          );
        }
        seenFields.add(field.name);
        return {name:field.name,type:asSoftwareType(field.type,nominalNames)};
      });
      return {
        name:constructor.name,
        qualifiedName:declaration.name+'.'+constructor.name,
        fields,
      };
    });

    inductives.set(declaration.name,{name:declaration.name,constructors});
  }

  return inductives;
}

export function collectConstructorIndex(
  inductives:ReadonlyMap<string,CheckedSoftwareInductive>,
):Map<string,CheckedSoftwareConstructorRef> {
  const constructors=new Map<string,CheckedSoftwareConstructorRef>();
  for(const inductive of inductives.values()){
    for(const constructor of inductive.constructors){
      constructors.set(constructor.qualifiedName,{inductive,constructor});
    }
  }
  return constructors;
}

export function tryCheckConstructorReference(
  name:string,
  context:SoftwareExpressionContext,
):CheckedSoftwareExpr|undefined {
  const ref=context.constructors.get(name);
  if(ref===undefined)return undefined;
  if(ref.constructor.fields.length>0){
    throw new Error(
      "PS_CHECK_CONSTRUCTOR_ARITY: '"+name+"' expects "+
      ref.constructor.fields.length+' arguments',
    );
  }
  return {
    kind:'constructor',
    inductive:ref.inductive.name,
    constructor:ref.constructor.name,
    fields:[],
    resultType:{kind:'nominal',name:ref.inductive.name},
  };
}

export function tryCheckConstructorCall(
  expr:Extract<V061Expr,{kind:'call'}>,
  context:SoftwareExpressionContext,
  check:CheckSoftwareExpr,
):CheckedSoftwareExpr|undefined {
  const ref=context.constructors.get(expr.callee);
  if(ref===undefined)return undefined;
  if(expr.args.length!==ref.constructor.fields.length){
    throw new Error(
      "PS_CHECK_CONSTRUCTOR_ARITY: '"+expr.callee+"' expects "+
      ref.constructor.fields.length+' arguments, got '+expr.args.length,
    );
  }

  const fields=ref.constructor.fields.map((field,index)=>{
    const value=check(expr.args[index]!,context,field.type);
    if(!softwareTypeEquals(value.resultType,field.type)){
      throw new Error(
        "PS_CHECK_CONSTRUCTOR_TYPE: field '"+field.name+"' of '"+expr.callee+
        "' expects "+softwareTypeToString(field.type)+', got '+
        softwareTypeToString(value.resultType),
      );
    }
    return {name:field.name,value};
  });

  return {
    kind:'constructor',
    inductive:ref.inductive.name,
    constructor:ref.constructor.name,
    fields,
    resultType:{kind:'nominal',name:ref.inductive.name} as NominalSoftwareType,
  };
}
