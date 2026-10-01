import {
  Environment,
  appView,
  nameToString,
  type Expr,
} from 'lean-ts-kernel';
import type {VerifiedIrExpr} from '@proofscript/compiler-ir/verified';
import type {ErasureScope} from './model.js';

type RuntimeExprEraser=(
  expr:Expr,
  scope:ErasureScope,
  environment:Environment,
)=>VerifiedIrExpr;

function tryErasePrimitiveBoolRecursor(
  view:ReturnType<typeof appView>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr|undefined {
  if(
    view.fn.kind!=='const'
    ||nameToString(view.fn.name)!=='Bool.rec'
  )return undefined;

  const recursor=environment.find(view.fn.name);
  if(
    recursor?.kind!=='recursor'
    ||recursor.numParams!==0
    ||recursor.numIndices!==0
    ||recursor.numMotives!==1
    ||recursor.numMinors!==2
    ||recursor.rules.length!==2
    ||nameToString(recursor.rules[0]!.ctor)!=='Bool.false'
    ||nameToString(recursor.rules[1]!.ctor)!=='Bool.true'
  ){
    throw new Error(
      'PS_ERASE_BOOL_RECURSOR_METADATA: Bool.rec does not match the admitted primitive Bool recursor',
    );
  }
  if(view.fn.levels.length!==1||view.args.length!==4){
    throw new Error(
      'PS_ERASE_BOOL_RECURSOR_ARITY: expected motive, false branch, true branch, and major',
    );
  }
  return {
    kind:'if',
    condition:erase(view.args[3]!,scope,environment),
    thenBranch:erase(view.args[2]!,scope,environment),
    elseBranch:erase(view.args[1]!,scope,environment),
  };
}

function eraseVerifiedCondition(
  proposition:Expr,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr {
  const view=appView(proposition);
  if(view.fn.kind!=='const'){
    throw new Error(
      'PS_ERASE_CONDITION_UNSUPPORTED: expected checked Nat relation',
    );
  }
  const head=nameToString(view.fn.name);
  if(head==='Eq'){
    if(view.args.length!==3){
      throw new Error(
        'PS_ERASE_CONDITION_UNSUPPORTED: malformed checked equality coercion',
      );
    }
    const typeArg=view.args[0]!;
    const left=view.args[1]!;
    const right=view.args[2]!;
    if(typeArg.kind!=='const'){
      throw new Error(
        'PS_ERASE_CONDITION_UNSUPPORTED: equality type is not constant',
      );
    }
    const equalityType=nameToString(typeArg.name);
    if(equalityType==='String'){
      return {
        kind:'intrinsic',
        operation:'string.eq',
        args:[
          erase(left,scope,environment),
          erase(right,scope,environment),
        ],
      };
    }
    if(
      equalityType!=='Bool'
      ||right.kind!=='const'
      ||nameToString(right.name)!=='Bool.true'
    ){
      throw new Error(
        'PS_ERASE_CONDITION_UNSUPPORTED: equality condition is not executable yet',
      );
    }
    return erase(left,scope,environment);
  }

  if(view.args.length!==4){
    throw new Error(
      'PS_ERASE_CONDITION_UNSUPPORTED: expected checked Nat relation',
    );
  }
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

function eraseCheckedIte(
  view:ReturnType<typeof appView>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr|undefined {
  if(
    view.fn.kind!=='const'
    ||nameToString(view.fn.name)!=='ite'
    ||view.args.length!==5
  )return undefined;

  const condition=eraseVerifiedCondition(
    view.args[1]!,
    scope,
    environment,
    erase,
  );
  const thenBranch=erase(view.args[3]!,scope,environment);
  const elseBranch=erase(view.args[4]!,scope,environment);
  if(
    thenBranch.kind==='literal'
    &&thenBranch.value===true
    &&elseBranch.kind==='literal'
    &&elseBranch.value===false
  )return condition;
  if(
    thenBranch.kind==='literal'
    &&thenBranch.value===false
    &&elseBranch.kind==='literal'
    &&elseBranch.value===true
  ){
    return {
      kind:'intrinsic',
      operation:'bool.not',
      args:[condition],
    };
  }
  return {kind:'if',condition,thenBranch,elseBranch};
}

export function tryEraseCheckedControlApplication(
  expr:Extract<Expr,{kind:'app'}>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr|undefined {
  const view=appView(expr);
  return tryErasePrimitiveBoolRecursor(
    view,
    scope,
    environment,
    erase,
  )??eraseCheckedIte(view,scope,environment,erase);
}
