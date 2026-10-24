import {pathToFileURL} from "node:url";
import path from "node:path";
const filename=process.argv[2];
if(!filename)throw Error("PSC1_ADMISSION_PUBLIC_REQUIRES_GENERATED_KERNEL");
const k=await import(pathToFileURL(path.resolve(filename)).href);
const get=n=>{if(!(n in k))throw Error("PSC1_ADMISSION_PUBLIC_MISSING_EXPORT "+n);return k[n];};
const unit=x=>typeof x==="function"?x():x;
const same=(a,b)=>{
 if(a===b)return true;
 if(a===null||b===null||typeof a!=="object"||typeof b!=="object")return false;
 const keys=Reflect.ownKeys(a),other=Reflect.ownKeys(b);
 return keys.length===other.length&&keys.every(key=>Object.hasOwn(b,key)&&same(a[key],b[key]));
};
const capture=value=>{
 if(value===null||typeof value!=="object")return value;
 if(Array.isArray(value))return value.map(capture);
 const result={};for(const key of Reflect.ownKeys(value))result[key]=capture(value[key]);
 return result;
};
const ok=(value,label)=>{
 if(value&&Object.hasOwn(value,"value"))return value.value;
 throw Error("PSC1_ADMISSION_PUBLIC_UNEXPECTED_ERROR "+label+" "+String(value?.error?.message??value?.error));
};
const Option=get("Option"),Except=get("Except"),List=get("List");
const none=unit(Option.none),nil=unit(List.nil);
const list=values=>values.reduceRight((tail,head)=>List.cons(head,tail),nil);
const array=values=>{const result=[];while(values&&Object.hasOwn(values,"head")){result.push(values.head);values=values.tail;}return result;};
const attempt=(value,label)=>{
 if(same(value,none))throw Error("PSC1_ADMISSION_PUBLIC_UNEXPECTED_DECLINE "+label);
 return ok(ok(value,label+"-option"),label);
};
const Err=get("PsKernelError"),N=get("PsKernelName"),L=get("PsKernelLevel"),E=get("PsKernelExpr");
const D=get("PsKernelDagDeclarationRequest"),C=get("PsKernelDagCommand"),Reply=get("PsKernelDagReply");
const safe=unit(get("PsKernelDefinitionSafety").safe);
const rejected=value=>value&&Object.hasOwn(value,"error")&&
 typeof value.error?.message==="string"&&same(value.error,Err.rejectedInvalid(value.error.message));
let assertions=0;
const sections={harness:0,routing:0,boundary:0},labels=[];
const require=(label,condition)=>{
 if(condition!==true)throw Error("PSC1_ADMISSION_PUBLIC_FAIL "+label);
 const section=label.split("/")[0];
 if(!(section in sections)||labels.includes(label))throw Error("PSC1_ADMISSION_PUBLIC_BAD_LABEL "+label);
 assertions++;sections[section]++;labels.push(label);
 console.log("PSC1_ADMISSION_PUBLIC_ASSERT "+label);
};
let harness=false;try{require("harness/forced-failure",false);}catch{harness=true;}
require("harness/rejection-active",harness);
const name=N.str(unit(N.anonymous),"T05PublicUnit"),ctorName=N.str(name,"mk");
const recName=get("psKernelSimpleRecName")(name),one=L.succ(unit(L.zero));
const s=ok(get("psKernelExprV2PagedMkSort")(unit(get("psKernelExprV2PagedEmpty")),one),"sort");
const t=ok(get("psKernelExprV2PagedMkConst")(s.fst,name,nil),"datatype");
const r=ok(get("psKernelExprV2PagedMkConst")(t.fst,recName,list([one])),"recursor");
const arena=r.fst;
const input=ok(get("psKernelExprV2DecodeCanonicalFuel")(
 arena.size+1n,arena,unit(get("psKernelExprV2DecodedEmpty")),0n),"decode");
const value={name,type:s.snd,ctors:list([{name:ctorName,type:t.snd}])};
const request=D.ordinaryInductive(nil,0n,value,false);
const declaration=ok(get("psKernelDagDecodeDeclaration")(input,request),"request");
const session=ok(get("psKernelKernelSessionEmpty")(
 unit(get("psKernelResourcePolicyDefault")),unit(get("psKernelProviderDefault"))),"empty");
const owner=ok(get("psKernelDagGeneratedFromSession")(session,arena,input),"session-owner");
const execution={session,declarations:owner.declarations};
const before=capture({session,owner,input});
const checked=attempt(get("psKernelExprV2OrdinaryAdmitWithFuel")(
 4096n,get("psKernelKernelSessionEnvironment")(session),
 session.resources.maxRecDepth,session.resources.maxNatSize,input,owner,nil,0n,value,false),"private");
const hasRecursor=refs=>array(refs).some(ref=>same(ref.name,recName)&&
 ref.kind&&Object.hasOwn(ref.kind,"rules")&&array(ref.kind.rules).length===1);
const direct=ok(get("psKernelDagRunOwnedCommandWithSource")(
 input,execution,nil,safe,owner.arena,owner.built,C.admit(request)),"direct");
require("routing/direct-owner-retained",
 direct.owner.arena.size===checked.owner.arena.size&&
 direct.owner.built.size===checked.owner.built.size&&
 direct.owner.arena.size===direct.owner.built.size&&hasRecursor(direct.owner.declarations)&&
 get("psKernelEnvironmentContains")(direct.execution.session.environment,name)&&
 get("psKernelEnvironmentContains")(direct.execution.session.environment,ctorName)&&
 get("psKernelEnvironmentContains")(direct.execution.session.environment,recName));
const marker=E.sort(L.succ(L.succ(L.succ(unit(L.zero)))));
const imported=ok(get("psKernelDagGeneratedImport")(marker,checked.owner),"marker");
const marked={environment:checked.environment,owner:imported.fst};
const run=(callback,ex=execution,ar=owner.arena,bu=owner.built,req=request,decl=declaration)=>
 get("psKernelDagRunOrdinaryOwnedWith")(callback,input,ex,nil,safe,ar,bu,req,decl);
const published=ok(run(_=>Option.some(Except.ok(marked))),"finish-marker");
const markerResult=ok(get("psKernelExprV2DecodedRequire")(published.owner.built,imported.snd),"marker-result");
require("routing/finish-carries-injected-suffix",
 published.owner.arena.size===imported.fst.arena.size&&
 published.owner.built.size===imported.fst.built.size&&
 get("psKernelExprEqual")(markerResult,marker)&&hasRecursor(published.execution.declarations));
const declined=ok(run(_=>none),"declined");
const fallback=ok(get("psKernelDagRunFallbackOwnedCommandWithSource")(
 input,execution,nil,safe,owner.arena,owner.built,C.admit(request)),"fallback");
require("routing/decline-restarts-original",
 same(declined.reply,fallback.reply)&&declined.owner.arena.size===fallback.owner.arena.size&&
 declined.owner.built.size===fallback.owner.built.size&&hasRecursor(declined.owner.declarations)&&
 !get("psKernelEnvironmentContains")(session.environment,name));
const failed=run(_=>Option.some(Except.error("expected sort")));
require("routing/hard-error-does-not-fallback",
 failed&&same(failed.error,Err.rejectedInvalid("expected sort")));
const limited={...session,resources:{...session.resources,maxDeclarations:1n}};
const refused=get("psKernelDagFinishOwnedOrdinaryAdmission")(limited,declaration,checked);
require("routing/resource-limit-failure",refused&&same(refused.error,
 Err.resourceExhausted(unit(get("PsKernelResourceError").declarationLimit),"declaration limit exceeded")));
const batch=ok(get("psKernelV1RunDag")(
 session,nil,safe,arena,list([C.admit(request),C.check(r.snd)])),"batch");
const replies=array(batch.replies);
require("routing/same-batch-recursor-check",
 replies.length===2&&replies[0].receipt?.declarationsBefore===0n&&
 replies[0].receipt?.declarationsAfter===3n&&
 same(replies[0],Reply.admitted(replies[0].receipt))&&
 Object.hasOwn(replies[1],"value")&&same(replies[1],Reply.checked(replies[1].value)));
const later=ok(get("psKernelV1RunDag")(
 batch.session,nil,safe,arena,list([C.check(r.snd)])),"cross-call");
const laterReplies=array(later.replies);
require("routing/cross-call-checked-recursor",
 laterReplies.length===1&&Object.hasOwn(laterReplies[0],"value")&&
 same(laterReplies[0],Reply.checked(laterReplies[0].value))&&
 get("psKernelEnvironmentContains")(later.session.environment,recName));
require("boundary/private-generated-id-not-external",rejected(get("psKernelV1RunDag")(
 session,nil,safe,arena,list([C.admit(request),C.check(input.size)]))));
require("boundary/later-command-failure-atomic",rejected(get("psKernelV1RunDag")(
 session,nil,safe,arena,list([C.admit(request),C.admit(request)])))&&
 !get("psKernelEnvironmentContains")(session.environment,name)&&
 get("psKernelEnvironmentSize")(session.environment)===0n&&same(before,{session,owner,input}));
const extra=ok(get("psKernelDagGeneratedImport")(E.sort(one),owner),"original-owner-append");
const badValue={name,type:extra.snd,ctors:nil};
const badRequest=D.ordinaryInductive(nil,0n,badValue,false);
const badDeclaration=ok(get("psKernelDagDecodeDeclaration")(extra.fst.built,badRequest),"internal-only-request");
require("boundary/fallback-original-bounds",
 rejected(run(_=>none,execution,extra.fst.arena,extra.fst.built,badRequest,badDeclaration)));
const cancelled={...session,resources:{...session.resources,cancelled:true}};
const cancelledExecution={session:cancelled,declarations:owner.declarations};
const preflight=run(_=>Option.some(Except.error("expected sort")),cancelledExecution);
require("boundary/preflight-precedence",preflight&&same(preflight.error,
 Err.resourceExhausted(unit(get("PsKernelResourceError").cancelled),"resource policy declined operation before entry")));
if(assertions!==12||!same(sections,{harness:1,routing:7,boundary:4}))
 throw Error("PSC1_ADMISSION_PUBLIC_BAD_INVENTORY");
for(const [section,count]of Object.entries(sections))console.log("PSC1_ADMISSION_PUBLIC_SECTION "+section+"="+count);
console.log(JSON.stringify({schema:"psc1-ordinary-admission-public-v1",kernel:filename,
 assertions,sectionAssertions:sections,assertionLabels:labels,
 publicRoutingChanged:true,ordinaryAdmission:true,fullKernel:false,performanceQualified:false}));
console.log("PSC1_ORDINARY_ADMISSION_PUBLIC_JS: PASS assertions=12 publicRoutingChanged=true ordinaryAdmission=true");
