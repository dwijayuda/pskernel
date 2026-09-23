import {
  Environment,
  TypeChecker,
  appView,
  fvar,
  instantiate1,
  nameToString,
  type Expr,
} from 'lean-ts-kernel';
import type {VerifiedIrType} from '@proofscript/compiler-ir/verified';
import {
  classifyBinder,
  type ErasureScope,
} from './model.js';
import {safeIdentifier} from './names.js';

const primitives=new Map<string,VerifiedIrType>([
  ['Nat',{kind:'primitive',name:'bigint'}],
  ['Int',{kind:'primitive',name:'bigint'}],
  ['Bool',{kind:'primitive',name:'boolean'}],
  ['String',{kind:'primitive',name:'string'}],
  ['Unit',{kind:'primitive',name:'undefined'}],
]);

export function eraseRuntimeType(
  type:Expr,
  scope:ErasureScope,
  environment:Environment,
):VerifiedIrType {
  const checker=new TypeChecker(environment,scope.localContext.clone());
  const value=checker.whnf(type);

  if(value.kind==='fvar'){
    const parameter=scope.typeLocals.get(value.id);
    return parameter===undefined
      ?{kind:'unknown'}
      :{kind:'typeParameter',name:parameter};
  }

  if(value.kind==='const'){
    return primitives.get(nameToString(value.name))
      ??{
        kind:'named',
        name:safeIdentifier(nameToString(value.name).replaceAll('.','_'),'Type'),
        args:[],
      };
  }

  if(value.kind==='app'){
    const view=appView(value);
    if(view.fn.kind!=='const')return {kind:'unknown'};
    return {
      kind:'named',
      name:safeIdentifier(
        nameToString(view.fn.name).replaceAll('.','_'),
        'Type',
      ),
      args:view.args.map(
        (arg)=>eraseRuntimeType(arg,scope,environment),
      ),
    };
  }

  if(value.kind==='forall'){
    const binderKind=classifyBinder(value.type,checker);
    if(binderKind!=='runtime')return {kind:'unknown'};

    const nextContext=scope.localContext.clone();
    const id=nextContext.fresh('type');
    nextContext.addLocal(id,value.name,value.type,value.binderInfo);
    const runtimeLocals=new Map(scope.runtimeLocals);
    runtimeLocals.set(id,'_arg');
    const openedScope:ErasureScope={
      ...scope,
      localContext:nextContext,
      runtimeLocals,
    };
    return {
      kind:'function',
      parameters:[eraseRuntimeType(value.type,scope,environment)],
      result:eraseRuntimeType(
        instantiate1(value.body,fvar(id)),
        openedScope,
        environment,
      ),
    };
  }

  return {kind:'unknown'};
}
