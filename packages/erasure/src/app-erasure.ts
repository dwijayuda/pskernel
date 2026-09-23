import {
  Environment,
  TypeChecker,
  appView,
  instantiate1,
  nameKey,
  nameToString,
  type Expr,
} from 'lean-ts-kernel';
import type {VerifiedIrExpr} from '@proofscript/compiler-ir/verified';
import {
  classifyBinder,
  type ErasureScope,
} from './model.js';

export type RuntimeExprEraser=(
  expr:Expr,
  scope:ErasureScope,
  environment:Environment,
)=>VerifiedIrExpr;

const natIntrinsics=new Map<
  string,
  'nat.add'|'nat.sub'|'nat.mul'
>([
  ['Nat.add','nat.add'],
  ['Nat.sub','nat.sub'],
  ['Nat.mul','nat.mul'],
]);

function eraseVerifiedCondition(
  proposition:Expr,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
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
      erase(view.args[2]!,scope,environment),
      erase(view.args[3]!,scope,environment),
    ],
  };
}

export function eraseRuntimeApplication(
  expr:Extract<Expr,{kind:'app'}>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr {
  const view=appView(expr);

  if(view.fn.kind==='const'){
    const structure=scope.structuresByConstructor.get(
      nameKey(view.fn.name),
    );
    if(structure!==undefined){
      if(view.args.length!==structure.fields.length){
        throw new Error(
          "PS_ERASE_STRUCTURE_ARITY: constructor for '"+
          structure.name+"' expected "+structure.fields.length+
          ' fields, got '+view.args.length,
        );
      }
      return {
        kind:'record',
        structure:structure.name,
        fields:structure.fields.map((field)=>({
          name:field.name,
          value:erase(
            view.args[field.sourceIndex]!,
            scope,
            environment,
          ),
        })),
      };
    }
  }

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
        erase,
      ),
      thenBranch:erase(view.args[3]!,scope,environment),
      elseBranch:erase(view.args[4]!,scope,environment),
    };
  }

  if(view.fn.kind==='const'){
    const intrinsic=natIntrinsics.get(nameToString(view.fn.name));
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
        args:view.args.map((arg)=>erase(arg,scope,environment)),
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
      runtimeArgs.push(erase(arg,scope,environment));
    }
    fnType=instantiate1(binder.body,arg);
  }

  const fn=erase(view.fn,scope,environment);
  return runtimeArgs.length===0
    ?fn
    :{kind:'call',fn,args:runtimeArgs};
}
