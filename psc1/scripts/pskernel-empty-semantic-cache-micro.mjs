// One authenticated generated leaf and one frozen case per fresh process.
// Report loop-plus-result-consumption cost; all semantic checks stay outside it.
import {readFileSync} from "node:fs";
import {createHash} from "node:crypto";
import {resolve} from "node:path";
import {fileURLToPath,pathToFileURL} from "node:url";

const fail=message=>{throw Error("PSC1_EMPTY_CACHE_MICRO_FAIL "+message);};
const ensure=(condition,message)=>{if(condition!==true)fail(message);};
const sha256=bytes=>createHash("sha256").update(bytes).digest("hex");
const own=(object,key)=>Object.hasOwn(object,key);
const sourcePins={
 baseline:{source:"20224a295359abb201f56c72395690bf0bfac9fa",bytes:360259,
  sha256:"47c320361a197b3bfe4eeb16c7a95375ceed26869375d1fd941ed7c2cb34021e"},
 candidate:{source:"e503972553ae2d41d5ba7a26d7739fb32ee86b96",bytes:360611,
  sha256:"067b7c540f340ccfc12b730156f5fdee0fa288ec4b784640f788a8e1eec0d554"}
};
const rows=[
 ["empty/shallow","empty","hit",1,1000000],
 ["empty/deep","empty","deep",1,10000],
 ["empty/early-open","empty","early",1,1000000],
 ["empty/late-open","empty","late",1,10000],
 ["small/hit","small","hit",2,1000000],
 ["small/deep-miss","small","deep",1,10000],
 ["small/early-open","small","early",1,1000000],
 ["small/late-open","small","late",1,10000],
 ["indexed/hit","indexed","hit",2,1000000],
 ["indexed/deep-miss","indexed","deep",1,10000],
 ["indexed/early-open","indexed","early",1,1000000],
 ["indexed/late-open","indexed","late",1,10000],
 ["small/shallow-miss","small","miss",1,1000000],
 ["indexed/shallow-miss","indexed","miss",1,1000000]
];
const configKeys=["schema","experimentSourceSha","runId","runAttempt","job",
 "sequenceOrdinal","caseIndex","caseId","variant","abbaPosition","kernelSourceSha",
 "kernelSha256","nodeSha256","warmupCalls","measuredCalls"];
ensure(process.argv.length===4,"usage: worker.mjs <kernel.mjs> <case-config.json>");
const kernelPath=resolve(process.argv[2]),configPath=resolve(process.argv[3]);
const config=JSON.parse(readFileSync(configPath,"utf8"));
ensure(config!==null&&typeof config==="object"&&!Array.isArray(config),"config object");
ensure(Object.keys(config).length===configKeys.length&&configKeys.every(key=>own(config,key)),
 "exact config keys");
ensure(config.schema==="psc1-empty-cache-micro-case-v1","config schema");
ensure(/^[0-9a-f]{40}$/.test(config.experimentSourceSha),"experiment source");
for(const field of ["runId","runAttempt"])
 ensure(typeof config[field]==="string"&&/^[1-9][0-9]*$/.test(config[field]),field);
ensure(typeof config.job==="string"&&config.job.length>0,"job");
for(const [field,env] of [["experimentSourceSha","GITHUB_SHA"],["runId","GITHUB_RUN_ID"],
 ["runAttempt","GITHUB_RUN_ATTEMPT"],["job","GITHUB_JOB"]])
 ensure(config[field]===process.env[env],"real environment "+field);
ensure(Number.isInteger(config.caseIndex)&&config.caseIndex>=0&&config.caseIndex<rows.length,
 "case index");
ensure(Number.isInteger(config.abbaPosition)&&config.abbaPosition>=0&&config.abbaPosition<4,
 "ABBA position");
ensure(Number.isInteger(config.sequenceOrdinal)&&
 config.sequenceOrdinal===4*config.caseIndex+config.abbaPosition,"sequence ordinal");
ensure(config.variant===["baseline","candidate","candidate","baseline"][config.abbaPosition],
 "ABBA variant");
const row=rows[config.caseIndex],pin=sourcePins[config.variant];
ensure(config.caseId===row[0]&&config.warmupCalls===4096&&config.measuredCalls===row[4],
 "frozen case and call counts");
ensure(config.kernelSourceSha===pin.source&&config.kernelSha256===pin.sha256,"kernel source pin");
ensure(process.version==="v22.23.3","captured Node version");
ensure(process.platform==="linux","Linux runner");
ensure(process.env.PATH===""&&process.env.NODE_OPTIONS==="","empty runtime paths/options");
ensure(process.execArgv.length===2&&
 process.execArgv.includes("--expose-gc")&&process.execArgv.includes("--max-old-space-size=2048"),
 "fixed Node flags");
ensure(typeof globalThis.gc==="function","explicit GC availability");
const kernelBytes=readFileSync(kernelPath),kernelSha256=sha256(kernelBytes);
ensure(kernelBytes.length===pin.bytes&&kernelSha256===pin.sha256,"actual leaf bytes");
const nodeSha256=sha256(readFileSync(process.execPath));
ensure(typeof config.nodeSha256==="string"&&/^[0-9a-f]{64}$/.test(config.nodeSha256)&&
 nodeSha256===config.nodeSha256,"same authenticated Node executable");
const workerSha256=sha256(readFileSync(fileURLToPath(import.meta.url)));
const k=await import(pathToFileURL(kernelPath).href);
const get=name=>{ensure(own(k,name),"export "+name);return k[name];};
const unit=value=>typeof value==="function"?value():value;
const E=get("PsKernelExpr"),L=get("PsKernelLevel"),N=get("PsKernelName");
const Literal=get("PsKernelLiteral"),List=get("List"),Option=get("Option");
const nil=unit(List.nil),none=unit(Option.none);
const name=text=>N.str(unit(N.anonymous),text),zero=unit(L.zero);
const one=L.succ(zero),two=L.succ(one),three=L.succ(two);
const hit=E.sort(one),value=E.sort(two),miss=E.sort(three);
let deep=E.const(name("EmptyCacheBench.closed"),nil);
for(let i=0;i<256;i++)deep=E.app(deep,E.lit(Literal.nat(BigInt(i%7))));
const free=E.fvar(name("EmptyCacheBench.open"));
const early=E.app(free,deep),late=E.app(deep,free);
const queries={hit,deep,early,late,miss};
const rawGet=get("psKernelExprMapGet"),rawInsert=get("psKernelExprMapInsert");
const semanticGet=get("psKernelSemanticExprMapGet"),eligible=get("psKernelSemanticCacheEligible");
const empty=unit(get("psKernelExprMapEmpty"));
const seeds=[hit,early,late,E.bvar(100n),E.bvar(101n),
 E.const(name("EmptyCacheBench.seed"),nil),E.lit(Literal.nat(5n)),E.lit(Literal.str("seed"))];
let small=empty;
for(const key of seeds)small=rawInsert(small,key,value);
const extra=[1000n,1001n,1002n,1003n].map(index=>E.bvar(index));
let indexed=small;
for(const key of extra)indexed=rawInsert(indexed,key,value);
const maps={empty,small,indexed};
const cache=maps[row[1]],query=queries[row[2]],expectedCode=row[3];
const some=Option.some(value),listCons=List.cons(hit,nil);

// Snapshots are independent copies of every own string/Symbol field and preserve
// alias relationships. Snapshot copies are never passed to generated functions.
function deepSnapshot(value,seen=new Map()){
 if(value===null||typeof value!=="object")return value;
 if(seen.has(value))return seen.get(value);
 const result=Array.isArray(value)?[]:Object.create(Object.getPrototypeOf(value));
 seen.set(value,result);
 for(const key of Reflect.ownKeys(value)){
  const descriptor=Object.getOwnPropertyDescriptor(value,key);
  if(own(descriptor,"value"))descriptor.value=deepSnapshot(descriptor.value,seen);
  Object.defineProperty(result,key,descriptor);
 }
 return result;
}
function deepUnchanged(actual,snapshot,forward=new Map(),reverse=new Map()){
 if(actual===null||snapshot===null||typeof actual!=="object"||typeof snapshot!=="object")
  return actual===snapshot;
 if(forward.has(actual))return forward.get(actual)===snapshot;
 if(reverse.has(snapshot))return false;
 if(Object.getPrototypeOf(actual)!==Object.getPrototypeOf(snapshot))return false;
 const a=Reflect.ownKeys(actual),b=Reflect.ownKeys(snapshot);
 if(a.length!==b.length||!a.every((key,index)=>key===b[index]))return false;
 forward.set(actual,snapshot);reverse.set(snapshot,actual);
 for(const key of a){
  const x=Object.getOwnPropertyDescriptor(actual,key),y=Object.getOwnPropertyDescriptor(snapshot,key);
  if(x.enumerable!==y.enumerable||x.configurable!==y.configurable||
     own(x,"value")!==own(y,"value"))return false;
  if(own(x,"value")){
   if(x.writable!==y.writable||!deepUnchanged(x.value,y.value,forward,reverse))return false;
  }else if(x.get!==y.get||x.set!==y.set)return false;
 }
 return true;
}
const inputs={maps,queries,seeds,extra,value,free};
const snapshot=deepSnapshot(inputs);
const sameKeys=(object,template)=>{
 if(object===null||typeof object!=="object")return false;
 const a=Reflect.ownKeys(object),b=Reflect.ownKeys(template);
 return a.length===b.length&&a.every(key=>own(template,key));
};
function discriminant(left,right,label){
 ensure(left!==null&&right!==null&&typeof left==="object"&&typeof right==="object",
  label+" actual constructor objects");
 const keys=Reflect.ownKeys(left).filter(key=>own(right,key)&&left[key]!==right[key]);
 ensure(keys.length===1,label+" unique actual discriminant");
 return keys[0];
}
const optionTag=discriminant(none,some,"Option"),noneTag=none[optionTag],someTag=some[optionTag];
ensure(noneTag!==someTag&&own(some,"value")&&some.value===value&&!own(none,"value"),
 "actual Option tag/value shape");
function optionShape(result,code,payload){
 const template=code===1?none:some;
 if(!sameKeys(result,template))return false;
 for(const key of Reflect.ownKeys(template))
  if(result[key]!==((code===2&&key==="value")?payload:template[key]))return false;
 return true;
}
const listTag=discriminant(nil,listCons,"List"),nilTag=nil[listTag],consTag=listCons[listTag];
ensure(nilTag!==consTag&&own(listCons,"head")&&own(listCons,"tail"),"actual List shape");
function listLength(list){
 let size=0,current=list;
 const seen=new Set();
 while(current!==null&&typeof current==="object"&&current[listTag]===consTag){
  ensure(!seen.has(current)&&sameKeys(current,listCons),"finite actual list");
  seen.add(current);size++;
  ensure(size<=12,"bounded fixture list");
  current=current.tail;
 }
 ensure(sameKeys(current,nil)&&current[listTag]===nilTag,"actual nil terminator");
 return size;
}
ensure(unit(get("psKernelCacheSmallLimit"))===8n,"published small limit");
ensure(optionShape(empty.index,1)&&listLength(empty.small)===0,"actual empty representation");
ensure(optionShape(small.index,1)&&listLength(small.small)===8,"actual small representation");
ensure(optionShape(indexed.index,2,indexed.index.value)&&listLength(indexed.small)===0,
 "actual indexed representation");

// Both tag and stored payload identity affect each consumed result.
const resultCode=result=>{
 if(result===null||typeof result!=="object")return 0;
 const tag=result[optionTag];
 if(tag===noneTag)return 1;
 if(tag===someTag&&result.value===value)return 2;
 return 0;
};
ensure(resultCode(none)===1&&resultCode(some)===2,"Option observation codes");
ensure(resultCode(Option.some(E.sort(two)))===0&&resultCode(null)===0,
 "invalid payload and result codes");

function semanticControls(){
 for(const key of seeds)ensure(optionShape(rawGet(small,key),2,value),"every small raw seed");
 for(const key of [...seeds,...extra])
  ensure(optionShape(rawGet(indexed,key),2,value),"every indexed raw seed");
 ensure(eligible(hit)===true&&eligible(deep)===true&&eligible(miss)===true,
  "closed query eligibility");
 ensure(eligible(early)===false&&eligible(late)===false,"open query ineligibility");
 for(const [mapName,map] of Object.entries(maps)){
  const hitCode=mapName==="empty"?1:2;
  ensure(optionShape(rawGet(map,hit),hitCode,value),"shallow raw hit "+mapName);
  ensure(optionShape(semanticGet(map,hit),hitCode,value),"shallow semantic hit "+mapName);
  for(const closed of [deep,miss]){
   ensure(optionShape(rawGet(map,closed),1),"closed raw miss "+mapName);
   ensure(optionShape(semanticGet(map,closed),1),"closed semantic miss "+mapName);
  }
  for(const open of [early,late]){
   ensure(optionShape(rawGet(map,open),hitCode,value),"open raw entry "+mapName);
   ensure(optionShape(semanticGet(map,open),1),"open semantic rejection "+mapName);
  }
 }
 ensure(optionShape(semanticGet(cache,query),expectedCode,value),"selected semantic result");
 ensure(deepUnchanged(inputs,snapshot),"all original input snapshots");
}
semanticControls();
const ring=new Array(1024);
globalThis.gc();
let warmupChecksum=0,warmupInvalid=0;
for(let i=0;i<config.warmupCalls;i++){
 const result=semanticGet(cache,query),code=resultCode(result);
 ring[i&1023]=result;
 warmupChecksum=(warmupChecksum+code)>>>0;
 warmupInvalid+=code===0?1:0;
}
ensure(warmupInvalid===0&&warmupChecksum===config.warmupCalls*expectedCode,
 "exact warm-up observations");
ensure(ring.every(result=>optionShape(result,expectedCode,value)),"complete warm-up ring");
ensure(deepUnchanged(inputs,snapshot),"warm-up input snapshots");
ring.fill(undefined);
globalThis.gc();
const before=process.memoryUsage(),memoryBefore={heapUsed:before.heapUsed,rss:before.rss};
let checksum=0,invalidResults=0;
const cpuStart=process.cpuUsage();
const started=process.hrtime.bigint();
for(let i=0;i<config.measuredCalls;i++){
 const result=semanticGet(cache,query),code=resultCode(result);
 ring[i&1023]=result;
 checksum=(checksum+code)>>>0;
 invalidResults+=code===0?1:0;
}
const elapsedNanoseconds=(process.hrtime.bigint()-started).toString();
const cpu=process.cpuUsage(cpuStart);
const after=process.memoryUsage(),memoryAfter={heapUsed:after.heapUsed,rss:after.rss};
ensure(invalidResults===0&&checksum===config.measuredCalls*expectedCode,
 "exact measured observations");
ensure(ring.length===1024&&ring.every(result=>optionShape(result,expectedCode,value)),
 "complete measured result ring");
ensure(deepUnchanged(inputs,snapshot),"measured input snapshots");
semanticControls();
ensure(/^[1-9][0-9]*$/.test(elapsedNanoseconds),"positive measured interval");
for(const amount of [cpu.user,cpu.system,memoryBefore.heapUsed,memoryBefore.rss,
 memoryAfter.heapUsed,memoryAfter.rss])
 ensure(Number.isSafeInteger(amount)&&amount>=0,"finite process measurement");
ensure(sha256(readFileSync(kernelPath))===kernelSha256,"unchanged executed leaf file");
const maxRssKiB=process.resourceUsage().maxRSS;
ensure(Number.isSafeInteger(maxRssKiB)&&maxRssKiB>=0,"whole-process maxRSS");
const observation={
 schema:"psc1-empty-cache-micro-observation-v1",status:"pass",config,workerSha256,
 kernelSha256,nodeVersion:process.version,nodeSha256,mapShape:row[1],queryShape:row[2],
 expectedResult:expectedCode===1?"none":"some(value)",expectedCode,warmupChecksum,checksum,
 invalidResults,elapsedNanoseconds,cpuUserMicroseconds:cpu.user,cpuSystemMicroseconds:cpu.system,
 memoryBefore,memoryAfter,maxRssKiB,maxRssScope:"whole-process-including-import-and-setup",
 gcCalls:2,controlsPassed:true,ringValidated:true,inputsUnchanged:true,optionShapeValidated:true,
 loopIncludesResultConsumption:true,fullKernel:false,performanceQualified:false
};
console.log("PSC1_EMPTY_CACHE_MICRO_OBSERVATION: PASS "+JSON.stringify(observation));
