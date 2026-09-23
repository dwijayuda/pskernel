import type {
  V061Expr,
  V061Pattern,
} from '@proofscript/syntax';
import {
  TypeChecker,
  abstractFVar,
  appView,
  fvar,
  instantiate1,
  lam,
  nameEq,
  nameFromDotted,
  nameToString,
  type Expr,
  type Name,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';


function hasConstant(
  expr:Expr,
  target:Name,
):boolean {
  switch(expr.kind){
    case 'const':return nameEq(expr.name,target);
    case 'app':return hasConstant(expr.fn,target)||hasConstant(expr.arg,target);
    case 'lam':
    case 'forall':
      return hasConstant(expr.type,target)||hasConstant(expr.body,target);
    case 'let':
      return hasConstant(expr.type,target)
        ||hasConstant(expr.value,target)
        ||hasConstant(expr.body,target);
    case 'mdata':
    case 'proj':
      return hasConstant(expr.expr,target);
    default:return false;
  }
}

function isDirectRecursiveField(
  type:Expr,
  inductive:Name,
  parameterArgs:readonly Expr[],
  checker:TypeChecker,
):boolean {
  const view=appView(checker.whnf(type));
  if(view.fn.kind!=='const'||!nameEq(view.fn.name,inductive))return false;
  if(view.args.length!==parameterArgs.length)return false;
  return view.args.every(
    (arg,index)=>checker.isDefEq(arg,parameterArgs[index]!),
  );
}

export type MatchTermElaborator=(
  expr:V061Expr,
  context:V061CoreElabContext,
  expected?:Expr,
)=>ElaboratedCoreTerm;

export function elaborateV061MatchMinor(
  alternative:Extract<
    Extract<V061Expr,{kind:'match'}>['alternatives'][number],
    {pattern:V061Pattern}
  >,
  constructorName:Name,
  parameterArgs:readonly Expr[],
  context:V061CoreElabContext,
  expected:Expr,
  elaborate:MatchTermElaborator,
):Expr {
  const pattern=alternative.pattern;
  if(pattern.kind!=='constructor')throw new Error('unreachable');
  const constructor=context.environment.find(constructorName);
  if(constructor?.kind!=='constructor'){
    throw new Error(
      "PS_ELAB_MATCH_CONSTRUCTOR: unknown constructor '"+
      nameToString(constructorName)+"'",
    );
  }
  if(constructor.numParams!==parameterArgs.length){
    throw new Error(
      "PS_ELAB_MATCH_PARAMETER_ARITY: constructor '"+
      nameToString(constructorName)+"' expects "+
      constructor.numParams+' shared parameters, got '+
      parameterArgs.length,
    );
  }
  if(pattern.binders.length!==constructor.numFields){
    throw new Error(
      "PS_ELAB_MATCH_ARITY: constructor '"+
      nameToString(constructorName)+"' binds "+
      constructor.numFields+' fields, got '+pattern.binders.length,
    );
  }

  let cursor=constructor.type;
  for(const parameter of parameterArgs){
    const checker=new TypeChecker(
      context.environment,
      context.localContext.clone(),
    );
    const binder=checker.ensureForall(checker.whnf(cursor));
    cursor=instantiate1(binder.body,parameter);
  }

  let branchContext=context;
  const fields:{
    readonly id:string;
    readonly name:Name;
    readonly type:Expr;
    readonly binderInfo:import('lean-ts-kernel').BinderInfo;
    readonly recursive:boolean;
  }[]=[];

  for(let index=0;index<constructor.numFields;index+=1){
    const checker=new TypeChecker(
      context.environment,
      branchContext.localContext.clone(),
    );
    const binder=checker.ensureForall(checker.whnf(cursor));
    const directRecursive=isDirectRecursiveField(
      binder.type,
      constructor.induct,
      parameterArgs,
      checker,
    );
    if(
      !directRecursive
      &&hasConstant(checker.whnf(binder.type),constructor.induct)
    ){
      throw new Error(
        'PS_ELAB_MATCH_HIGHER_ORDER_RECURSION_UNSUPPORTED: constructor field '+
        index+' of '+nameToString(constructorName),
      );
    }

    const sourceName=pattern.binders[index]!;
    if(branchContext.locals.has(sourceName)){
      throw new Error(
        "PS_ELAB_MATCH_BINDER_DUPLICATE: '"+sourceName+"'",
      );
    }

    const localContext=branchContext.localContext.clone();
    const id=localContext.fresh(sourceName);
    const userName=nameFromDotted(sourceName);
    localContext.addLocal(
      id,
      userName,
      binder.type,
      binder.binderInfo,
    );
    const locals=new Map(branchContext.locals);
    locals.set(sourceName,id);
    branchContext={...branchContext,localContext,locals};
    fields.push({
      id,
      name:userName,
      type:binder.type,
      binderInfo:binder.binderInfo,
      recursive:directRecursive,
    });
    cursor=instantiate1(binder.body,fvar(id));
  }

  const recursiveFields=fields.filter((field)=>field.recursive);
  const inductionHypotheses:{
    readonly id:string;
    readonly name:Name;
    readonly type:Expr;
  }[]=[];
  for(let index=0;index<recursiveFields.length;index+=1){
    const field=recursiveFields[index]!;
    const localContext=branchContext.localContext.clone();
    const name=nameFromDotted('_ih_'+nameToString(field.name));
    const id=localContext.fresh(nameToString(name));
    localContext.addLocal(id,name,expected,'default');

    let structuralRecursion=branchContext.structuralRecursion;
    if(structuralRecursion!==undefined){
      const calls=new Map(structuralRecursion.calls);
      calls.set(field.id,id);
      structuralRecursion={...structuralRecursion,calls};
    }
    branchContext={
      ...branchContext,
      localContext,
      ...(structuralRecursion===undefined
        ?{}
        :{structuralRecursion}),
    };
    inductionHypotheses.push({id,name,type:expected});
  }

  const branch=elaborate(
    alternative.body,
    branchContext,
    expected,
  );
  let result=branch.term;
  for(let index=inductionHypotheses.length-1;index>=0;index-=1){
    const ih=inductionHypotheses[index]!;
    result=lam(
      ih.name,
      ih.type,
      abstractFVar(result,ih.id),
      'default',
    );
  }
  for(let index=fields.length-1;index>=0;index-=1){
    const field=fields[index]!;
    result=lam(
      field.name,
      field.type,
      abstractFVar(result,field.id),
      field.binderInfo,
    );
  }
  return result;
}
