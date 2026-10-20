import fs from "node:fs";
import path from "node:path";
const dir=process.argv[2];
if(!dir)throw Error("MISSING_NATIVE_ABBA_REPORT_DIR");
function read(name) {return fs.readFileSync(path.join(dir,name),"utf8");}
function parse(name) {
  const rows=new Map();
  for(const line of read(name+".log").split("\n")) {
    if(!line.includes("C0_COMPARE round=")||!line.includes(" milliseconds="))continue;
    const round=line.match(/round=(\d+)/)?.[1],ms=line.match(/milliseconds=(\d+)/)?.[1];
    if(round===undefined||ms===undefined)continue;
    const key=line.slice(line.indexOf("operation=")).replace(/\bmilliseconds=\d+\b/,"").trim().replace(/\s+/g," ");
    const id=round+":"+key;
    if(rows.has(id))throw Error("DUPLICATE_NATIVE_CASE "+name+" "+id);
    rows.set(id,Number(ms));
  }
  const rss=Number(read(name+".memory").match(/max_rss_kb=(\d+)/)?.[1]);
  if(!(rss>0)||rows.size<100)throw Error("INCOMPLETE_NATIVE_PROBE "+name+" "+rows.size);
  return {rows,rss};
}
const probes={original:parse("original"),optimized:parse("optimized"),
 optimized_reverse:parse("optimized-reverse"),original_reverse:parse("original-reverse")};
const fixtureIds=[...probes.original.rows.keys()].sort();
for(const [name,probe] of Object.entries(probes))
 if(probe.rows.size!==fixtureIds.length||fixtureIds.some(id=>!probe.rows.has(id)))
   throw Error("NATIVE_ABBA_CASE_SET_MISMATCH "+name);
const grouped=new Map();
for(const id of fixtureIds) {
  const key=id.slice(id.indexOf(":")+1);
  if(!grouped.has(key))grouped.set(key,{original:[],optimized:[],original_reverse:[],optimized_reverse:[]});
  const entry=grouped.get(key);
  for(const label of Object.keys(probes))entry[label].push(probes[label].rows.get(id));
}
const median=arr=>{
  const a=[...arr].sort((x,y)=>x-y),m=Math.floor(a.length/2);
  return a.length%2?a[m]:(a[m-1]+a[m])/2;
};
const focus=/cold_whnf_zeta_spine|cold_check_application|cold_infer_application|cold_defeq_binder_spine|admit_wide_checked_library|admit_nested_application_library/;
const rows=[...grouped].filter(([key])=>focus.test(key)).map(([key,v])=>{
  if(Object.values(v).some(x=>x.length!==3))throw Error("NATIVE_ABBA_MISSING_ROUND "+key);
  const original_ms=median([...v.original,...v.original_reverse]);
  const optimized_ms=median([...v.optimized,...v.optimized_reverse]);
  const reliable=original_ms>=5&&optimized_ms>=5;
  return {fixture:key,original_ms,optimized_ms,
    original_first_median_ms:median(v.original),
    original_second_median_ms:median(v.original_reverse),
    optimized_first_median_ms:median(v.optimized),
    optimized_second_median_ms:median(v.optimized_reverse),
    original_samples:v.original.concat(v.original_reverse),
    optimized_samples:v.optimized.concat(v.optimized_reverse),
    ratio:reliable?original_ms/optimized_ms:null,
    resolution_limited:!reliable};
}).sort((a,b)=>a.fixture.localeCompare(b.fixture));
const refs=Object.fromEntries(read("refs.txt").trim().split("\n").map(x=>x.split("=")));
const report={refs,fixtureCount:fixtureIds.length,focusCount:rows.length,
 order:["original","optimized","optimized_reverse","original_reverse"],
 peak_rss_kib:Object.fromEntries(Object.entries(probes).map(([k,v])=>[k,v.rss])),
 rows,limitations:"A-B-B-A process order; 3 rounds each phase; ms timestamps round to integers; ratios excluded below 5 ms; shared runner but no CPU affinity."};
fs.writeFileSync(path.join(dir,"native-abba-report.json"),JSON.stringify(report,null,2)+"\n");
const fmt=x=>x===null?"resolution-limited":x.toFixed(2)+"x";
const representative=rows.filter(x=>/cold_whnf_zeta_spine|cold_check_application_varied|cold_check_application_wide|admit_wide_checked_library/.test(x.fixture));
const table=representative.map(x=>"| "+x.fixture+" | "+x.original_ms+" | "+x.optimized_ms+" | "+fmt(x.ratio)+" |").join("\n");
const md="# PSC1 native A-B-B-A complete-checker focus comparison\n\n"+
"Original "+refs.original+"; optimized "+refs.optimized+". Identical source fixtures and Lean toolchain on one Linux runner.\n"+
"Both sides must accept/reject the exact same input suite. Execution order A-B-B-A. Six timing rounds per side per fixture.\n\n"+
"| Operation | Original median ms | Optimized median ms | Ratio |\n|---|---:|---:|---:|\n"+table+"\n\n"+
"Peak RSS KiB: "+JSON.stringify(report.peak_rss_kib)+"\n"+
"See JSON for all "+rows.length+" focused fixture variants and separate first-versus-reversed timing to assess order effects.\n";
fs.writeFileSync(path.join(dir,"native-abba-report.md"),md);
console.log(md);
