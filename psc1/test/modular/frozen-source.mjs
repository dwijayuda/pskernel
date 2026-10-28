// Read the immutable qualified source closure. It is data, never an executable import.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {readOwnedCompilerSources} from '../../host-tools/compiler-source-inputs.mjs';
import {compilerSourceClosureDigest} from '../../host-tools/compiler-host-protocol.mjs';
const previous=process.cwd(),root=fs.realpathSync(process.env.PSC1_MODULAR_FROZEN_ROOT);
let rows;
try{process.chdir(root);rows=readOwnedCompilerSources('Ps.CompilerUnified.Service').map(row=>({...row,path:path.resolve(row.path)}));}
finally{process.chdir(previous);}
const sources=rows.map(row=>({module:row.module,kind:'lean',text:row.text}));
const digest=compilerSourceClosureDigest(sources);
assert.equal(sources.length,122);assert.equal(digest,'073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9');
for(const row of rows)assert.equal(fs.readFileSync(row.path,'utf8'),row.text);
fs.mkdirSync('dist/modular/frozen-source',{recursive:true});
fs.writeFileSync('dist/modular/frozen-source/sources.json',JSON.stringify(sources));
fs.writeFileSync('dist/modular/frozen-source/rows.json',JSON.stringify(rows));
console.log('PSC1_MODULAR_FROZEN_SOURCE '+JSON.stringify({modules:sources.length,digest,bytes:Buffer.byteLength(JSON.stringify(sources)),root,scope:'read-only exact qualified source; no compiler generation claim'}));
