import {
  getMainGoal,
  refine as refineTransition,
  type TacticGoal,
} from '@proofscript/tactic';
import type {V061Expr} from '@proofscript/syntax';
import {
  TypeChecker,
  constant,
  fvar,
  hasMVar,
  nameFromDotted,
  type Expr,
} from 'lean-ts-kernel';
import {
  elaborateApplication,
  type ApplicationArgumentSource,
} from './application.js';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
import {v061LocalInstanceTerms} from './v061-context.js';
import type {V061TermElaborator} from './v061-tactic-elab.js';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

interface PartialRefinement {
  readonly term:Expr;
  readonly type:Expr;
  readonly holes:readonly Expr[];
}

function resolveCallee(
  name:string,
  context:V061CoreElabContext,
):Expr {
  const local=context.locals.get(name);
  if(local!==undefined)return fvar(local);
  const full=nameFromDotted(name);
  if(context.environment.find(full)===undefined){
    throw new Error(
      "PS_ELAB_TACTIC_REFINE_UNKNOWN_NAME: unknown name '"+name+"'",
    );
  }
  return constant(full);
}

function callRefinement(
  expr:Extract<V061Expr,{kind:'call'}>,
  context:V061CoreElabContext,
  target:Expr,
  elaborate:V061TermElaborator,
):PartialRefinement {
  const holes:Expr[]=[];
  const source:ApplicationArgumentSource={
    length:expr.args.length,
    elaborate:(index,expectedType)=>{
      const argument=expr.args[index]!;
      if(argument.kind==='syntheticHole'){
        const hole=context.metaContext.mkFresh(
          expectedType,
          context.localContext,
          'syntheticOpaque',
        );
        holes.push(hole);
        return {term:hole,allowUnresolvedMVar:true};
      }
      return {
        term:elaborate(argument,context,expectedType).term,
      };
    },
  };
  const result=elaborateApplication({
    environment:context.environment,
    metaContext:context.metaContext,
    fn:resolveCallee(expr.callee,context),
    args:source,
    expectedType:target,
    localContext:context.localContext,
    localInstances:v061LocalInstanceTerms(context),
    globalInstances:context.globalInstances,
    classNames:context.classes,
  });

  if(result.pendingInstances.length!==0){
    throw new Error(
      'PS_ELAB_TACTIC_REFINE_INSTANCE: unresolved instance argument',
    );
  }
  for(const inserted of result.inserted){
    if(
      inserted.argument.kind==='mvar'
      &&!context.metaContext.isAssigned(inserted.argument)
    ){
      throw new Error(
        'PS_ELAB_TACTIC_REFINE_IMPLICIT: unresolved implicit argument; '+
        "use explicit terms or wait for refine' support",
      );
    }
  }

  return {term:result.term,type:result.type,holes};
}

function elaboratePartial(
  expr:V061Expr,
  context:V061CoreElabContext,
  target:Expr,
  elaborate:V061TermElaborator,
):PartialRefinement {
  if(expr.kind==='group'){
    return elaboratePartial(expr.value,context,target,elaborate);
  }
  if(expr.kind==='syntheticHole'){
    const hole=context.metaContext.mkFresh(
      target,
      context.localContext,
      'syntheticOpaque',
    );
    return {term:hole,type:target,holes:[hole]};
  }
  if(expr.kind==='call'){
    return callRefinement(expr,context,target,elaborate);
  }

  const result=elaborate(expr,context,target);
  return {term:result.term,type:result.type,holes:[]};
}

function refinementGoals(
  runtime:V061TacticRuntime,
  goal:TacticGoal<Expr>,
  partial:PartialRefinement,
):readonly TacticGoal<Expr>[] {
  const entry=runtime.entry(goal);
  const meta=entry.context.metaContext;
  const checker=new TypeChecker(
    entry.context.environment,
    entry.context.localContext.clone(),
  );
  const target=runtime.expected(goal);
  const open=partial.holes.filter((hole)=>!meta.isAssigned(hole));

  const finalize=():void=>{
    if(open.some((hole)=>!meta.isAssigned(hole)))return;
    const term=meta.instantiate(partial.term);
    if(hasMVar(term)){
      throw new Error(
        'PS_ELAB_TACTIC_REFINE_STUCK: partial proof leaves unresolved metavariables',
      );
    }
    const type=checker.check(term);
    if(!checker.isDefEq(type,target)){
      throw new Error(
        'PS_ELAB_TACTIC_REFINE_TYPE: refined proof does not match the goal',
      );
    }
    runtime.completeGoal(goal,{term,type});
  };

  if(open.length===0){
    finalize();
    return [];
  }

  return open.map((hole)=>{
    const declaration=meta.getDecl(hole);
    return runtime.createGoal(
      entry.context,
      declaration.type,
      (proof)=>{
        meta.assign(hole,proof.term);
        finalize();
      },
    );
  });
}

export function refineV061Tactic(
  runtime:V061TacticRuntime,
  expr:V061Expr,
  elaborate:V061TermElaborator,
):void {
  const goal=getMainGoal(runtime.state);
  const entry=runtime.entry(goal);
  const partial=elaboratePartial(
    expr,
    entry.context,
    runtime.expected(goal),
    elaborate,
  );

  runtime.state=refineTransition(
    runtime.state,
    partial.term,
    {
      refine:(current)=>refinementGoals(runtime,current,partial),
    },
  );
}
