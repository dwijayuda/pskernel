import { pathToFileURL } from "node:url";
import { performance } from "node:perf_hooks";
import fs from "node:fs";
import path from "node:path";

const filename=process.argv[2], label=process.argv[3];
if(!filename || !["original","optimized"].includes(label))
  throw Error("Usage: node pskernel-whole-js-bench.mjs <compiled-kernel.js> original|optimized");
const loadStart=performance.now();
const kernel=await import(pathToFileURL(path.resolve(filename)).href);
const importMs=performance.now()-loadStart;
function decl(name) {
  if(!(name in kernel)) throw Error("MISSING_CHECKED_JS_KERNEL_EXPORT: "+name);
  return kernel[name];
}
const Expr=decl("PsKernelExpr"), Level=decl("PsKernelLevel");
const Name=decl("PsKernelName"), Binder=decl("PsKernelBinderInfo");
const Safety=decl("PsKernelDefinitionSafety"), Hints=decl("PsKernelReducibilityHints");
const List=decl("List"), nil=typeof List.nil==="function"?List.nil():List.nil;
const empty=decl("psKernelEnvironmentEmpty"), maxNat=decl("psKernelLeanNatMaxSizeDefault");
const mkSession=decl("psKernelMkCheckerSession"), sessionInfer=decl("psKernelSessionInfer");
const sessionCheck=decl("psKernelSessionCheck"), sessionWhnf=decl("psKernelSessionWhnf");
const sessionEq=decl("psKernelSessionIsDefEq"), admitAxiom=decl("psKernelAddAxiom");
const admitDefinition=decl("psKernelAddDefinition"), addInductive=decl("psKernelAddSimpleInductive");
const addMutual=decl("psKernelAddSimpleMutualInductive"), eq=decl("psKernelExprEq");
const exists=decl("psKernelEnvironmentContains");
const zero=Level.zero, sort0=Expr.sort(zero), sort1=Expr.sort(Level.succ(zero));
const idLam=Expr.lam(Name.anonymous,sort0,Expr.bvar(0n),Binder.default);
const beta=Expr.app(idLam,sort0);
const fuel=4096n, depth=4096n;
function ok(result,caseName) {
  if(result && "value" in result) return result.value;
  throw Error("KERNEL_JS_UNEXPECTED_REJECTION "+caseName+" "+String(result?.error));
}
function rejected(result,caseName) {
  if(result && "error" in result) return true;
  throw Error("KERNEL_JS_FALSE_ACCEPT "+caseName);
}
function demand(test,caseName) {if(!test)throw Error("KERNEL_JS_WRONG_SEMANTICS "+caseName);}
const originalSession=mkSession(empty,nil,Safety.safe,depth,maxNat);
const fnName=Name.str(Name.anonymous,"BenchCheckedFunction");
let pi=sort0;
for(let i=0;i<16;i++) pi=Expr.forallE(Name.anonymous,sort1,pi,Binder.default);
const axiom={base:{name:fnName,levelParams:nil,type:pi},isUnsafe:false};
const checkedEnv=ok(admitAxiom(fuel,empty,axiom,depth,maxNat),"admitAxiom");
demand(exists(checkedEnv,fnName)===true,"axiom published");
const checkedSession=mkSession(checkedEnv,nil,Safety.safe,depth,maxNat);
let application=Expr.const(fnName,nil);
for(let i=0;i<16;i++) application=Expr.app(application,sort0);
const results=[];
function run(operation,round,iterations,invoke,guard) {
  const start=performance.now();
  let completed=0;
  for(let i=0;i<iterations;i++){
    const result=invoke(i);
    if(!guard(result,i))throw Error("KERNEL_JS_BENCH_VERDICT_FAILED "+operation+" "+i);
    completed++;
  }
  const ms=performance.now()-start;
  const row={label,operation,round,iterations,ms:Number(ms.toFixed(3)),completed};
  results.push(row);
  console.log("PSC1_JS_WHOLE "+JSON.stringify(row));
}
for(let round=0;round<3;round++){
  run("whnf_beta",round,30,()=>sessionWhnf(fuel,originalSession,beta),
    r=>eq(ok(r,"whnf_beta").fst,sort0));
  run("defeq_positive",round,24,()=>sessionEq(fuel,originalSession,beta,sort0),
    r=>ok(r,"defeq_positive").fst===true);
  run("defeq_negative",round,24,()=>sessionEq(fuel,originalSession,sort0,sort1),
    r=>ok(r,"defeq_negative").fst===false);
  run("infer_sort",round,32,()=>sessionInfer(fuel,originalSession,sort0),
    r=>eq(ok(r,"infer_sort").fst,sort1));
  let warm=originalSession;
  run("warm_infer",round,32,()=>{
    const outcome=sessionInfer(fuel,warm,sort0);
    warm=ok(outcome,"warm_infer").snd;
    return outcome;
  },r=>eq(ok(r,"warm_infer").fst,sort1));
  run("checked_application_16",round,12,()=>sessionCheck(fuel,checkedSession,application),
    r=>eq(ok(r,"checked_application_16").fst,sort0));
  run("inferred_application_16",round,12,()=>sessionInfer(fuel,checkedSession,application),
    r=>eq(ok(r,"inferred_application_16").fst,sort0));
  let env=checkedEnv;
  const base=Name.num(Name.str(Name.anonymous,"JsComparedDefinitions"),BigInt(round));
  run("admit_checked_definitions",round,8,(i)=>{
    const name=Name.num(base,BigInt(i));
    const info={base:{name,levelParams:nil,type:sort0},value:application,
      hints:Hints.abbrevHint,safety:Safety.safe};
    const outcome=admitDefinition(fuel,env,info,depth,maxNat);
    env=ok(outcome,"admit_checked_definitions");
    demand(exists(env,name)===true,"accepted definition visible");
    return outcome;
  },r=>!!r && "value" in r);
  const invalidName=Name.num(base,9n);
  const invalid={base:{name:invalidName,levelParams:nil,type:sort1},value:application,
    hints:Hints.abbrevHint,safety:Safety.safe};
  run("reject_wrong_type",round,3,()=>admitDefinition(fuel,env,invalid,depth,maxNat),
    r=>rejected(r,"reject_wrong_type"));
  const typeName=Name.num(Name.str(Name.anonymous,"JsComparedEnum"),BigInt(round));
  const ctorName=Name.str(typeName,"mk");
  const enumDecl={levelParams:nil,name:typeName,type:sort1,
    ctors:List.cons({name:ctorName,type:Expr.const(typeName,nil)},nil),
    isUnsafe:false,numParams:0n};
  run("admit_ordinary_inductive",round,2,()=>addInductive(fuel,empty,enumDecl,depth,maxNat),
    r=>exists(ok(r,"admit_ordinary_inductive"),typeName)===true);
  const left=Name.num(Name.str(Name.anonymous,"JsMutual"),BigInt(round*2));
  const right=Name.num(Name.str(Name.anonymous,"JsMutual"),BigInt(round*2+1));
  const types=List.cons({name:left,type:sort1,
      ctors:List.cons({name:Name.str(left,"mk"),type:Expr.const(left,nil)},nil)},
    List.cons({name:right,type:sort1,
      ctors:List.cons({name:Name.str(right,"mk"),type:Expr.const(right,nil)},nil)},nil));
  const mutualDecl={levelParams:nil,numParams:0n,types,isUnsafe:false};
  run("admit_mutual_inductive",round,1,()=>addMutual(fuel,empty,mutualDecl,depth,maxNat),
    r=>{const e=ok(r,"admit_mutual_inductive");return exists(e,left)===true && exists(e,right)===true;});
}
const summary={label,import_ms:Number(importMs.toFixed(3)),
  rss_bytes:process.memoryUsage().rss,
  max_rss_kib:process.resourceUsage().maxRSS,
  operations:results.length,all_correct:true};
console.log("PSC1_JS_WHOLE_SUMMARY "+JSON.stringify(summary));
