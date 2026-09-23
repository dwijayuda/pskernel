import {
  Environment,
  TypeChecker,
  appView,
  fvar,
  instantiate1,
  nameKey,
  nameToString,
  type Expr,
} from 'lean-ts-kernel';
import type {
  VerifiedIrExpr,
} from '@proofscript/compiler-ir/verified';
import {
  classifyBinder,
  type ErasureScope,
  type RuntimeConstructorInfo,
  type RuntimeInductiveInfo,
} from './model.js';
import {safeIdentifier} from './names.js';
import {eraseRuntimeType} from './type-erasure.js';
import {substituteVerifiedType} from './verified-type-substitution.js';
import type {RuntimeExprEraser} from './app-erasure.js';

function freshBranchName(
  raw:string,
  used:Set<string>,
  index:number,
):string {
  const base=safeIdentifier(raw,'field'+index);
  let candidate=base;
  let suffix=0;
  while(used.has(candidate)){
    suffix+=1;
    candidate=base+'_'+suffix;
  }
  used.add(candidate);
  return candidate;
}

function eraseMinor(
  minor:Expr,
  constructor:RuntimeConstructorInfo,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
  substitutions:ReadonlyMap<
    string,
    import('@proofscript/compiler-ir/verified').VerifiedIrType
  >,
):Extract<VerifiedIrExpr,{kind:'match'}>['alternatives'][number] {
  let cursor=minor;
  let branchScope=scope;
  const used=new Set(branchScope.runtimeLocals.values());
  const bindings:{
    readonly field:string;
    readonly name:string;
    readonly type:import('@proofscript/compiler-ir/verified').VerifiedIrType;
  }[]=[];

  for(let index=0;index<constructor.fields.length;index+=1){
    if(cursor.kind!=='lam'){
      throw new Error(
        "PS_ERASE_MATCH_MINOR_ARITY: constructor '"+
        constructor.inductive+'.'+constructor.name+
        "' minor is missing field lambda "+index,
      );
    }
    const checker=new TypeChecker(
      environment,
      branchScope.localContext.clone(),
    );
    if(classifyBinder(cursor.type,checker)!=='runtime'){
      throw new Error(
        "PS_ERASE_MATCH_FIELD_UNSUPPORTED: constructor '"+
        constructor.inductive+'.'+constructor.name+
        "' field "+index+" is not runtime-level",
      );
    }

    const sourceField=constructor.fields[index]!;
    const binderName=freshBranchName(
      nameToString(cursor.name),
      used,
      index,
    );
    const localContext=branchScope.localContext.clone();
    const id=localContext.fresh(binderName);
    localContext.addLocal(
      id,
      cursor.name,
      cursor.type,
      cursor.binderInfo,
    );
    const runtimeLocals=new Map(branchScope.runtimeLocals);
    runtimeLocals.set(id,binderName);
    branchScope={...branchScope,localContext,runtimeLocals};
    bindings.push({
      field:sourceField.name,
      name:binderName,
      type:substituteVerifiedType(
        sourceField.type,
        substitutions,
      ),
    });
    cursor=instantiate1(cursor.body,fvar(id));
  }

  return {
    constructor:constructor.name,
    bindings,
    body:erase(cursor,branchScope,environment),
  };
}

export function tryEraseRuntimeRecursorApplication(
  expr:Extract<Expr,{kind:'app'}>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr|undefined {
  const view=appView(expr);
  if(view.fn.kind!=='const')return undefined;

  const inductive:RuntimeInductiveInfo|undefined=
    scope.inductivesByRecursor.get(nameKey(view.fn.name));
  if(inductive===undefined)return undefined;

  const recursor=environment.find(view.fn.name);
  if(
    recursor?.kind!=='recursor'
    ||recursor.numParams!==inductive.numParams
    ||recursor.numIndices!==0
    ||recursor.numMotives!==1
    ||recursor.numMinors!==inductive.constructors.length
  ){
    throw new Error(
      "PS_ERASE_MATCH_RECURSOR_UNSUPPORTED: '"+
      nameToString(view.fn.name)+"'",
    );
  }

  const majorIndex=
    recursor.numParams+
    recursor.numMotives+
    recursor.numMinors+
    recursor.numIndices;
  if(view.args.length!==majorIndex+1){
    throw new Error(
      "PS_ERASE_MATCH_RECURSOR_ARITY: '"+
      nameToString(view.fn.name)+"' expected "+
      (majorIndex+1)+' arguments, got '+view.args.length,
    );
  }

  const typeArgs=view.args
    .slice(0,recursor.numParams)
    .map((arg)=>eraseRuntimeType(arg,scope,environment));
  if(typeArgs.length!==inductive.typeParameters.length){
    throw new Error(
      "PS_ERASE_MATCH_PARAMETER_ARITY: '"+
      nameToString(view.fn.name)+"' expected "+
      inductive.typeParameters.length+' type parameters, got '+
      typeArgs.length,
    );
  }
  const substitutions=new Map(
    inductive.typeParameters.map((parameter,index)=>[
      parameter.name,
      typeArgs[index]!,
    ] as const),
  );

  const minorStart=recursor.numParams+recursor.numMotives;
  const alternatives=inductive.constructors.map(
    (constructor,index)=>eraseMinor(
      view.args[minorStart+index]!,
      constructor,
      scope,
      environment,
      erase,
      substitutions,
    ),
  );

  return {
    kind:'match',
    inductive:inductive.name,
    scrutinee:erase(view.args[majorIndex]!,scope,environment),
    alternatives,
  };
}
