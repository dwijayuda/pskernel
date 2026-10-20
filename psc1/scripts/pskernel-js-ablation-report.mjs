import fs from "node:fs";
import path from "node:path";
const dir=process.argv[2];
if(!dir)throw Error("MEMORY_ABLATION_REPORT_DIR_REQUIRED");
const variants=["original","optimized","no-lift","no-instantiate","no-beta"];
const operations=["whnf_beta","defeq_positive","checked_application_16",
  "admit_ordinary_inductive","admit_mutual_inductive"];
const read=n=>fs.readFileSync(path.join(dir,n),"utf8");
const median=x=>{const s=[...x].sort((a,b)=>a-b);return(s[0]+s[1])/2};
const results={};
for(const operation of operations){
  results[operation]={};
  for(const variant of variants){
    const samples=[];
    for(const round of [1,2]){
      const lines=read(variant+"-"+operation+"-"+round+".log").split("\n");
      const rows=lines.filter(l=>l.startsWith("PSC1_JS_WHOLE "));
      const summaries=lines.filter(l=>l.startsWith("PSC1_JS_WHOLE_SUMMARY "));
      if(rows.length!==3 || summaries.length!==1)throw Error("ABORT_INCOMPLETE_CHECKED_OPERATION "+operation+" "+variant+" "+round);
      const data=rows.map(l=>JSON.parse(l.slice("PSC1_JS_WHOLE ".length)));
      if(data.some((x,i)=>x.operation!==operation||x.round!==i||x.completed!==x.iterations))throw Error("ABORT_INCOMPARABLE_WORKLOAD "+variant);
      const summary=JSON.parse(summaries[0].slice("PSC1_JS_WHOLE_SUMMARY ".length));
      if(summary.filter!==operation||!summary.all_correct||summary.operations!==3||
         !summary.after_workload||!summary.before_workload||!(summary.max_rss_kib>0))
        throw Error("ABORT_UNQUALIFIED_MEM_SAMPLE "+variant);
      samples.push({peak_rss_kib:summary.max_rss_kib,
        post_gc_heap_mib:summary.after_workload.heapUsed/1048576,
        pre_workload_heap_mib:summary.before_workload.heapUsed/1048576,
        post_gc_delta_mib:(summary.after_workload.heapUsed-summary.before_workload.heapUsed)/1048576,
        gc_events:summary.gc_events, gc_ms:summary.gc_duration_ms,
        wall_ms:data.map(d=>d.ms).reduce((a,b)=>a+b,0)});
    }
    results[operation][variant]={samples,
      median_rss_mib:median(samples.map(s=>s.peak_rss_kib))/1024,
      median_post_gc_heap_mib:median(samples.map(s=>s.post_gc_heap_mib)),
      median_heap_delta_mib:median(samples.map(s=>s.post_gc_delta_mib)),
      median_wall_ms:median(samples.map(s=>s.wall_ms))};
  }
}
const hashes=read("compiler-snapshots.sha256").trim().split("\n").map(s=>s.split(/\s+/)[0]);
if(hashes.length!==5 ||new Set(hashes).size!==1)
  throw Error("ABORT_COMPILER_BINARY_NOT_IDENTICAL_ACROSS_KERNEL_VARIANTS");
const refs=Object.fromEntries(read("refs.txt").trim().split("\n").map(x=>x.split("=")));
const sizes=Object.fromEntries(read("module-sizes.txt").trim().split("\n").map(x=>x.split("=")));
const json={refs,compiler_sha256:hashes[0],generated_js_sizes_bytes:sizes,variants,operations,
 results,scope:"Same binary compiler for all five kernel-source variants; fresh process per guarded checked operation; two repeats per variant; GC hooks may be unavailable",
 limitations:"These are two samples per variant in fixed operation/variant order, not a statistically stable bound; include heap and memory outcome independently from correctness."};
fs.writeFileSync(path.join(dir,"report.json"),JSON.stringify(json,null,2)+"\n");
const table=operations.map(op=>{
 const f=v=>results[op][v];
 return "| "+op+" | "+variants.map(v=>f(v).median_rss_mib.toFixed(1)).join(" | ")+" |";
}).join("\n");
const heap=operations.map(op=>{
 const f=v=>results[op][v];return "| "+op+" | "+variants.map(v=>f(v).median_post_gc_heap_mib.toFixed(1)).join(" | ")+" |";
}).join("\n");
const md="# PSC1 same-compiler kernel-source memory ablation\n\n"+
"Compiler binary SHA256: "+hashes[0]+"\n"+
"Original: "+refs.original+"; optimized: "+refs.optimized+". Same compiler executable used for all five variants. Every checked operation passes correctness guards.\n"+
"Variant no-lift restores the original Lift.lean only; no-instantiate restores the original Instantiate.lean; no-beta restores the original Beta.lean and WhnfCore.lean. Baseline restores all four.\n"+
"Measurements are medians of two independent Node processes per operation/variant; each process includes three checked rounds.\n\n"+
"### Peak RSS (MiB)\n\n| Operation | Original | Optimized | No lifting port | No substitution ports | No beta ports |\n|---|---:|---:|---:|---:|---:|\n"+table+
"\n\n### Retained V8 heap after forced GC (MiB)\n\n| Operation | Original | Optimized | No lifting port | No substitution ports | No beta ports |\n|---|---:|---:|---:|---:|---:|\n"+heap+
"\n\nRaw logs, generated artifact sizes, GC and timing statistics are attached. This is evidence to prioritize further profiling, not a proof of memory safety or whole-library speedup.\n";
fs.writeFileSync(path.join(dir,"report.md"),md);
console.log(md);
