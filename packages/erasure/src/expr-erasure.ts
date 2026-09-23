import {
  Environment,
  LocalContext,
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
  VerifiedIrParameter,
  VerifiedIrTypeParameter,
} from '@proofscript/compiler-ir/verified';
import {
  classifyBinder,
  type ErasureScope,
} from './model.js';
import {eraseRuntimeType} from './type-erasure.js';
import {safeIdentifier} from './names.js';

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

function eraseVerifiedCondition(
  proposition:Expr,
  scope:ErasureScope,
  environment:Environment,
):VerifiedIrExpr {
  const view=appView(proposition);
  if(view.fn.kind!=='const'||view.args.length!==4){
    throw new Error(
      'PS_ERASE_CONDITION_UNSUPPORTED: expected checked Nat relation',
    );
  }
  const head=nameToString(view.fn.name);
  const instance=view.args[1];
  if(instance?.kind!=='const'){
    throw new Error(
      'PS_ERASE_CONDITION_UNSUPPORTED: relation instance is not constant',
    );
  }
  const instanceName=nameToString(instance.name);
  let operation:'nat.le'|'nat.lt';
  if(head==='LE.le'&&instanceName==='instLENat'){
    operation='nat.le';
  }else if(head==='LT.lt'&&instanceName==='instLTNat'){
    operation='nat.lt';
  }else{
    throw new Error(
      "PS_ERASE_CONDITION_UNSUPPORTED: relation '"+head+
      "' with instance '"+instanceName+"' is not executable yet",
    );
  }
  return {
    kind:'intrinsic',
    operation,
    args:[
      eraseRuntimeExpr(view.args[2]!,scope,environment),
      eraseRuntimeExpr(view.args[3]!,scope,environment),
    ],
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
    case 'fvar':{
      const runtime=scope.runtimeLocals.get(expr.id);
      if(runtime!==undefined)return {kind:'var',name:runtime};
      if(scope.erasedLocals.has(expr.id)||scope.typeLocals.has(expr.id)){
        throw new Error(
          "PS_ERASE_ERASED_LOCAL_USED: erased local '"+expr.id+
          "' survives in executable code",
        );
      }
      throw new Error("PS_ERASE_UNKNOWN_LOCAL: '"+expr.id+"'");
    }
    case 'const':{
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
    case 'app':{
      const view=appView(expr);
      if(
        view.fn.kind==='const'
        &&nameToString(view.fn.name)==='ite'
        &&view.args.length===5
      ){
        return {
          kind:'if',
          condition:eraseVerifiedCondition(
            view.args[1]!,
            scope,
            environment,
          ),
          thenBranch:eraseRuntimeExpr(
            view.args[3]!,
            scope,
            environment,
          ),
          elseBranch:eraseRuntimeExpr(
            view.args[4]!,
            scope,
            environment,
          ),
        };
      }
      if(view.fn.kind==='const'){
        const intrinsic=new Map<string,'nat.add'|'nat.sub'|'nat.mul'>([
          ['Nat.add','nat.add'],
          ['Nat.sub','nat.sub'],
          ['Nat.mul','nat.mul'],
        ]).get(nameToString(view.fn.name));
        if(intrinsic!==undefined){
          if(view.args.length!==2){
            throw new Error(
              "PS_ERASE_INTRINSIC_ARITY: '"+intrinsic+
              "' expects two arguments",
            );
          }
          return {
            kind:'intrinsic',
            operation:intrinsic,
            args:view.args.map(
              (arg)=>eraseRuntimeExpr(arg,scope,environment),
            ),
          };
        }
      }
      const checker=new TypeChecker(environment,scope.localContext.clone());
      let fnType=checker.check(view.fn);
      const runtimeArgs:VerifiedIrExpr[]=[];
      for(const arg of view.args){
        const binder=checker.ensureForall(checker.whnf(fnType));
        const kind=classifyBinder(binder.type,checker);
        if(kind==='runtime'){
          runtimeArgs.push(eraseRuntimeExpr(arg,scope,environment));
        }
        fnType=instantiate1(binder.body,arg);
      }
      const fn=eraseRuntimeExpr(view.fn,scope,environment);
      return runtimeArgs.length===0
        ?fn
        :{kind:'call',fn,args:runtimeArgs};
    }
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
      throw new Error('PS_ERASE_PROJECTION_UNSUPPORTED');
  }
}

export function openAndEraseDefinition(
  type:Expr,
  value:Expr,
  baseScope:ErasureScope,
  environment:Environment,
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

  return {
    typeParameters,
    parameters,
    resultType:eraseRuntimeType(currentType,scope,environment),
    body:eraseRuntimeExpr(currentValue,scope,environment),
  };
}
