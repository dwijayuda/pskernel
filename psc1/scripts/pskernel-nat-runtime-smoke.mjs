import { spawnSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";
import path from "node:path";
import { performance } from "node:perf_hooks";

const filename=process.argv[2];
if(!filename)throw Error("PSC1_NAT_REQUIRES_GENERATED_KERNEL");
// A regression must terminate this gate instead of constructing a fuel-sized
// closure chain for a 129-bit numeral. The kernel policy itself stays unchanged.
if(process.argv[3]!=="--worker"){
  const result=spawnSync(process.execPath,[
    "--expose-gc",fileURLToPath(import.meta.url),path.resolve(filename),"--worker"
  ],{encoding:"utf8",timeout:30000,maxBuffer:2*1024*1024,env:{...process.env,PATH:""}});
  if(result.stdout)process.stdout.write(result.stdout);
  if(result.stderr)process.stderr.write(result.stderr);
  if(result.error)throw result.error;
  if(result.status!==0)throw Error("PSC1_NAT_WORKER_FAILED status="+result.status);
}else{
  const started=performance.now(),k=await import(pathToFileURL(path.resolve(filename)).href);
  const get=name=>{
    if(!(name in k))throw Error("PSC1_NAT_MISSING_EXPORT "+name);
    return k[name];
  };
  let assertions=0;
  const must=(condition,label)=>{
    if(condition!==true)throw Error("PSC1_NAT_FAILED "+label);
    assertions++;
  };
  const accepted=(result,label)=>{
    if(result&&typeof result==="object"&&"value" in result)return result.value;
    throw Error("PSC1_NAT_REJECTED "+label);
  };
  const rejected=result=>result&&typeof result==="object"&&"error" in result;
  const same=(left,right)=>{
    if(left===right)return true;
    if(left===null||right===null||typeof left!=="object"||typeof right!=="object")return false;
    const keys=Reflect.ownKeys(left),others=Reflect.ownKeys(right);
    return keys.length===others.length&&keys.every(key=>
      Object.hasOwn(right,key)&&same(left[key],right[key]));
  };
  const b63=1n<<63n,b64=1n<<64n,b128=1n<<128n;
  for(const [value,words,bytes]of [[0n,0n,8n],[b63,1n,8n],
      [b64-1n,1n,8n],[b64,2n,16n],[b128,3n,24n],[b128+31n,3n,24n]]){
    must(get("psKernelNatHeapWordCount")(value)===words,"heap-word-count-"+value);
    must(get("psKernelNatSizeInBytes")(value)===bytes,"numeral-bytes-"+value);
    accepted(get("psKernelCheckNatSize")(bytes,value),"exact-size");
    must(rejected(get("psKernelCheckNatSize")(bytes-1n,value)),"size-below-boundary");
  }
  must(get("psKernelNatGcd")(3n*b128,5n*b128)===b128,"large-gcd");
  must(get("psKernelNatGcd")(b128+1n,b128)===1n,"large-coprime-gcd");
  must(get("psKernelNatPow")(0n,4294967295n)===0n,"large-exponent-zero");
  must(get("psKernelNatPow")(1n,4294967295n)===1n,"large-exponent-one");
  must(get("psKernelNatPow")(2n,128n)===b128,"power-result");
  const Op=get("PsKernelNatBitwiseOp"),left=b128+31n,right=b128+85n;
  for(const [op,expected]of [[Op.land,left&right],[Op.lor,left|right],[Op.xor,left^right]])
    must(get("psKernelNatBitwise")(op,left,right)===expected,"large-bitwise");
  must(get("psKernelNatShiftRight")(left,128n)===1n,"large-shift-right");
  must(get("psKernelNatShiftRight")(left,4294967296n)===0n,"huge-right-count");
  must(get("psKernelNatGcdWithFuel")(0n)(17n)(9n)===17n,"zero-fuel-gcd");
  must(get("psKernelNatHeapWordCountWithFuel")(0n)(b128)===0n,"zero-fuel-words");
  must(get("psKernelNatHeapWordCountWithFuel")(1n)(b128)===1n,"one-fuel-words");
  must(get("psKernelNatPowWithFuel")(0n)(2n)(128n)===1n,"zero-fuel-pow");
  must(get("psKernelNatBitwiseWithFuel")(0n)(Op.lor)(left)(right)===0n,"zero-fuel-bitwise");
  must(get("psKernelNatShiftRightWithFuel")(0n)(left)(128n)===left,"zero-fuel-shift");
  must(get("psKernelNatShiftRightWithFuel")(1n)(left)(128n)===left/2n,"one-fuel-shift");
  const primitive=get("psKernelReduceNatBinaryValue");
  const reduced=(op,a,b)=>accepted(accepted(primitive(1024n,get(op),a,b),op),op+"-some");
  must(reduced("psKernelNatPowName",1n,4294967295n).value===1n,"checked-large-exponent");
  must(reduced("psKernelNatShiftLeftName",0n,4294967296n).value===0n,
    "zero-left-before-count-guard");
  const tooLarge=primitive(1024n,get("psKernelNatPowName"),1n,4294967296n);
  must(rejected(tooLarge)&&tooLarge.error===
    "the kernel refused to evaluate Nat.pow because its second argument does not fit in a 32-bit unsigned integer",
    "exact-pow-count-error");

  const N=get("PsKernelName"),L=get("PsKernelLevel"),E=get("PsKernelExpr");
  const Lit=get("PsKernelLiteral"),B=get("PsKernelBinderInfo"),S=get("PsKernelDefinitionSafety");
  const C=get("PsKernelDagCommand"),D=get("PsKernelDagDeclarationRequest");
  const Request=get("PsKernelDeclarationRequest"),List=get("List");
  const nil=typeof List.nil==="function"?List.nil():List.nil;
  const list=values=>values.reduceRight((tail,head)=>List.cons(head,tail),nil);
  const array=values=>{
    const result=[];while(values&&"head" in values){result.push(values.head);values=values.tail;}
    return result;
  };
  const name=text=>N.str(N.anonymous,text),sort1=E.sort(L.succ(L.zero));
  const natName=get("psKernelNatName"),nat=E.const(natName,nil),numeral=n=>E.lit(Lit.nat(n));
  const equal=(a,b)=>get("psKernelExprEqual")(a)(b);
  const initial=accepted(get("psKernelKernelSessionEmpty")(
    get("psKernelResourcePolicyDefault"),get("psKernelProviderDefault")),"empty-session");
  must(initial.resources.fuel===4096n,"unchanged-published-fuel");
  const natSession=accepted(get("psKernelV1AdmitDeclaration")(initial,Request.ordinaryInductive({
    levelParams:nil,name:natName,type:sort1,numParams:0n,isUnsafe:false,
    ctors:list([{name:get("psKernelNatZeroName"),type:nat},
      {name:get("psKernelNatSuccName"),type:E.forallE(name("n"),nat,nat,B.default)}])
  })),"real-Nat-admission").session;
  let arena=get("psKernelExprV2PagedEmpty");
  const mk=(kind,...args)=>{
    const result=accepted(get("psKernelExprV2PagedMk"+kind)(arena,...args),"build-"+kind);
    arena=result.fst;return result.snd;
  };
  const natId=mk("Const",natName,nil),sortId=mk("Sort",L.succ(L.zero));
  const succId=mk("Const",get("psKernelNatSuccName"),nil);
  const large=mk("Lit",Lit.nat(b128)),other=mk("Lit",Lit.nat(b128+1n));
  const successor=mk("App",succId,large),term=E.app(E.const(get("psKernelNatSuccName"),nil),numeral(b128));
  const invoke=(session,commands)=>get("psKernelV1RunDag")(session,nil,S.safe,arena,list(commands));
  const checked=accepted(get("psKernelV1CheckExpression")(natSession,nil,S.safe,numeral(b128)),"legacy-check");
  must(equal(checked.type,nat),"legacy-large-literal-type");
  must(equal(accepted(get("psKernelV1Whnf")(natSession,nil,S.safe,term),"legacy-succ"),numeral(b128+1n)),
    "legacy-large-succ");
  const replies=array(accepted(invoke(natSession,[
    C.check(large),C.whnf(successor),C.isDefEq(large,large),C.isDefEq(large,other)
  ]),"full-DAG-large-checks").replies);
  must(replies.length===4&&equal(replies[0].value.type,nat)&&
    equal(replies[1].value,numeral(b128+1n))&&replies[2].value===true&&replies[3].value===false,
    "complete-DAG-positive-and-negative");
  const bounded={...natSession,resources:{...natSession.resources,maxNatSize:16n}};
  const originalRejected=get("psKernelV1CheckExpression")(bounded,nil,S.safe,numeral(b128));
  const dagRejected=invoke(bounded,[C.check(large)]);
  must(rejected(originalRejected)&&rejected(dagRejected)&&same(originalRejected.error,dagRejected.error)&&
    same(dagRejected.error.resource,get("PsKernelResourceError").natSize),"same-Nat-size-rejection");
  const goodName=name("DagLargeNumeral"),constant=mk("Const",goodName,nil);
  const definition={base:{name:goodName,levelParams:nil,type:natId},
    value:large,hints:get("PsKernelReducibilityHints").abbrevHint,safety:S.safe};
  const admitted=array(accepted(invoke(natSession,[
    C.admit(D.definitionDecl(definition)),C.whnf(constant)
  ]),"large-declaration-and-unfold").replies);
  must(admitted.length===2&&equal(admitted[1].value,numeral(b128)),"large-declaration-result");
  const invalid=invoke(natSession,[C.admit(D.definitionDecl({
    ...definition,base:{...definition.base,type:sortId}
  }))]);
  must(rejected(invalid)&&same(get("psKernelErrorOutcome")(invalid.error),
    get("PsKernelOutcome").rejectedInvalid),"illtyped-large-declaration-rejected");
  const limited=invoke(bounded,[C.admit(D.definitionDecl(definition))]);
  must(rejected(limited)&&same(limited.error.resource,get("PsKernelResourceError").natSize),
    "large-declaration-size-limit");
  if(global.gc)global.gc();
  console.log("PSC1_NAT_LARGE_RUNTIME "+JSON.stringify({
    assertions,fuel:String(natSession.resources.fuel),wall_ms:performance.now()-started,
    peak_rss_kib:process.resourceUsage().maxRSS,post_gc_heap_bytes:process.memoryUsage().heapUsed,
    scope:"one generated-worker regression; not an A-B performance comparison"
  }));
  console.log("PSC1_NAT_LARGE_RUNTIME: PASS");
}
