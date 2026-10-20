import fs from "node:fs";
import path from "node:path";

const pinnedLean=fs.readFileSync(new URL("../lean-toolchain",import.meta.url),"utf8").trim();
if(!/^leanprover\/lean4:v[0-9]+\.[0-9]+\.[0-9]+$/.test(pinnedLean))
  throw Error("PSC1_CONTROLLED_REPORT_INVALID_LEAN_PIN "+pinnedLean);
const dir=process.argv[2];
if(!dir)throw Error("CONTROLLED_REPORT_DIRECTORY_REQUIRED");
const read=name=>fs.readFileSync(path.join(dir,name),"utf8");
const fixtures=["whnf_beta","defeq_positive","checked_application_16",
  "admit_ordinary_inductive","admit_mutual_inductive"];
const ordered=["original-all-1","optimized-all-1",
  "optimized-all-2","original-all-2"];
function parse(name,selected) {
  const rows=new Map();let summary;
  for(const line of read(name+".log").split("\n")) {
    if(line.startsWith("PSC1_JS_WHOLE ")) {
      const item=JSON.parse(line.slice("PSC1_JS_WHOLE ".length));
      const key=item.operation+":"+item.round;
      if(rows.has(key)||item.completed!==item.iterations)throw Error("INVALID_OPERATION "+name+" "+key);
      rows.set(key,item);
    }
    if(line.startsWith("PSC1_JS_WHOLE_SUMMARY "))
      summary=JSON.parse(line.slice("PSC1_JS_WHOLE_SUMMARY ".length));
  }
  const expected=selected==="all"?33:3;
  if(rows.size!==expected||!summary?.all_correct||summary.filter!==selected||
     summary.operations!==expected||!(summary.max_rss_kib>0)||
     !summary.before_workload||!summary.after_workload)
    throw Error("UNQUALIFIED_MEMORY_PROBE "+name+" "+rows.size+"/"+expected);
  if(selected!=="all" && [...rows.values()].some(v=>v.operation!==selected))
    throw Error("UNEXPECTED_OPERATION "+name);
  return {rows,summary};
}
const pairs={original:[],optimized:[]};
for(const name of ordered) {
  const label=name.split("-")[0];
  const probe=parse(name,"all");
  if(probe.summary.label!==label)throw Error("MISLABELED_PROBE "+name);
  pairs[label].push(probe);
}
const orderedKeys=[...pairs.original[0].rows.keys()].sort();
for(const p of [...pairs.original,...pairs.optimized])
  if(p.rows.size!==orderedKeys.length ||orderedKeys.some(k=>!p.rows.has(k)||
     p.rows.get(k).iterations!==pairs.original[0].rows.get(k).iterations))
    throw Error("INCOMPARABLE_JS_WORKLOADS");
const median=x=>[...x].sort((a,b)=>a-b)[Math.floor(x.length/2)];
const group=new Map();
for(const [label,reps] of Object.entries(pairs))for(const rep of reps)
 for(const item of rep.rows.values()) {
   if(!group.has(item.operation))group.set(item.operation,{original:[],optimized:[],iterations:item.iterations});
   group.get(item.operation)[label].push(item.ms);
 }
const operations=[...group.entries()].map(([name,g])=>({
 name,iterations_per_round:g.iterations,
 original_ms:median(g.original),optimized_ms:median(g.optimized),
 ratio:median(g.optimized)>0?median(g.original)/median(g.optimized):null,
 original_samples_ms:g.original,optimized_samples_ms:g.optimized
})).sort((a,b)=>a.name.localeCompare(b.name));
if(operations.length!==11 ||operations.some(x=>x.original_samples_ms.length!==6||x.optimized_samples_ms.length!==6))
 throw Error("UNEXPECTED_PAIRED_CASE_COUNT");
const memory={};
for(const label of ["original","optimized"]) {
  const runs=pairs[label].map(p=>p.summary);
  memory[label]={
    max_rss_kib:runs.map(r=>r.max_rss_kib),
    median_max_rss_kib:median(runs.map(r=>r.max_rss_kib)),
    post_gc_heap_used_bytes:runs.map(r=>r.after_workload.heapUsed),
    post_import_heap_used_bytes:runs.map(r=>r.after_import.heapUsed),
    gc_events:runs.map(r=>r.gc_events),
    import_ms:runs.map(r=>r.import_ms)
  };
}
const isolated={};
for(const fixture of fixtures) {
 const o=parse("original-"+fixture,fixture),p=parse("optimized-"+fixture,fixture);
 isolated[fixture]={original:o.summary,optimized:p.summary,
   original_ms:median([...o.rows.values()].map(x=>x.ms)),
   optimized_ms:median([...p.rows.values()].map(x=>x.ms))};
}
const refs=Object.fromEntries(read("refs.txt").trim().split("\n").map(l=>l.split("=")));
const sourcePaths=Object.fromEntries(read("sizes.txt").trim().split("\n").map(l=>l.split("=")));
const report={
 refs,toolchain:"single PSC1 compiler source snapshot, "+pinnedLean+", TS 7.0.2, Node 22",
 order:ordered,fixtures,source_artifact_sizes_bytes:sourcePaths,
 operations,memory,isolated,
 caveats:"ABBA uses 2 fresh processes per side, 6 in-process operation rounds per side. RSS is process max; post-GC heapUsed measures retained V8 heap, not total allocations. Small timing differences are uncertain."
};
fs.writeFileSync(path.join(dir,"controlled-report.json"),JSON.stringify(report,null,2)+"\n");
const mib=kib=>(kib/1024).toFixed(1);
const rows=operations.map(r=>"| "+r.name+" | "+r.original_ms.toFixed(1)+" | "+
r.optimized_ms.toFixed(1)+" | "+r.ratio.toFixed(2)+"x |").join("\n");
const memrows=fixtures.map(name=>{
 const r=isolated[name];
 return "| "+name+" | "+mib(r.original.max_rss_kib)+" | "+
 mib(r.optimized.max_rss_kib)+" | "+
 (r.original.after_workload.heapUsed/1048576).toFixed(1)+" | "+
 (r.optimized.after_workload.heapUsed/1048576).toFixed(1)+" |";
}).join("\n");
const md="# Same-compiler controlled PSC1 generated-JS A/B\n\n"+
"Source compiler: "+refs.compiler+"; original kernel: "+refs.baseline+
"; optimized kernel: "+refs.optimized+"\n\n"+
"One GitHub Actions Linux runner; Node 22, "+pinnedLean+", TypeScript 7.0.2. Both builds use identical compiler sources and configurations. Both full kernels passed strict semantic guards.\n"+
"Execution order: A-B-B-A, with two separate fresh processes per variant. Three guarded rounds per process. Memory below is recorded independently, not inferred from timing.\n\n"+
"| Checked operation | Original median ms | Optimized median ms | Ratio |\n|---|---:|---:|---:|\n"+rows+"\n\n"+
"Full-suite peak RSS original "+memory.original.max_rss_kib.map(mib).join(", ")+" MiB versus optimized "+
memory.optimized.max_rss_kib.map(mib).join(", ")+" MiB.\n\n"+
"| Operation isolated in fresh process | Original max RSS (MiB) | Optimized max RSS (MiB) | Original post-GC heap (MiB) | Optimized post-GC heap (MiB) |\n|---|---:|---:|---:|---:|\n"+memrows+
"\n\nArtifacts and V8 heap/GC observations are in controlled-report.json. This reports measured finite workloads; no Arena/fixed-point proof or causality guarantee is implied.\n";
fs.writeFileSync(path.join(dir,"controlled-report.md"),md);
console.log(md);
