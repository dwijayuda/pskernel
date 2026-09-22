import fs from 'node:fs';
import os from 'node:os';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { join, resolve } from 'node:path';
import { Lean4ExportReplay } from '../dist/src/integration/lean4export.js';
import { TypeChecker } from '../dist/src/kernel/type-checker.js';
import { LocalContext } from '../dist/src/core/local-context.js';
import { nameFromDotted } from '../dist/src/core/name.js';
import { app, bvar, constant, forallE, fvar, lam, mkAppN, natLit, sort, strLit } from '../dist/src/core/expr.js';
import { levelParam, levelSucc, levelZero, mkIMax, mkMax } from '../dist/src/core/level.js';

const candidates=[process.env.LEAN434_BIN,'/mnt/data/work/lean4src/lean4-4.34.0/build/release/stage1/bin'].filter(Boolean).map(p=>resolve(p));
const bin=candidates.find(p=>fs.existsSync(join(p,'lean')));
if(!bin) throw new Error('defeq-differential: set LEAN434_BIN to Lean 4.34.0 bin directory');
const version=spawnSync(join(bin,'lean'),['--version'],{encoding:'utf8',timeout:5000}).stdout.trim();
if(version!=='Lean (version 4.34.0, Release)') throw new Error(`defeq-differential: Lean version drift: ${version}`);

const replay=new Lean4ExportReplay();
replay.replay(fs.readFileSync('oracle/fixtures/lean434-init-prelude.ndjson','utf8'));
const env=replay.env;
const N=s=>nameFromDotted(s), Nat=()=>constant(N('Nat')), Bool=()=>constant(N('Bool'));
const oneLevel=levelSucc(levelZero);
const arrow=(a,b)=>forallE(N('_'),a,b);
// The dependency-closed Init.Prelude fixture does not reference the deprecated
// native-reduction helpers, so install their exact opaque signatures explicitly.
if(!env.has(N('Lean.reduceNat'))) env.add({kind:'opaque',name:N('Lean.reduceNat'),levelParams:[],type:arrow(Nat(),Nat()),value:lam(N('n'),Nat(),bvar(0))});
if(!env.has(N('Lean.reduceBool'))) env.add({kind:'opaque',name:N('Lean.reduceBool'),levelParams:[],type:arrow(Bool(),Bool()),value:lam(N('b'),Bool(),bvar(0))});
const eqNat=(a,b)=>mkAppN(constant(N('Eq'),[oneLevel]),[Nat(),a,b]);
const add=(a,b)=>app(app(constant(N('Nat.add')),a),b);
const mkLocal=(decls,build)=>{const l=new LocalContext();const xs={};for(const [id,type] of decls){l.addLocal(id,N(id),type);xs[id]=fvar(id);}const tc=new TypeChecker(env,l);return build(tc,xs);};

const stringCtor=(text)=>{
 const chars=[...text].map(ch=>app(constant(N('Char.ofNat')),natLit(ch.codePointAt(0))));
 let xs=app(constant(N('List.nil'),[levelZero]),constant(N('Char')));
 for(let i=chars.length-1;i>=0;i--) xs=mkAppN(constant(N('List.cons'),[levelZero]),[constant(N('Char')),chars[i],xs]);
 return app(constant(N('String.ofList')),xs);
};
const eqRelNat=lam(N('a'),Nat(),lam(N('b'),Nat(),eqNat(bvar(1),bvar(0))));
const quotNat=(n)=>mkAppN(constant(N('Quot.mk'),[oneLevel]),[Nat(),eqRelNat,n]);
const quotLiftId=(n)=>mkAppN(constant(N('Quot.lift'),[oneLevel,oneLevel]),[Nat(),eqRelNat,Nat(),lam(N('x'),Nat(),bvar(0)),constant(N('True.intro')),quotNat(n)]);

const cases=[
 {name:'beta',expected:true,lean:'example : ((fun x : Nat => x) 3) = 3 := rfl',ts:()=>({tc:new TypeChecker(env),lhs:app(lam(N('x'),Nat(),bvar(0)),natLit(3)),rhs:natLit(3)})},
 {name:'zeta',expected:true,lean:'example : (let x : Nat := 2; x) = 2 := rfl',ts:()=>({tc:new TypeChecker(env),lhs:{kind:'let',name:N('x'),type:Nat(),value:natLit(2),body:bvar(0)},rhs:natLit(2)})},
 {name:'nat-add',expected:true,lean:'example : (2 + 3 : Nat) = 5 := rfl',ts:()=>({tc:new TypeChecker(env),lhs:add(natLit(2),natLit(3)),rhs:natLit(5)})},
 {name:'function-eta',expected:true,lean:'example (f : Nat → Nat) : (fun x => f x) = f := rfl',ts:()=>mkLocal([['f',arrow(Nat(),Nat())]],(tc,x)=>({tc,lhs:lam(N('x'),Nat(),app(x.f,bvar(0))),rhs:x.f}))},
 {name:'proof-irrelevance',expected:true,lean:'example (p q : (0 : Nat) = 0) : p = q := rfl',ts:()=>mkLocal([['p',eqNat(natLit(0),natLit(0))],['q',eqNat(natLit(0),natLit(0))]],(tc,x)=>({tc,lhs:x.p,rhs:x.q}))},
 {name:'structure-eta',expected:true,lean:'example (p : PProd Nat Nat) : PProd.mk p.1 p.2 = p := rfl',ts:()=>{const pp=mkAppN(constant(N('PProd'),[oneLevel,oneLevel]),[Nat(),Nat()]);return mkLocal([['p',pp]],(tc,x)=>{const fst={kind:'proj',typeName:N('PProd'),index:0,expr:x.p},snd={kind:'proj',typeName:N('PProd'),index:1,expr:x.p};return {tc,lhs:mkAppN(constant(N('PProd.mk'),[oneLevel,oneLevel]),[Nat(),Nat(),fst,snd]),rhs:x.p};});}},
 {name:'universe-max-commutes',expected:true,lean:'universe u v\nexample (α : Sort (max u v)) : Sort (max v u) := α',ts:()=>{const u=levelParam(N('u')),v=levelParam(N('v'));return {tc:new TypeChecker(env),lhs:sort(mkMax(u,v)),rhs:sort(mkMax(v,u))};}},
 {name:'delta-definition',expected:true,lean:'def DiffD : Nat := 1\nexample : DiffD = 1 := rfl',ts:()=>{const n=N('Diff.D');if(!env.has(n))env.add({kind:'definition',name:n,levelParams:[],type:Nat(),value:natLit(1),hints:{kind:'regular',height:1n},safety:'safe'});return {tc:new TypeChecker(env),lhs:constant(n),rhs:natLit(1)};}},
 {name:'opaque-does-not-delta',expected:false,lean:'opaque DiffO : Nat := 1\nexample : DiffO = 1 := rfl',ts:()=>{const n=N('Diff.O');if(!env.has(n))env.add({kind:'opaque',name:n,levelParams:[],type:Nat(),value:natLit(1)});return {tc:new TypeChecker(env),lhs:constant(n),rhs:natLit(1)};}},
 {name:'projection-lazy-delta',expected:true,lean:'def pleft1 : PProd Nat Nat := PProd.mk 1 2\ndef pleft2 : PProd Nat Nat := PProd.mk 1 3\nexample : pleft1.1 = pleft2.1 := rfl',ts:()=>{const pp=mkAppN(constant(N('PProd'),[oneLevel,oneLevel]),[Nat(),Nat()]),mk=(a,b)=>mkAppN(constant(N('PProd.mk'),[oneLevel,oneLevel]),[Nat(),Nat(),a,b]),p1=N('Diff.pleft1'),p2=N('Diff.pleft2');if(!env.has(p1))env.add({kind:'definition',name:p1,levelParams:[],type:pp,value:mk(natLit(1),natLit(2)),hints:{kind:'regular',height:1n},safety:'safe'});if(!env.has(p2))env.add({kind:'definition',name:p2,levelParams:[],type:pp,value:mk(natLit(1),natLit(3)),hints:{kind:'regular',height:1n},safety:'safe'});return {tc:new TypeChecker(env),lhs:{kind:'proj',typeName:N('PProd'),index:0,expr:constant(p1)},rhs:{kind:'proj',typeName:N('PProd'),index:0,expr:constant(p2)}};}},

 {name:'nat-recursor-iota',expected:true,lean:'example : Nat.rec (motive := fun _ => Nat) 7 (fun _ r => Nat.succ r) 2 = 9 := rfl',ts:()=>{const motive=lam(N('_'),Nat(),Nat()),step=lam(N('n'),Nat(),lam(N('r'),Nat(),app(constant(N('Nat.succ')),bvar(0))));const lhs=mkAppN(constant(N('Nat.rec'),[oneLevel]),[motive,natLit(7),step,natLit(2)]);return {tc:new TypeChecker(env),lhs,rhs:natLit(9)};}},
 {name:'unit-like',expected:true,lean:'example (x y : Unit) : x = y := rfl',ts:()=>mkLocal([['x',constant(N('Unit'))],['y',constant(N('Unit'))]],(tc,x)=>({tc,lhs:x.x,rhs:x.y}))},
 {name:'string-expansion',expected:true,lean:`example : "A🙂" = String.ofList ['A','🙂'] := rfl`,ts:()=>({tc:new TypeChecker(env),lhs:strLit('A🙂'),rhs:stringCtor('A🙂')})},
 {name:'string-unequal',expected:false,lean:'example : "A" = "B" := rfl',ts:()=>({tc:new TypeChecker(env),lhs:strLit('A'),rhs:strLit('B')})},
 {name:'quot-lift-iota',expected:true,lean:'example : Quot.lift (fun n : Nat => n) (by intro a b h; exact h) (Quot.mk (fun a b : Nat => a = b) 3) = 3 := rfl',ts:()=>({tc:new TypeChecker(env),lhs:quotLiftId(natLit(3)),rhs:natLit(3)})},
 {name:'imax-zero',expected:true,lean:'universe u\nexample : Sort (imax u 0) = Sort 0 := rfl',ts:()=>{const u=levelParam(N('u'));return {tc:new TypeChecker(env),lhs:sort(mkIMax(u,levelZero)),rhs:sort(levelZero)};}},
 {name:'max-idempotent',expected:true,lean:'universe u\nexample : Sort (max u u) = Sort u := rfl',ts:()=>{const u=levelParam(N('u'));return {tc:new TypeChecker(env),lhs:sort(mkMax(u,u)),rhs:sort(u)};}},
 {name:'imax-successor',expected:true,lean:'universe u v\nexample : Sort (imax u (v+1)) = Sort (max u (v+1)) := rfl',ts:()=>{const u=levelParam(N('u')),v1=levelSucc(levelParam(N('v')));return {tc:new TypeChecker(env),lhs:sort(mkIMax(u,v1)),rhs:sort(mkMax(u,v1))};}},
 {name:'nat-recursor-depth3',expected:true,lean:'example : (Nat.rec (motive := fun _ => Nat) 0 (fun _ r => r + 1) 3) = 3 := rfl',ts:()=>{const motive=lam(N('_'),Nat(),Nat()),step=lam(N('_'),Nat(),lam(N('r'),Nat(),add(bvar(0),natLit(1))));return {tc:new TypeChecker(env),lhs:mkAppN(constant(N('Nat.rec'),[oneLevel]),[motive,natLit(0),step,natLit(3)]),rhs:natLit(3)};}},
 {name:'bool-and',expected:true,lean:'example : (true && false) = false := rfl',ts:()=>({tc:new TypeChecker(env),lhs:mkAppN(constant(N('Bool.and')),[constant(N('Bool.true')),constant(N('Bool.false'))]),rhs:constant(N('Bool.false'))})},
 {name:'nat-succ-literal',expected:true,lean:'example : (Nat.succ 2) = 3 := rfl',ts:()=>({tc:new TypeChecker(env),lhs:app(constant(N('Nat.succ')),natLit(2)),rhs:natLit(3)})},
 {name:'native-reduce-nat-provider',expected:true,lean:'def NativeReduceNatV := 100000000000 + 100000000000\nexample : Lean.reduceNat NativeReduceNatV = 200000000000 := rfl',ts:()=>{const n=N('Diff.NativeReduceNatV');if(!env.has(n))env.add({kind:'definition',name:n,levelParams:[],type:Nat(),value:add(natLit(100000000000n),natLit(100000000000n)),hints:{kind:'regular',height:1n},safety:'safe'});const nativeEvaluator={evaluate(_env,request){return request.kind==='nat'&&request.constant===n?{kind:'nat',value:200000000000n}:null;}};return {tc:new TypeChecker(env,undefined,undefined,undefined,'safe',undefined,false,nativeEvaluator),lhs:app(constant(N('Lean.reduceNat')),constant(n)),rhs:natLit(200000000000n)};}},
 {name:'native-reduce-bool-provider',expected:true,lean:'def NativeReduceBoolV : Bool := 200000000001 <= 20000000000\nexample : Lean.reduceBool NativeReduceBoolV = false := rfl',ts:()=>{const n=N('Diff.NativeReduceBoolV');if(!env.has(n))env.add({kind:'definition',name:n,levelParams:[],type:Bool(),value:mkAppN(constant(N('Nat.ble')),[natLit(200000000001n),natLit(20000000000n)]),hints:{kind:'regular',height:1n},safety:'safe'});const nativeEvaluator={evaluate(_env,request){return request.kind==='bool'&&request.constant===n?{kind:'bool',value:false}:null;}};return {tc:new TypeChecker(env,undefined,undefined,undefined,'safe',undefined,false,nativeEvaluator),lhs:app(constant(N('Lean.reduceBool')),constant(n)),rhs:constant(N('Bool.false'))};}},
 {name:'nat-unequal',expected:false,lean:'example : (2 : Nat) = 3 := rfl',ts:()=>({tc:new TypeChecker(env),lhs:natLit(2),rhs:natLit(3)})},
 {name:'lambda-unequal',expected:false,lean:'example : (fun x : Nat => x) = (fun _ : Nat => 0) := rfl',ts:()=>({tc:new TypeChecker(env),lhs:lam(N('x'),Nat(),bvar(0)),rhs:lam(N('_'),Nat(),natLit(0))})},
 {name:'eta-wrong-function',expected:false,lean:'example (f : Nat → Nat) : (fun _ => f 0) = f := rfl',ts:()=>mkLocal([['f',arrow(Nat(),Nat())]],(tc,x)=>({tc,lhs:lam(N('_'),Nat(),app(x.f,natLit(0))),rhs:x.f}))},
];

const dir=mkdtempSync(join(os.tmpdir(),'lean434-defeq-'));
let passed=0;
try{
 for(const c of cases){
   const {tc,lhs,rhs}=c.ts(); const ts=tc.isDefEq(lhs,rhs);
   if(ts!==c.expected) throw new Error(`${c.name}: TS=${ts}, expected ${c.expected}`);
   const file=join(dir,`${c.name.replaceAll('-','_')}.lean`);writeFileSync(file,`import Init.Prelude\n${c.lean}\n`);
   const rr=spawnSync(join(bin,'lean'),[file],{encoding:'utf8',timeout:10000,env:{...process.env,PATH:`${bin}:${process.env.PATH??''}`}});
   if(rr.error?.code==='ETIMEDOUT') throw new Error(`${c.name}: official Lean timed out`);
   const official=rr.status===0;
   if(official!==c.expected) throw new Error(`${c.name}: official=${official}, expected ${c.expected}\n${rr.stderr}`);
   if(official!==ts) throw new Error(`${c.name}: differential mismatch: TS=${ts}, Lean=${official}`);
   passed++;console.log(`ok ${passed} - ${c.name}: ${ts?'defeq':'not-defeq'}`);
 }
} finally { rmSync(dir,{recursive:true,force:true}); }
console.log(`defeq-differential: PASS (${passed}/${cases.length}; ${version})`);
