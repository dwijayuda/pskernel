import {pathToFileURL} from "node:url";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

/*
Run the real original and opt-in generated modules, after authentic source
admission and pinned TS7 compilation. No compiler decision or kernel outcome is
reconstructed here. Independent tiny models specify fixture arithmetic/radix
outputs; actual callbacks test order, multiplicity, partial captures and throws.
*/
let assertions=0;
const insist=(condition,label)=>{assertions++;if(condition!==true)throw Error("SATURATION_JS "+label);};
const unit=value=>typeof value==="function"?value():value;
const digest=bytes=>crypto.createHash("sha256").update(bytes).digest("hex");
const inspectFile=filename=>{
 const resolved=path.resolve(filename);
 const bytes=fs.readFileSync(resolved);
 return {path:resolved,bytes:bytes.length,sha256:digest(bytes)};
};
const [sourceOriginalArg,sourceOptimizedArg,modelOriginalArg,modelOptimizedArg]=process.argv.slice(2);
insist(sourceOriginalArg&&sourceOptimizedArg&&modelOriginalArg&&modelOptimizedArg,
 "usage: original-fixture.js optimized-fixture.js original-model.js optimized-model.js");
insist(process.env.PATH==="","detached execution requires empty PATH");
insist(process.version.startsWith("v22."),"Node22 required");
const identities=[sourceOriginalArg,sourceOptimizedArg,modelOriginalArg,modelOptimizedArg].map(inspectFile);
const modules=await Promise.all(identities.map(row=>import(pathToFileURL(row.path).href)));
const [sourceOriginal,sourceOptimized,modelOriginal,modelOptimized]=modules;
const comparable=value=>JSON.stringify(value,(_,field)=>typeof field==="bigint"?field.toString()+"n":field);
const equal=(left,right,label)=>insist(comparable(left)===comparable(right),label);
for(const [left,right,label] of [[sourceOriginal,sourceOptimized,"source"],[modelOriginal,modelOptimized,"model"]]){
 equal(Object.keys(left).sort(),Object.keys(right).sort(),label+" exact public export set");
 for(const name of Object.keys(left))if(typeof left[name]==="function"){
  insist(typeof right[name]==="function"&&left[name].length===right[name].length,
   label+" public entry arity "+name);
 }
 insist(!Object.keys(right).some(name=>name.startsWith("__ps$stage$")&&name!=="__ps$stage$0"),
  label+" no private helper export");
}
for(const [old,next] of [[identities[0],identities[1]],[identities[2],identities[3]]]){
 const declaration=filename=>filename.replace(/\.js$/,".d.ts");
 insist(fs.readFileSync(declaration(old.path),"utf8")===fs.readFileSync(declaration(next.path),"utf8"),
  "exact emitted public declarations");
 for(const item of [old,next]){
  const map=JSON.parse(fs.readFileSync(item.path+".map","utf8"));
  insist(map.version===3&&Array.isArray(map.sources)&&map.sources.length>0,"real source map");
 }
}

function fixtureApi(module){
 const List=module.List,Index=module.SatIndex;
 insist(List&&Index,"real generated fixture constructors");
 const nil=unit(List.nil);
 const list=values=>values.reduceRight((tail,head)=>List.cons(head,tail),nil);
 const array=values=>{
  const result=[];
  while(values&&Object.hasOwn(values,"head")){result.push(values.head);values=values.tail;}
  return result;
 };
 const empty=unit(Index.empty);
 const tag=Object.getOwnPropertySymbols(empty).find(symbol=>typeof empty[symbol]==="string");
 insist(tag!==undefined,"actual generated index discriminator");
 const encode=model=>model.kind==="empty"?empty:model.kind==="bucket"?
  Index.bucket(list(model.entries)):Index.branch(encode(model.left),encode(model.right));
 const decode=value=>{
  const kind=value[tag];
  if(kind==="empty")return {kind};
  if(kind==="bucket")return {kind,entries:array(value.entries)};
  insist(kind==="branch","actual generated index result shape");
  return {kind,left:decode(value.left),right:decode(value.right)};
 };
 return {module,list,array,encode,decode,empty};
}
const empty={kind:"empty"},bucket=entries=>({kind:"bucket",entries});
const branch=(left,right)=>({kind:"branch",left,right});
const lookup=(levels,index,hash)=>{
 if(levels===0)return index.kind==="bucket"?index.entries:[];
 if(index.kind!=="branch")return [];
 return lookup(levels-1,hash%2n===0n?index.left:index.right,hash/2n);
};
const set=(levels,index,hash,entries)=>{
 if(levels===0)return bucket(entries);
 const left=index.kind==="branch"?index.left:empty,right=index.kind==="branch"?index.right:empty;
 return hash%2n===0n?branch(set(levels-1,left,hash/2n,entries),right):
  branch(left,set(levels-1,right,hash/2n,entries));
};
const hashes=[0n,1n,2n,17n,18446744073709551629n,1180591620717411303455n];
const malformed=[empty,bucket([9n,9n]),branch(bucket([4n]),empty),
 branch(empty,branch(bucket([3n]),bucket([5n])))];
// Existing __ps$wrap uses (...args), so returned functions have JS length zero.
// Unary staging is checked by each ordered application and the identical .d.ts.
let radix=0,partials=0;
for(const module of [sourceOriginal,sourceOptimized]){
 const api=fixtureApi(module);
 insist(module.satLookupWorker.length===3&&module.satSetWorker.length===4,"flat source worker ABI");
 insist(module.satLookup.length===1&&module.satSet.length===1,"public staged wrapper ABI");
 for(const levels of [0,1,2,8,16])for(const initial of malformed)for(const hash of hashes){
  const input=api.encode(initial),level=BigInt(levels),values=[hash,level,hash];
  equal(api.array(module.satLookupWorker(level,input,hash)),lookup(levels,initial,hash),"raw lookup model");
  const changed=module.satSetWorker(level,input,hash,api.list(values));
  equal(api.decode(changed),set(levels,initial,hash,values),"persistent setter model");
  equal(api.decode(input),initial,"input retained");
  const lookup1=module.satLookup(level),lookup2=lookup1(changed);
  insist(typeof lookup1==="function"&&typeof lookup2==="function"&&
   lookup1.length===0&&lookup2.length===0,"lookup partials retain runtime rest-wrapper ABI");
  equal(api.array(lookup2(hash)),values,"partial lookup value");
  equal(api.array(lookup2(hash+(1n<<level))),values,"exact hash bucket collision");
  const set1=module.satSet(level),set2=set1(input),set3=set2(hash);
  insist(typeof set1==="function"&&typeof set2==="function"&&typeof set3==="function"&&
   set1.length===0&&set2.length===0&&set3.length===0,"setter partials retain runtime rest-wrapper ABI");
  equal(api.decode(set3(api.list(values))),api.decode(changed),"partial setter value");
  equal(api.decode(set3(api.list([1n,2n]))),set(levels,initial,hash,[1n,2n]),"reused setter closure");
  equal(api.array(lookup2(hash)),values,"separate previous closure capture");
  radix++;partials+=5;
 }
 // Repeated writes test disjoint paths, exact collisions and duplicate buckets.
 let current=api.empty,model=empty;
 for(const [i,hash] of hashes.entries()){
  const values=[BigInt(i),hash,hash];
  current=module.satSetWorker(16n,current,hash,api.list(values));
  model=set(16,model,hash,values);
  for(const observed of hashes)equal(api.array(module.satLookupWorker(16n,current,observed)),
   lookup(16,model,observed),"multiple persistent writes");
 }
 for(const fuel of [0n,1n,2n,16n,128n,4096n])for(const state of [0n,1n,18446744073709551629n]){
  const staged=module.satStage(fuel),captured=module.satCaptured(fuel,11n);
  insist(typeof staged==="function"&&typeof captured==="function"&&
   staged.length===0&&captured.length===0,"one-stage runtime rest-wrapper ABI");
  insist(staged(state)===fuel+state,"stage arithmetic model");
  insist(captured(state)===fuel+11n+state&&captured(state+1n)===fuel+12n+state,"captured values reusable");
  insist(module.satZeroDiv(fuel,state)===fuel+state,"total division/remainder by zero");
  insist(module.satApplyEffect(fuel,n=>n+3n,state)===fuel+state+3n,"callback argument value");
 }
 insist(module.satShadow(x=>y=>x*10n+y,3n,8n)===38n,"source local callee shadow");
}
insist(radix===240&&partials===1200,"complete two-runtime radix and partial matrix");
console.log("PSC1_SATURATION_RADIX_JS: PASS cases=240 partialStages=1200 largeNat=above2^70");

function observeSource(module){
 const trace=[];
 const effect=n=>{trace.push("effect:"+n);return n+1n;};
 const before=module.satEffectful(3n,effect);
 const afterEntry=[...trace],first=before(5n),afterFirst=[...trace],second=before(7n);
 const betweenTrace=[];
 const between=n=>{betweenTrace.push("between:"+n);return n+2n;};
 const two=module.satBetweenStages(2n,between);
 const afterTwoEntry=[...betweenTrace],last=two(4n),afterFirstStage=[...betweenTrace];
 const twoFirst=last(5n),afterTwoCall=[...betweenTrace],twoSecond=last(7n);
 const order=[];
 const left=n=>{order.push("left:"+n);return n+1n;};
 const right=n=>{order.push("right:"+n);return n+2n;};
 const ordered=module.satFixedOrder(left,right,3n,5n,7n);
 return {afterEntry,first,afterFirst,second,finalTrace:trace,
  afterTwoEntry,afterFirstStage,twoFirst,afterTwoCall,twoSecond,finalBetween:betweenTrace,order,ordered};
}
const sourceTrace=observeSource(sourceOriginal);
equal(sourceTrace,observeSource(sourceOptimized),"source callback order/multiplicity across stages");
equal(sourceTrace.afterEntry,["effect:3"],"pre-stage callback occurs on entry");
equal(sourceTrace.afterFirstStage,["between:4"],"middle-stage callback occurs at first partial application");
equal(sourceTrace.order,["left:3","right:5"],"arbitrary fixed args evaluated once left-to-right");
function observeThrow(module,name){
 const trace=[],sentinel={reason:"deliberate callback exception"};
 let sameException=false;
 try{
  if(name==="before")module.satEffectful(3n,n=>{trace.push(n);throw sentinel;});
  else module.satBetweenStages(3n,n=>{trace.push(n);throw sentinel;})(5n);
 }catch(error){sameException=error===sentinel;}
 return {trace,sameException};
}
for(const phase of ["before","between"]){
 const original=observeThrow(sourceOriginal,phase),optimized=observeThrow(sourceOptimized,phase);
 equal(original,optimized,"exact thrown callback identity/order "+phase);
 insist(optimized.sameException&&optimized.trace.length===1,"throw is neither swallowed nor duplicated");
}

function observeModel(module){
 const order=[];
 const result=module.fixedOrder(n=>{order.push(n);return n+1n;},2n,5n,7n);
 const before=[];
 const closure=module.effectBefore(2n,n=>{before.push(n);return n+1n;});
 const entry=[...before],value=closure(5n),after=[...before],reused=closure(8n);
 const middle=[];
 const first=module.effectBetween(2n,n=>{middle.push(n);return n+2n;});
 const beforeFirst=[...middle],last=first(4n),afterFirst=[...middle],middleValue=last(5n);
 const extra=[];
 const extraValue=module.effectArgument(3n,n=>{extra.push(n);return n+7n;},2n);
 return {result,order,entry,value,after,reused,before,beforeFirst,afterFirst,middleValue,middle,
  extra,extraValue};
}
equal(observeModel(modelOriginal),observeModel(modelOptimized),"model exact callback trace");
for(const module of [modelOriginal,modelOptimized]){
 insist(module.stage.length===1&&module.stageTwo.length===2,"model original entry ABI");
 for(const fuel of [0n,1n,2n,16n,128n,4096n])for(const state of [0n,1n,18446744073709551629n]){
  insist(module.stage(fuel)(state)===fuel+state,"model stage result");
  insist(module.saturated(fuel,state)===fuel+state,"model saturated global call");
  const one=module.stageTwo(fuel,3n),two=one(state);
  insist(typeof one==="function"&&typeof two==="function"&&
   one.length===0&&two.length===0,"two-stage runtime rest-wrapper ABI");
  insist(two(7n)===state+(fuel+1n)*3n+7n+fuel,"two-stage captured interval arithmetic");
  insist(two(9n)===state+(fuel+1n)*3n+9n+fuel,"two-stage reuse exact");
  insist(module.partialStage(fuel)(state)===fuel+state,"unrewritten partial global call");
  insist(module.pureDiv(fuel,state)===fuel+state,"moved total primitives zero control");
 }
 const replacement=first=>second=>first*10n+second;
 insist(module.shadowLambda(replacement,3n,8n)===38n,"lambda shadow runtime");
 insist(module.shadowLet(replacement,3n,8n)===38n,"let shadow runtime");
 insist(module.helperShadow(replacement,3n,8n)===11n,"private helper lexical collision decline");
}
console.log("PSC1_SATURATION_ORDER_JS: PASS preStage+betweenStage+fixedArgs+effectArg throws=identity");
console.log("PSC1_SATURATION_ABI_JS: PASS exports=identical declarations=identical returnedStages=unary");
console.log("PSC1_SATURATION_JS: PASS assertions="+assertions+" identities="+JSON.stringify(identities));
