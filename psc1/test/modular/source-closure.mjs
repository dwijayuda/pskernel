// Read-only source-import navigation; not a validated runtime/link graph.
import fs from 'node:fs';
import {readOwnedCompilerSources} from '../../host-tools/compiler-source-inputs.mjs';
import {compilerSourceClosureDigest} from '../../host-tools/compiler-host-protocol.mjs';
import {sha256} from '../../host-tools/modular/compiler.mjs';
const entry='Ps.CompilerUnified.Service',rows=readOwnedCompilerSources(entry);
const sources=rows.map(row=>({module:row.module,kind:'lean',text:row.text}));
const receipt={schema:'psc1-owned-source-navigation/1',testedCommit:process.env.GITHUB_SHA,entry,
 sourceClosureDigest:compilerSourceClosureDigest(sources),modules:rows.length,
 sourceBytes:rows.reduce((sum,row)=>sum+Buffer.byteLength(row.text),0),
 graphKind:'source imports only; not transformed runtime ownership, admission, complete modular emission or self-hosting evidence',
 files:rows.map(row=>({module:row.module,path:row.path,bytes:Buffer.byteLength(row.text),sha256:sha256(row.text),
  imports:[...row.text.matchAll(/^import\s+(.+)$/gm)].flatMap(match=>match[1].trim().split(/\s+/))}))};
fs.mkdirSync('dist/modular',{recursive:true});
fs.writeFileSync('dist/modular/current-source-navigation.json',JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_SOURCE_NAVIGATION '+JSON.stringify({entry,modules:receipt.modules,sourceBytes:receipt.sourceBytes,
 sourceClosureDigest:receipt.sourceClosureDigest,graphKind:receipt.graphKind}));
