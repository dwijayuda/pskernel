import {
  Environment,
  LocalContext,
  TypeChecker,
  fvar,
  instantiate1,
  nameKey,
  nameToString,
  type Expr,
} from 'lean-ts-kernel';
import type {
  VerifiedIrExpr,
  VerifiedIrParameter,
  VerifiedIrTypeParameter,
} from '@proofscript/compiler-ir/verified';
import {
  classifyBinder,
  type ErasureScope,
} from './model.js';
import {eraseRuntimeType} from './type-erasure.js';
import {safeIdentifier} from './names.js';
import {eraseRuntimeApplication} from './app-erasure.js';
import {eraseRuntimeFVar} from './local-erasure.js';
import {eraseRuntimeProjection} from './projection-erasure.js';
export interface OpenedDefinition {
  readonly typeParameters:readonly VerifiedIrTypeParameter[];
  readonly parameters:readonly VerifiedIrParameter[];
  readonly resultType:import('@proofscript/compiler-ir/verified').VerifiedIrType;
  readonly body:VerifiedIrExpr;
}

function openBinder(
  scope:ErasureScope,
  binder:Extract<Expr,{kind:'lam'}>,
  typeBinder:Extract<Expr,{kind:'forall'}>,
  environment:Environment,
  typeIndex:number,
):{
  readonly scope:ErasureScope;
  readonly variable:Expr;
  readonly runtimeParameter?:VerifiedIrParameter;
  readonly typeParameter?:VerifiedIrTypeParameter;
} {
  const checker=new TypeChecker(environment,scope.localContext.clone());
  const kind=classifyBinder(typeBinder.type,checker);
  const localContext=scope.localContext.clone();
  const id=localContext.fresh(nameToString(typeBinder.name)||'arg');
  localContext.addLocal(
    id,
    typeBinder.name,
    typeBinder.type,
    typeBinder.binderInfo,
  );

  const runtimeLocals=new Map(scope.runtimeLocals);
  const typeLocals=new Map(scope.typeLocals);
  const erasedLocals=new Set(scope.erasedLocals);
  let runtimeParameter:VerifiedIrParameter|undefined;
  let typeParameter:VerifiedIrTypeParameter|undefined;

  if(kind==='type'){
    const name='T'+typeIndex;
    typeLocals.set(id,name);
    erasedLocals.add(id);
    typeParameter={name};
  }else if(kind==='proof'){
    erasedLocals.add(id);
  }else{
    const raw=nameToString(binder.name)||'arg';
    const name=safeIdentifier(raw,'arg');
    runtimeLocals.set(id,name);
    runtimeParameter={
      name,
      type:eraseRuntimeType(typeBinder.type,scope,environment),
    };
  }

  return {
    scope:{
      ...scope,
      localContext,
      runtimeLocals,
      typeLocals,
      erasedLocals,
    },
    variable:fvar(id),
    ...(runtimeParameter===undefined?{}:{runtimeParameter}),
    ...(typeParameter===undefined?{}:{typeParameter}),
  };
}

export function eraseRuntimeExpr(
  expr:Expr,
  scope:ErasureScope,
  environment:Environment,
):VerifiedIrExpr {
  switch(expr.kind){
    case 'mdata':
      return eraseRuntimeExpr(expr.expr,scope,environment);
    case 'lit':
      return {kind:'literal',value:expr.literal.value};
    case 'fvar':
      return eraseRuntimeFVar(expr,scope);
    case 'const':{
      const constructor=scope.inductivesByConstructor.get(
        nameKey(expr.name),
      );
      if(constructor!==undefined){
        if(constructor.numParams!==0){
          throw new Error(
            "PS_ERASE_GENERIC_CONSTRUCTOR_STUCK: '"+
            constructor.inductive+'.'+constructor.name+
            "' requires inferred type arguments before erasure",
          );
        }
        if(constructor.fields.length!==0){
          throw new Error(
            "PS_ERASE_CONSTRUCTOR_FUNCTION_UNSUPPORTED: '"+
            constructor.inductive+'.'+constructor.name+"'",
          );
        }
        return {
          kind:'constructor',
          inductive:constructor.inductive,
          constructor:constructor.name,
          typeArgs:[],
          fields:[],
        };
      }
      const known=scope.declarationNames.get(nameKey(expr.name));
      if(known!==undefined)return {kind:'var',name:known};
      const name=nameToString(expr.name);
      if(name==='Bool.true')return {kind:'literal',value:true};
      if(name==='Bool.false')return {kind:'literal',value:false};
      if(name==='Unit.unit')return {kind:'literal',value:undefined};
      throw new Error(
        "PS_ERASE_EXTERNAL_CONSTANT_UNSUPPORTED: '"+name+"'",
      );
    }
    case 'app':
      return eraseRuntimeApplication(
        expr,
        scope,
        environment,
        eraseRuntimeExpr,
      );
    case 'lam':{
      const checker=new TypeChecker(environment,scope.localContext.clone());
      const kind=classifyBinder(expr.type,checker);
      const localContext=scope.localContext.clone();
      const id=localContext.fresh(nameToString(expr.name)||'arg');
      localContext.addLocal(id,expr.name,expr.type,expr.binderInfo);
      const runtimeLocals=new Map(scope.runtimeLocals);
      const typeLocals=new Map(scope.typeLocals);
      const erasedLocals=new Set(scope.erasedLocals);
      const parameters:VerifiedIrParameter[]=[];

      if(kind==='runtime'){
        const name=safeIdentifier(nameToString(expr.name)||'arg','arg');
        runtimeLocals.set(id,name);
        parameters.push({
          name,
          type:eraseRuntimeType(expr.type,scope,environment),
        });
      }else{
        erasedLocals.add(id);
      }

      const body=eraseRuntimeExpr(
        instantiate1(expr.body,fvar(id)),
        {
          ...scope,
          localContext,
          runtimeLocals,
          typeLocals,
          erasedLocals,
        },
        environment,
      );
      return parameters.length===0
        ?body
        :{kind:'lambda',parameters,body};
    }
    case 'let':{
      const checker=new TypeChecker(environment,scope.localContext.clone());
      const kind=classifyBinder(expr.type,checker);
      if(kind!=='runtime'){
        return eraseRuntimeExpr(
          instantiate1(expr.body,expr.value),
          scope,
          environment,
        );
      }
      const value=eraseRuntimeExpr(expr.value,scope,environment);
      const localContext=scope.localContext.clone();
      const id=localContext.fresh(nameToString(expr.name)||'local');
      localContext.addLet(id,expr.name,expr.type,expr.value);
      const runtimeLocals=new Map(scope.runtimeLocals);
      const name=safeIdentifier(nameToString(expr.name)||'local','local');
      runtimeLocals.set(id,name);
      const body=eraseRuntimeExpr(
        instantiate1(expr.body,fvar(id)),
        {...scope,localContext,runtimeLocals},
        environment,
      );
      return {kind:'let',name,value,body};
    }
    case 'bvar':
      throw new Error('PS_ERASE_LOOSE_BVAR: executable term is not opened');
    case 'mvar':
      throw new Error('PS_ERASE_MVAR: checked core must not contain metavariables');
    case 'sort':
    case 'forall':
      throw new Error(
        "PS_ERASE_TYPE_TERM_AT_RUNTIME: '"+expr.kind+
        "' survives in executable code",
      );
    case 'proj':
      return eraseRuntimeProjection(
        expr,
        scope,
        environment,
        eraseRuntimeExpr,
      );
  }
}

export function openAndEraseDefinition(
  type:Expr,
  value:Expr,
  baseScope:ErasureScope,
  environment:Environment,
  definitionName:string,
):OpenedDefinition {
  let currentType=type;
  let currentValue=value;
  let scope=baseScope;
  const typeParameters:VerifiedIrTypeParameter[]=[];
  const parameters:VerifiedIrParameter[]=[];
  let typeIndex=0;

  while(currentType.kind==='forall'){
    if(currentValue.kind!=='lam'){
      throw new Error(
        'PS_ERASE_BINDER_MISMATCH: definition type/value binder mismatch',
      );
    }
    const opened=openBinder(
      scope,
      currentValue,
      currentType,
      environment,
      typeIndex,
    );
    scope=opened.scope;
    if(opened.typeParameter!==undefined){
      typeParameters.push(opened.typeParameter);
      typeIndex+=1;
    }
    if(opened.runtimeParameter!==undefined){
      parameters.push(opened.runtimeParameter);
    }
    currentType=instantiate1(currentType.body,opened.variable);
    currentValue=instantiate1(currentValue.body,opened.variable);
  }

  const executableScope:ErasureScope={
    ...scope,
    currentDefinition:{
      name:definitionName,
      runtimeParameters:parameters.map((parameter)=>parameter.name),
    },
  };
  return {
    typeParameters,
    parameters,
    resultType:eraseRuntimeType(currentType,scope,environment),
    body:eraseRuntimeExpr(
      currentValue,
      executableScope,
      environment,
    ),
  };
}
