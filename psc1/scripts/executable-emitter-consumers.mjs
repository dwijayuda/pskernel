// Consume the actual outputs of the pure production emitters.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
const root=path.resolve('dist/executable-packages/emitted');
const js=await import(pathToFileURL(path.join(root,'candidate.mjs')));
assert.equal(js.answer,42n);
const tsconfig={compilerOptions:{strict:true,noEmitOnError:true,target:'ES2022',module:'NodeNext',moduleResolution:'NodeNext',
 declaration:true,types:[],lib:['ES2022','DOM'],outDir:path.join(root,'checked-ts')},files:[path.join(root,'candidate.mts')]};
fs.writeFileSync(path.join(root,'tsconfig.json'),JSON.stringify(tsconfig));
const tsc=path.resolve('../node_modules/typescript/bin/tsc');
const compiled=spawnSync(process.execPath,[tsc,'--project',path.join(root,'tsconfig.json')],{encoding:'utf8',timeout:240000,maxBuffer:33554432});
assert.equal(compiled.error,undefined);assert.equal(compiled.status,0,compiled.stdout+compiled.stderr);
const ts=await import(pathToFileURL(path.join(root,'checked-ts/candidate.mjs')));
assert.equal(ts.answer,42n);assert.ok(fs.statSync(path.join(root,'checked-ts/candidate.d.mts')).size>0);
const hex=fs.readFileSync(path.join(root,'candidate.wasm.hex'),'utf8'),prefix='psc1-wasm-hex/1:';
assert.ok(hex.startsWith(prefix));const bytes=Buffer.from(hex.slice(prefix.length),'hex');
assert.ok(bytes.length>8);assert.equal(WebAssembly.validate(bytes),true);
fs.writeFileSync(path.join(root,'candidate.wasm'),bytes);
const receipt={schema:'psc1-production-emitter-consumers/1',status:'passed',node:process.versions.node,
 jsObservation:'42n',tsObservation:'42n',tsStrictDeclarations:true,wasmBinaryValidated:true,
 rust:'real emitted source; full Rust consumer coverage remains in the existing source/backend gates',
 scope:'strict IR fixture only; not independent source admission or a complete modular compiler'};
fs.writeFileSync('dist/executable-packages/emitter-consumers.json',JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_PRODUCTION_EMITTER_CONSUMERS '+JSON.stringify(receipt));
