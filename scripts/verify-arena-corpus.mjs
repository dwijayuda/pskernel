import {createHash} from 'node:crypto';
import {readdirSync,readFileSync,statSync} from 'node:fs';
import {join,relative,sep} from 'node:path';

const root=process.argv[2];
if(!root)throw new Error('usage: verify-arena-corpus <arena-tests-dir>');
const lock=JSON.parse(readFileSync('ARENA_LOCK.json','utf8'));
const files=[];
const walk=p=>{for(const n of readdirSync(p)){const q=join(p,n),s=statSync(q);if(s.isDirectory())walk(q);else if(q.endsWith('.ndjson'))files.push(q);}};
walk(root);
files.sort((a,b)=>relative(root,a).localeCompare(relative(root,b)));
const rows=files.map(file=>{
  const rel=relative(root,file).split(sep).join('/');
  const data=readFileSync(file);
  const sha=createHash('sha256').update(data).digest('hex');
  return {rel,bytes:data.length,sha,perf:rel.includes('/perf/'),good:rel.startsWith('good/'),bad:rel.startsWith('bad/')};
});
for(const r of rows)if(!r.good&&!r.bad)throw new Error('Arena case outside good/bad: '+r.rel);
const canonical=xs=>xs.map(r=>`${r.rel}\\0${r.bytes}\\0${r.sha}\\n`).join('');
const digest=xs=>createHash('sha256').update(canonical(xs)).digest('hex');
const correctness=rows.filter(r=>!r.perf);
const counts={
  total:rows.length,
  good:rows.filter(r=>r.good).length,
  bad:rows.filter(r=>r.bad).length,
  correctness:correctness.length,
  performance:rows.filter(r=>r.perf).length
};
for(const [k,v] of Object.entries(lock.corpus)){
  if(k in counts&&counts[k]!==v)throw new Error(`Arena corpus count drift: ${k}=${counts[k]} expected ${v}`);
}
const allDigest=digest(rows),correctnessDigest=digest(correctness);
if(allDigest!==lock.corpus.contentDigestSha256)throw new Error(`Arena corpus content drift: ${allDigest}`);
if(correctnessDigest!==lock.corpus.correctnessDigestSha256)throw new Error(`Arena correctness content drift: ${correctnessDigest}`);
console.log(JSON.stringify({ok:true,source:lock.source,counts,contentDigestSha256:allDigest,correctnessDigestSha256:correctnessDigest},null,2));
