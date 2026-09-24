import {
  Environment,
  appView,
  exprEq,
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

function namedApplication(
  expr:Expr,
  name:string,
  arity:number,
):ReturnType<typeof appView>|undefined {
  const view=appView(expr);
  return view.fn.kind==='const'
    &&nameToString(view.fn.name)===name
    &&view.args.length===arity
    ?view
    :undefined;
}

function synthesizedBoolEqualityOperands(
  expr:Expr,
):readonly [Expr,Expr]|undefined {
  const disjunction=namedApplication(expr,'Bool.or',2);
  if(disjunction===undefined)return undefined;
  const direct=namedApplication(disjunction.args[0]!,'Bool.and',2);
  const negated=namedApplication(disjunction.args[1]!,'Bool.and',2);
  if(direct===undefined||negated===undefined)return undefined;
  const leftNot=namedApplication(negated.args[0]!,'Bool.not',1);
  const rightNot=namedApplication(negated.args[1]!,'Bool.not',1);
  if(leftNot===undefined||rightNot===undefined)return undefined;
  if(
    !exprEq(direct.args[0]!,leftNot.args[0]!)
    ||!exprEq(direct.args[1]!,rightNot.args[0]!)
  )return undefined;
  return [direct.args[0]!,direct.args[1]!];
}

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

export function tryErasePrimitiveRuntimeApplication(
  expr:Extract<Expr,{kind:'app'}>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr|undefined {
  const view=appView(expr);
  const boolRecursor=tryErasePrimitiveBoolRecursor(
    view,
    scope,
    environment,
    erase,
  );
  if(boolRecursor!==undefined)return boolRecursor;

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
    &&nameToString(view.fn.name)==='Char.ofNat'
  ){
    if(view.args.length!==1){
      throw new Error(
        "PS_ERASE_INTRINSIC_ARITY: 'char.ofNat' expects one argument",
      );
    }
    return {
      kind:'intrinsic',
      operation:'char.ofNat',
      args:[erase(view.args[0]!,scope,environment)],
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
    const boolEquality=synthesizedBoolEqualityOperands(view.args[0]!);
    if(boolEquality!==undefined){
      return {
        kind:'intrinsic',
        operation:'bool.ne',
        args:boolEquality.map((arg)=>erase(arg,scope,environment)),
      };
    }
    return {
      kind:'intrinsic',
      operation:'bool.not',
      args:[erase(view.args[0]!,scope,environment)],
    };
  }

  const boolEquality=synthesizedBoolEqualityOperands(expr);
  if(boolEquality!==undefined){
    return {
      kind:'intrinsic',
      operation:'bool.eq',
      args:boolEquality.map((arg)=>erase(arg,scope,environment)),
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
  return undefined;
}
