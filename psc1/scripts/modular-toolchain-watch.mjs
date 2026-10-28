// Reuse the nine applicable retained watch bodies; keep original native-engine
// cancellation tests unchanged in the separate reference CLI regression workflow.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
const source=fs.readFileSync('test/installed/watch.test.mjs','utf8');
const first=source.indexOf('  // Exercise real native descendants');
const last=source.indexOf("  const result={schema:'psc1-installed-watch/1'");
assert.ok(first>0&&last>first);
let code=source.slice(0,first)+source.slice(last);
code=code.replace("from './cli-fixture.mjs'","from '../../scripts/modular-toolchain-fixture.mjs'");
code=code.replace("  const result={schema:","  assert.equal(cases.length,9);\n  const result={schema:");
const runtime=process.env.PSC1_TEST_RUNTIME||process.execPath;
const name=path.basename(runtime).startsWith('bun')?'bun':'node';
code=code.replace("'dist/cli/watch.json'","'dist/modular-toolchain/watch-"+name+".json'");
code=code.replace("'PSC1_INSTALLED_WATCH '","'PSC1_MODULAR_INSTALLED_WATCH '");
const file=path.resolve('test/installed/modular-watch-generated.mjs');
assert.equal(fs.existsSync(file),false);
try{
 fs.writeFileSync(file,code,{flag:'wx'});
 const r=spawnSync(process.execPath,[file],{stdio:'inherit',timeout:1800000,env:process.env});
 assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0);
}finally{fs.rmSync(file,{force:true});}
