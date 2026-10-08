import test from 'node:test';
import assert from 'node:assert/strict';
import { k, tag, list, expression, randomGenerator, randomExpression } from './binding-values.mjs';
import { runtimeName, runtimeLevel, runtimeFuel } from './fixture-values.mjs';
const N=s=>['str',['anonymous'],s], Z=['zero'], P=s=>['param',N(s)], S=x=>['succ',x];
const names=['u','v'], levels=[P('outer'),S(Z)];
const make=(value,ns=names,ls=levels)=>k.psKernelExprInstantiateStart(list(ns.map(n=>runtimeName(k,N(n)))),list(ls.map(l=>runtimeLevel(k,l))),expression(value));
function drive(state,budget=20000){
  for(let steps=1;steps<=budget;steps++){
    const out=k.psKernelExprInstantiateStep(state);
    if(tag(out)==='final')return{status:tag(out.result),result:out.result,steps};
    assert.equal(tag(out),'next');state=out.state;
  }
  return{status:'outOfFuel',steps:budget};
}
const good=(input,expected)=>{
  const r=drive(make(input));assert.equal(r.status,'done');assert.deepEqual(r.result.value,expression(expected));
};
for(const value of [['b','9007199254740993'],['f','123'],['nat','9007199254740993'],['text','λ\u0000😀']]){
  test('universe traversal preserves term-only leaf '+value[0],()=>good(value,value));
}
test('sort levels substitute simultaneously',()=>good(['sort',['max',P('u'),P('v')]],['sort',['max',P('outer'),S(Z)]]));
test('constant universe argument order is preserved',()=>good(['const',N('C'),[P('v'),P('u'),Z]],['const',N('C'),[S(Z),P('outer'),Z]]));
test('empty constant argument lists remain empty',()=>good(['const',N('C'),[]],['const',N('C'),[]]));
for(const [label,input,expected] of [
  ['application',['app',['const',N('f'),[P('u')]],['sort',P('v')]],['app',['const',N('f'),[P('outer')]],['sort',S(Z)]]],
  ['lambda',['lam',N('u'),['sort',P('u')],['b','0'],'strictImplicit'],['lam',N('u'),['sort',P('outer')],['b','0'],'strictImplicit']],
  ['dependent Pi',['pi',N('v'),['sort',P('v')],['app',['b','0'],['sort',P('u')]],'instanceImplicit'],['pi',N('v'),['sort',S(Z)],['app',['b','0'],['sort',P('outer')]],'instanceImplicit']],
  ['let',['let',N('local'),['sort',P('u')],['sort',P('v')],['const',N('body'),[P('u')]]],['let',N('local'),['sort',P('outer')],['sort',S(Z)],['const',N('body'),[P('outer')]]]],
  ['projection',['proj',N('Family'),'4294967296',['const',N('C'),[P('u')]]],['proj',N('Family'),'4294967296',['const',N('C'),[P('outer')]]]],
])test('universe traversal through '+label,()=>good(input,expected));
test('parameter validation cannot be bypassed by terms without universes',()=>{
  assert.equal(drive(make(['b','0'],['u'],[])).status,'invalidParameters');
  assert.equal(drive(make(['nat','0'],['u','u'],[Z,Z])).status,'invalidParameters');
});
test('undeclared level parameter fails inside a nested expression',()=>{
  assert.equal(drive(make(['lam',N('x'),['sort',P('u')],['const',N('Bad'),[P('missing')]],'explicit'])).status,'undeclaredParameter');
});
test('shared expression budget includes nested level validation and traversal',()=>{
  const input=['const',N('C'),[P('u'),P('v'),['imax',P('u'),P('v')]]];
  const full=drive(make(input));assert.equal(full.status,'done');
  assert.equal(drive(make(input),full.steps-1).status,'outOfFuel');
  assert.deepEqual(drive(make(input),full.steps).result,full.result);
  assert.deepEqual(k.psKernelExprInstantiateRun(runtimeFuel(k,full.steps),make(input)),full.result);
});
test('50000-deep expression stops at a finite shared budget',()=>{
  let input=k.PsKernelExpr.bvar(k.PsKernelNatural.zero);
  for(let i=0;i<50000;i++)input=k.PsKernelExpr.app(input,input);
  assert.equal(drive(k.psKernelExprInstantiateStart(k.PsKernelList.nil(),k.PsKernelList.nil(),input),1000).status,'outOfFuel');
});
test('256 expression trees preserve all term fields and substitute only levels',()=>{
  const rand=randomGenerator(79381), replacement=['max',P('outer'),S(Z)];
  const substLevel=x=>x[0]==='param'?replacement:x[0]==='zero'?x:x[0]==='succ'?S(substLevel(x[1])):[x[0],substLevel(x[1]),substLevel(x[2])];
  const spec=x=>{
    switch(x[0]){
      case'sort':return['sort',substLevel(x[1])];
      case'const':return['const',x[1],x[2].map(substLevel)];
      case'app':return['app',spec(x[1]),spec(x[2])];
      case'lam':case'pi':return[x[0],x[1],spec(x[2]),spec(x[3]),x[4]];
      case'let':return['let',x[1],spec(x[2]),spec(x[3]),spec(x[4])];
      case'proj':return['proj',x[1],x[2],spec(x[3])];
      default:return x;
    }
  };
  for(let i=0;i<256;i++){
    const input=randomExpression(rand,4), r=drive(make(input,['u'],[replacement]));
    assert.equal(r.status,'done','case '+i);assert.deepEqual(r.result.value,expression(spec(input)),'case '+i);
  }
});
