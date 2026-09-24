import {
  Environment,
  appView,
  nameToString,
} from 'lean-ts-kernel';
import type {VerifiedIrExpr} from '@proofscript/compiler-ir/verified';
import type {ErasureScope} from './model.js';
import type {RuntimeExprEraser} from './app-erasure.js';

export function tryEraseBoolRecursorApplication(
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
  ){
    throw new Error(
      "PS_ERASE_BOOL_RECURSOR_UNSUPPORTED: expected canonical Bool.rec metadata",
    );
  }

  const majorIndex=recursor.numMotives+recursor.numMinors;
  if(view.args.length!==majorIndex+1){
    throw new Error(
      "PS_ERASE_BOOL_RECURSOR_ARITY: expected "+
      (majorIndex+1)+' arguments, got '+view.args.length,
    );
  }

  const falseIndex=recursor.rules.findIndex(
    (rule)=>nameToString(rule.ctor)==='Bool.false',
  );
  const trueIndex=recursor.rules.findIndex(
    (rule)=>nameToString(rule.ctor)==='Bool.true',
  );
  if(falseIndex<0||trueIndex<0){
    throw new Error(
      'PS_ERASE_BOOL_RECURSOR_RULES: expected Bool.false and Bool.true rules',
    );
  }

  const minorStart=recursor.numMotives;
  return {
    kind:'if',
    condition:erase(view.args[majorIndex]!,scope,environment),
    thenBranch:erase(
      view.args[minorStart+trueIndex]!,
      scope,
      environment,
    ),
    elseBranch:erase(
      view.args[minorStart+falseIndex]!,
      scope,
      environment,
    ),
  };
}
