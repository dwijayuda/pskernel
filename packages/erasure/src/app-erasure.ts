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

export type RuntimeExprEraser=(
  expr:Expr,
  scope:ErasureScope,
  environment:Environment,
)=>VerifiedIrExpr;

const natIntrinsics=new Map<
  string,
  'nat.add'|'nat.sub'|'nat.mul'|'nat.div'|'nat.mod'|'nat.eq'
>([
  ['Nat.add','nat.add'],
  ['Nat.sub','nat.sub'],
  ['Nat.mul','nat.mul'],
  ['Nat.div','nat.div'],
  ['Nat.mod','nat.mod'],
  ['Nat.beq','nat.eq'],
]);

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
    const reflected=view.args[1]!;
    const truth=view.args[2]!;
    if(
      typeArg.kind!=='const'
      ||nameToString(typeArg.name)!=='Bool'
      ||truth.kind!=='const'
      ||nameToString(truth.name)!=='Bool.true'
    ){
      throw new Error(
        'PS_ERASE_CONDITION_UNSUPPORTED: expected checked Bool condition coerced to Prop',
      );
    }
    return erase(reflected,scope,environment);
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

export function eraseRuntimeApplication(
  expr:Extract<Expr,{kind:'app'}>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr {
  const view=appView(expr);
  const recursor=tryEraseRuntimeRecursorApplication(
    expr,
    scope,
    environment,
    erase,
  );
  if(recursor!==undefined)return recursor;

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

  if(
    view.fn.kind==='const'
    &&nameToString(view.fn.name)==='Bool.not'
    &&view.args.length===1
  ){
    const equality=appView(view.args[0]!);
    if(
      equality.fn.kind==='const'
      &&nameToString(equality.fn.name)==='Nat.beq'
      &&equality.args.length===2
    ){
      return {
        kind:'intrinsic',
        operation:'nat.ne',
        args:equality.args.map((arg)=>erase(arg,scope,environment)),
      };
    }
    return {
      kind:'intrinsic',
      operation:'bool.not',
      args:[erase(view.args[0]!,scope,environment)],
    };
  }

  if(
    view.fn.kind==='const'
    &&(nameToString(view.fn.name)==='Bool.and'
      ||nameToString(view.fn.name)==='Bool.or')
    &&view.args.length===2
  ){
    return {
      kind:'intrinsic',
      operation:nameToString(view.fn.name)==='Bool.and'
        ?'bool.and'
        :'bool.or',
      args:view.args.map((arg)=>erase(arg,scope,environment)),
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
