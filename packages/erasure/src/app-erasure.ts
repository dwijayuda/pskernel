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
import {tryEraseRuntimeRecursorApplication} from './recursor-erasure.js';
import {eraseRuntimeType} from './type-erasure.js';
import {tryErasePrimitiveRuntimeApplication} from './primitive-app-erasure.js';
import {tryEraseRawPosApplication} from './raw-pos-erasure.js';

export type RuntimeExprEraser=(
  expr:Expr,
  scope:ErasureScope,
  environment:Environment,
)=>VerifiedIrExpr;

export function eraseRuntimeApplication(
  expr:Extract<Expr,{kind:'app'}>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr {
  const view=appView(expr);
  const primitive=tryErasePrimitiveRuntimeApplication(
    expr,
    scope,
    environment,
    erase,
  );
  if(primitive!==undefined)return primitive;

  const recursor=tryEraseRuntimeRecursorApplication(
    expr,
    scope,
    environment,
    erase,
  );
  if(recursor!==undefined)return recursor;

  const rawPos=tryEraseRawPosConstructor(
    expr,
    scope,
    environment,
    erase,
  );
  if(rawPos!==undefined)return rawPos;

  if(view.fn.kind==='const'){
    const constructor=scope.inductivesByConstructor.get(
      nameKey(view.fn.name),
    );
    if(constructor!==undefined){
      const expectedArity=constructor.numParams+constructor.fields.length;
      if(view.args.length!==expectedArity){
        throw new Error(
          "PS_ERASE_CONSTRUCTOR_ARITY: '"+constructor.inductive+'.'+
          constructor.name+"' expected "+expectedArity+
          ' arguments including erased parameters, got '+view.args.length,
        );
      }
      return {
        kind:'constructor',
        inductive:constructor.inductive,
        constructor:constructor.name,
        typeArgs:view.args.slice(0,constructor.numParams).map(
          (arg)=>eraseRuntimeType(arg,scope,environment),
        ),
        fields:constructor.fields.map((field)=>({
          name:field.name,
          value:erase(
            view.args[field.sourceIndex]!,
            scope,
            environment,
          ),
        })),
      };
    }

    const structure=scope.structuresByConstructor.get(
      nameKey(view.fn.name),
    );
    if(structure!==undefined){
      const expectedArity=structure.numParams+structure.fields.length;
      if(view.args.length!==expectedArity){
        throw new Error(
          "PS_ERASE_STRUCTURE_ARITY: constructor for '"+
          structure.name+"' expected "+expectedArity+
          ' total arguments, got '+view.args.length,
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
