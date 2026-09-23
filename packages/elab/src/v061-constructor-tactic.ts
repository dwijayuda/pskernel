import {getMainGoal} from '@proofscript/tactic';
import {
  TypeChecker,
  appView,
  constant,
} from 'lean-ts-kernel';
import {applyV061Tactic} from './v061-apply-tactic.js';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

export function constructorV061Tactic(
  runtime:V061TacticRuntime,
):void {
  const goal=getMainGoal(runtime.state);
  const entry=runtime.entry(goal);
  const checker=new TypeChecker(
    entry.context.environment,
    entry.context.localContext.clone(),
  );
  const target=checker.whnf(runtime.expected(goal));
  const view=appView(target);

  if(view.fn.kind!=='const'){
    throw new Error(
      'PS_ELAB_TACTIC_CONSTRUCTOR: target is not an inductive datatype',
    );
  }
  const info=entry.context.environment.find(view.fn.name);
  if(info?.kind!=='inductive'){
    throw new Error(
      'PS_ELAB_TACTIC_CONSTRUCTOR: target is not an inductive datatype',
    );
  }

  const errors:string[]=[];
  for(const ctor of info.ctors){
    const term=constant(ctor,view.fn.levels);
    let type;
    try{
      type=checker.check(term);
      applyV061Tactic(runtime,{term,type});
      return;
    }catch(error){
      errors.push(error instanceof Error?error.message:String(error));
    }
  }

  throw new Error(
    'PS_ELAB_TACTIC_CONSTRUCTOR: no applicable constructor found'+
    (errors.length===0?'':' ('+errors[0]+')'),
  );
}
