import fs from "node:fs";
import path from "node:path";
const dir = process.argv[2];
if (!dir) throw Error("BENCH_REPORT_DIRECTORY_REQUIRED");
const read = file => fs.readFileSync(path.join(dir, file), "utf8");
function parse(label) {
  const results = new Map();
  for (const line of read(label + ".log").split("\n")) {
    if (!line.includes("C0_COMPARE round=") || !line.includes(" milliseconds=")) continue;
    const operation = line.match(/operation=([A-Za-z0-9_]+)/)?.[1];
    const ms = line.match(/milliseconds=(\d+)/)?.[1];
    const round = line.match(/round=(\d+)/)?.[1];
    if (!operation || ms === undefined || round === undefined) continue;
    const arity = line.match(/arguments=(\d+)/)?.[1] ?? "";
    const style = line.match(/style=(\d+)/)?.[1] ?? "";
    const key = [operation, arity, style].filter(Boolean).join("/");
    const identity = round + ":" + key;
    if (results.has(identity)) throw Error("DUPLICATE_BENCHMARK_SAMPLE " + label + " " + identity);
    results.set(identity, Number(ms));
  }
  const rss = Number(read(label + ".memory").match(/max_rss_kb=(\d+)/)?.[1]);
  if (!Number.isFinite(rss) || rss <= 0) throw Error("INVALID_BENCHMARK_MEMORY " + label);
  if (results.size < 15) throw Error("INCOMPLETE_WHOLE_KERNEL_BENCHMARK " + label + ": " + results.size);
  return {results, rss};
}
const a=parse("original"),b=parse("optimized");
const ids=[...a.results.keys()].sort();
if (ids.length!==b.results.size || ids.some(key=>!b.results.has(key)))
  throw Error("INCOMPARABLE_OPERATION_OR_ROUND_SETS");
const paired=new Map();
for (const id of ids) {
  const [,key]=id.split(":");
  if (!paired.has(key)) paired.set(key,{before:[],after:[]});
  paired.get(key).before.push(a.results.get(id));
  paired.get(key).after.push(b.results.get(id));
}
const median=arr=>[...arr].sort((x,y)=>x-y)[Math.floor(arr.length/2)];
const rows=[...paired].map(([operation,{before,after}])=>{
  if(before.length!==3 || after.length!==3) throw Error("EXPECTED_THREE_ROUNDS_"+operation);
  const original_ms=median(before),optimized_ms=median(after);
  return {operation,rounds:3,original_ms,optimized_ms,speedup:optimized_ms?original_ms/optimized_ms:null,original_samples_ms:before,optimized_samples_ms:after};
}).sort((a,b)=>a.operation.localeCompare(b.operation));
const refs=Object.fromEntries(read("refs.txt").trim().split("\n").map(s=>s.split("=")));
const report={refs,toolchain:"leanprover/lean4:v4.34.0",scope:"Project-local synthetic complete checker, same runner, identical source and accepted/rejected counts",memory:{original_rss_kib:a.rss,optimized_rss_kib:b.rss},rows};
fs.writeFileSync(path.join(dir,"report.json"),JSON.stringify(report,null,2)+"\n");
const data=rows.map(r=>"| "+r.operation+" | "+r.rounds+" | "+r.original_ms+" | "+r.optimized_ms+" | "+(r.speedup===null?"n/a":r.speedup.toFixed(2)+"x")+" |").join("\n");
const md="# PSC1 native whole-kernel matched comparison\n\nOriginal: "+refs.original+"; optimized: "+refs.optimized+"\n\nBoth builds use pinned Lean 4.34, the same source, and one Linux CI runner. Results are three ordered rounds; comparisons are informational and may include run-order noise. All kernel success/rejection checks must pass before a benchmark is accepted.\n\n| Complete checker operation | Rounds | Original median (ms) | Optimized median (ms) | Original/optimized |\n|---|---:|---:|---:|---:|\n"+data+"\n\nPeak RSS: original "+a.rss+" KiB; optimized "+b.rss+" KiB (GNU time including build launcher). No general-library speedup or soundness result is inferred.\n";
fs.writeFileSync(path.join(dir,"report.md"),md);
console.log(md);
