// Fast source ownership/census diagnostic. No admission or generation claim.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {generatedTarget} from '../host-tools/generated-target-profiles.mjs';
import {sha} from '../host-tools/generated-target-tools.mjs';
import {validateCensusLane} from './compiler-source-census-contract.mjs';
const target=process.argv[2];const definition=generatedTarget(target);
const sources=readOwnedCompilerSources(definition.entry);
const directory=path.resolve('dist/generated-'+target+'-compiler/source-audit');fs.mkdirSync(directory,{recursive:true});
const modules=sources.map(s=>({name:s.module,path:s.path,utf8Bytes:Buffer.byteLength(s.text),sha256:sha(s.text),
 imports:[...s.text.matchAll(/^import\s+(.+)$/gm)].flatMap(m=>m[1].trim().split(/\s+/))}));
let refused=false;
for(const grammar of ['lean','ps']){
 const output=path.join(directory,grammar+'.json');
 const r=spawnSync('.lake/build/bin/psc1_source_census_probe',['--grammar',grammar,'--out',output,
  '--modules',...sources.flatMap(s=>[s.module,s.path])],{encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
 fs.writeFileSync(path.join(directory,grammar+'.stdout.txt'),r.stdout||'');fs.writeFileSync(path.join(directory,grammar+'.stderr.txt'),r.stderr||'');
 assert.equal(r.status,0,r.error?.message||r.stderr);
 const value=JSON.parse(fs.readFileSync(output,'utf8'));validateCensusLane(value,modules,grammar);
 const failures=value.records.filter(row=>row.elaboration!=='accepted');
 refused ||= failures.length>0;
 console.log('PSC1_TARGET_SOURCE_AUDIT: '+JSON.stringify({target,grammar,modules:modules.length,
  refused:failures.map(({module,parse,elaboration,sourceDeclaration,line,column,detail,blockedImports})=>({module,parse,elaboration,sourceDeclaration,line,column,detail,blockedImports}))}));
}
assert.equal(refused,false,'PSC1_TARGET_SOURCE_CLOSURE_REFUSED');
