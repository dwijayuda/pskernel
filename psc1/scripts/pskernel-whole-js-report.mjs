import fs from "node:fs";
import path from "node:path";
const dir=process.argv[2];
if(!dir)throw Error("MISSING_JS_COMPARE_DIRECTORY");
const read=n=>fs.readFileSync(path.join(dir,n),"utf8");
function parse(label) {
  const measurements=new Map();
  let summary;
  for(const line of read(label+".log").split("\n")) {
    if(line.startsWith("PSC1_JS_WHOLE_SUMMARY ")) {
      summary=JSON.parse(line.slice("PSC1_JS_WHOLE_SUMMARY ".length));
      continue;
    }
    if(!line.startsWith("PSC1_JS_WHOLE "))continue;
    const item=JSON.parse(line.slice("PSC1_JS_WHOLE ".length));
    const key=item.operation+":"+item.round;
    if(measurements.has(key) || item.completed!==item.iterations || item.iterations<=0 || !Number.isFinite(item.ms))
      throw Error("INVALID_JS_WHOLE_SAMPLE "+label+" "+key);
    measurements.set(key,item);
  }
  if(!summary?.all_correct || measurements.size!==30 || !(summary.max_rss_kib>0))
    throw Error("INCOMPLETE_JS_COMPLETE_OPERATIONS "+label+" "+measurements.size);
  return {measurements,summary};
}
const a=parse("original"),b=parse("optimized");
if(a.measurements.size!==b.measurements.size ||
   [...a.measurements.keys()].some(key=>!b.measurements.has(key)||
      a.measurements.get(key).iterations!==b.measurements.get(key).iterations))
  throw Error("INCOMPARABLE_JS_OPERATION_SET");
const groups=new Map();
for(const [key,item] of a.measurements) {
  const target=b.measurements.get(key);
  if(!groups.has(item.operation))groups.set(item.operation,{original:[],optimized:[],count:item.iterations});
  groups.get(item.operation).original.push(item.ms);
  groups.get(item.operation).optimized.push(target.ms);
}
const median=x=>[...x].sort((a,b)=>a-b)[Math.floor(x.length/2)];
const rows=[...groups].map(([operation,v])=>{
  if(v.original.length!==3||v.optimized.length!==3)throw Error("WRONG_JS_ROUNDS "+operation);
  const original_ms=median(v.original),optimized_ms=median(v.optimized);
  return {operation,iterations_per_round:v.count,original_median_ms:original_ms,
    optimized_median_ms:optimized_ms,speedup:optimized_ms?original_ms/optimized_ms:null,
    original_samples_ms:v.original,optimized_samples_ms:v.optimized};
}).sort((a,b)=>a.operation.localeCompare(b.operation));
const refs=Object.fromEntries(read("refs.txt").trim().split("\n").map(x=>x.split("=")));
const report={refs,environment:"Node 22, TypeScript 7.0.2, Lean 4.34, separate compiled PSC1 snapshots on one GitHub runner",
  limitations:"Each revision also uses its corresponding historical compiler source; performance is indicative, not an isolated kernel-code ablation.",
  original:a.summary,optimized:b.summary,rows};
fs.writeFileSync(path.join(dir,"report.json"),JSON.stringify(report,null,2)+"\n");
const md="# PSC1 complete-operation generated JavaScript benchmark\n\n"+
"Original: "+refs.original+"; optimized: "+refs.optimized+"\n\n"+
"All outcomes are checked, with three fixed-order in-process rounds on one GitHub runner. The original and optimized compiler snapshots also differ; do not attribute every JS difference solely to kernel optimization.\n\n"+
"| Operation | Ops per round | Original median ms | Optimized median ms | Ratio (higher=faster) |\n|---|---:|---:|---:|---:|\n"+
rows.map(r=>"| "+r.operation+" | "+r.iterations_per_round+" | "+r.original_median_ms+" | "+r.optimized_median_ms+" | "+(r.speedup===null?"n/a":r.speedup.toFixed(2)+"x")+" |").join("\n")+
"\n\nPeak process RSS (maxRSS): original "+a.summary.max_rss_kib+" KiB; optimized "+b.summary.max_rss_kib+" KiB.\n"+
"Module import elapsed: original "+a.summary.import_ms+" ms; optimized "+b.summary.import_ms+" ms.\n";
fs.writeFileSync(path.join(dir,"report.md"),md);
console.log(md);
