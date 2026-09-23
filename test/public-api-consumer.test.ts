import {
  Environment,
  Kernel,
  bvar,
  forallE,
  lam,
  levelSucc,
  levelZero,
  nameFromDotted,
  sort,
} from 'lean-ts-kernel';

function assert(condition:boolean,message:string):asserts condition {
  if(!condition) throw new Error(message);
}

const env=new Environment();
const kernel=new Kernel(env);
const alpha=nameFromDotted('alpha');
const x=nameFromDotted('x');
const identity=nameFromDotted('Feasibility.identity');
const typeOfType=sort(levelSucc(levelZero));

const identityType=forallE(
  alpha,
  typeOfType,
  forallE(x,bvar(0),bvar(1),'default'),
  'implicit',
);
const identityValue=lam(
  alpha,
  typeOfType,
  lam(x,bvar(0),bvar(0),'default'),
  'implicit',
);

kernel.addDefinition({
  kind:'definition',
  name:identity,
  levelParams:[],
  type:identityType,
  value:identityValue,
  hints:{kind:'regular',height:0n},
  safety:'safe',
});

const admitted=env.find(identity);
assert(admitted?.kind==='definition','public facade must admit identity definition');
assert(admitted.value.kind==='lam','admitted definition must retain checked lambda body');

console.log('ok - pskernel public consumer facade admits dependent identity');
