import {
  TypeChecker,
  abstractFVar,
  appView,
  constant,
  fvar,
  instantiate1,
  lam,
  mkAppN,
  nameEq,
  nameFromDotted,
  nameToString,
  type BinderInfo,
  type Expr,
  type Name,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';

interface InductionField {
  readonly id:string;
  readonly name:Name;
  readonly type:Expr;
  readonly binderInfo:BinderInfo;
  readonly recursive:boolean;
}

interface InductionHypothesis {
  readonly id:string;
  readonly name:Name;
  readonly type:Expr;
}

export interface V061InductionBranch {
  readonly fields:readonly InductionField[];
  readonly hypotheses:readonly InductionHypothesis[];
  readonly context:V061CoreElabContext;
  readonly target:Expr;
}

function containsConstant(expr:Expr,target:Name):boolean {
  switch(expr.kind){
    case 'const':return nameEq(expr.name,target);
    case 'app':
      return containsConstant(expr.fn,target)
        ||containsConstant(expr.arg,target);
    case 'lam':
    case 'forall':
      return containsConstant(expr.type,target)
        ||containsConstant(expr.body,target);
    case 'let':
      return containsConstant(expr.type,target)
        ||containsConstant(expr.value,target)
        ||containsConstant(expr.body,target);
    case 'mdata':
    case 'proj':
      return containsConstant(expr.expr,target);
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

export function buildV061InductionBranch(
  branchIndex:number,
  constructorName:Name,
  parameterArgs:readonly Expr[],
  constructorLevels:readonly import('lean-ts-kernel').Level[],
  majorName:string,
  motiveBody:Expr,
  baseContext:V061CoreElabContext,
):V061InductionBranch {
  const constructor=baseContext.environment.find(constructorName);
  if(constructor?.kind!=='constructor'){
    throw new Error(
      "PS_ELAB_TACTIC_INDUCTION_CONSTRUCTOR: unknown constructor '"+
      nameToString(constructorName)+"'",
    );
  }
  if(constructor.numParams!==parameterArgs.length){
    throw new Error(
      'PS_ELAB_TACTIC_INDUCTION_PARAMETER_ARITY: constructor parameter mismatch',
    );
  }

  const branchLocals=new Map(baseContext.locals);
  branchLocals.delete(majorName);
  let branchContext:V061CoreElabContext={
    ...baseContext,
    localContext:baseContext.localContext.clone(),
    locals:branchLocals,
  };

  let cursor=constructor.type;
  const fields:InductionField[]=[];
  const fieldTerms:Expr[]=[];
  for(const parameter of parameterArgs){
    const checker=new TypeChecker(
      branchContext.environment,
      branchContext.localContext.clone(),
    );
    const binder=checker.ensureForall(checker.whnf(cursor));
    cursor=instantiate1(binder.body,parameter);
  }

  for(let index=0;index<constructor.numFields;index+=1){
    const checker=new TypeChecker(
      branchContext.environment,
      branchContext.localContext.clone(),
    );
    const binder=checker.ensureForall(checker.whnf(cursor));
    const recursive=isDirectRecursiveField(
      binder.type,
      constructor.induct,
      parameterArgs,
      checker,
    );
    if(
      !recursive
      &&containsConstant(checker.whnf(binder.type),constructor.induct)
    ){
      throw new Error(
        'PS_ELAB_TACTIC_INDUCTION_HIGHER_ORDER_RECURSION_UNSUPPORTED: field '+
        index+' of '+nameToString(constructorName),
      );
    }

    let sourceName='_ind_'+branchIndex+'_'+index;
    while(branchContext.locals.has(sourceName))sourceName+='x';
    const localContext=branchContext.localContext.clone();
    const id=localContext.fresh(sourceName);
    const userName=nameFromDotted(sourceName);
    localContext.addLocal(id,userName,binder.type,binder.binderInfo);
    const locals=new Map(branchContext.locals);
    locals.set(sourceName,id);
    branchContext={...branchContext,localContext,locals};

    fields.push({
      id,
      name:userName,
      type:binder.type,
      binderInfo:binder.binderInfo,
      recursive,
    });
    const term=fvar(id);
    fieldTerms.push(term);
    cursor=instantiate1(binder.body,term);
  }

  const hypotheses:InductionHypothesis[]=[];
  const recursiveFields=fields.filter((field)=>field.recursive);
  for(let index=0;index<recursiveFields.length;index+=1){
    const field=recursiveFields[index]!;
    const type=instantiate1(motiveBody,fvar(field.id));
    let sourceName='_ih_'+branchIndex+'_'+index;
    while(branchContext.locals.has(sourceName))sourceName+='x';
    const localContext=branchContext.localContext.clone();
    const id=localContext.fresh(sourceName);
    const userName=nameFromDotted(sourceName);
    localContext.addLocal(id,userName,type,'default');
    const locals=new Map(branchContext.locals);
    locals.set(sourceName,id);
    branchContext={...branchContext,localContext,locals};
    hypotheses.push({id,name:userName,type});
  }

  const constructorTerm=mkAppN(
    constant(constructorName,constructorLevels),
    [...parameterArgs,...fieldTerms],
  );
  return {
    fields,
    hypotheses,
    context:branchContext,
    target:instantiate1(motiveBody,constructorTerm),
  };
}

export function abstractV061InductionBranch(
  proof:ElaboratedCoreTerm,
  branch:V061InductionBranch,
):Expr {
  let result=proof.term;
  for(let index=branch.hypotheses.length-1;index>=0;index-=1){
    const ih=branch.hypotheses[index]!;
    result=lam(
      ih.name,
      ih.type,
      abstractFVar(result,ih.id),
      'default',
    );
  }
  for(let index=branch.fields.length-1;index>=0;index-=1){
    const field=branch.fields[index]!;
    result=lam(
      field.name,
      field.type,
      abstractFVar(result,field.id),
      field.binderInfo,
    );
  }
  return result;
}
