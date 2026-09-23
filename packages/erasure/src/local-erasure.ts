import type {Expr} from 'lean-ts-kernel';
import type {VerifiedIrExpr} from '@proofscript/compiler-ir/verified';
import type {ErasureScope} from './model.js';

export function eraseRuntimeFVar(
  expr:Extract<Expr,{kind:'fvar'}>,
  scope:ErasureScope,
):VerifiedIrExpr {
  const replacement=scope.runtimeExpressions?.get(expr.id);
  if(replacement!==undefined)return replacement;

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
