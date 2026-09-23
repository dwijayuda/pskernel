import {
  apply,
  assumption,
  exact,
  intro,
  type TacticGoal,
} from '../src/index.js';

function equal(actual:unknown,expected:unknown):void {
  if(actual!==expected){
    throw new Error(
      'expected '+String(expected)+', got '+String(actual),
    );
  }
}

function goal(
  id:string,
  target:string,
  locals:TacticGoal<string>['locals']=[],
):TacticGoal<string> {
  return {id,target,locals};
}

const assignments=new Map<string,string>();
const kernel={
  inferType:(term:string)=>term.startsWith('proof:')
    ?term.slice(6)
    :'?',
  isDefEq:(left:string,right:string)=>left===right,
  assign:(current:TacticGoal<string>,proof:string)=>{
    assignments.set(current.id,proof);
  },
};

{
  const state={goals:[goal('g0','P'),goal('tail','Q')]};
  const next=exact(state,'proof:P',kernel);
  equal(next.goals.length,1);
  equal(next.goals[0]?.id,'tail');
  equal(assignments.get('g0'),'proof:P');
}

{
  const state={
    goals:[
      goal('g1','P',[
        {name:'old',type:'P',value:'proof:P-old'},
        {name:'new',type:'P',value:'proof:P-new'},
      ]),
    ],
  };
  const next=assumption(state,kernel);
  equal(next.goals.length,0);
  equal(assignments.get('g1'),'proof:P-new');
}

{
  const state={goals:[goal('g2','A->B'),goal('tail','Q')]};
  const next=intro(state,'a',{
    intro:(current,name)=>{
      equal(current.id,'g2');
      equal(name,'a');
      assignments.set(current.id,'lambda:a');
      return goal(
        'g2.body',
        'B',
        [...current.locals,{name,type:'A',value:'local:a'}],
      );
    },
  });
  equal(next.goals.length,2);
  equal(next.goals[0]?.id,'g2.body');
  equal(next.goals[1]?.id,'tail');
  equal(next.goals[0]?.locals[0]?.name,'a');
}

{
  const state={goals:[goal('g3','C'),goal('tail','Q')]};
  const next=apply(state,'f',{
    apply:(current,candidate)=>{
      equal(current.id,'g3');
      equal(candidate,'f');
      assignments.set(current.id,'f ?m0 ?m1');
      return [goal('m0','A'),goal('m1','B')];
    },
  });
  equal(next.goals.length,3);
  equal(next.goals[0]?.id,'m0');
  equal(next.goals[1]?.id,'m1');
  equal(next.goals[2]?.id,'tail');
  equal(assignments.get('g3'),'f ?m0 ?m1');
}

{
  const state={goals:[goal('g4','P')]};
  const next=apply(state,'closed',{
    apply:(current)=>{
      assignments.set(current.id,'closed');
      return [];
    },
  });
  equal(next.goals.length,0);
}

console.log('ok - @proofscript/tactic ordered multi-goal state');
