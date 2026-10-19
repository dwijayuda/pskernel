import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {gunzipSync} from 'node:zlib';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url));
const expected=JSON.parse(gunzipSync(fs.readFileSync(path.join(root,
  'docs/continuity/joint-inventory-7f8c078e/declarations.json.gz')))).prelude;
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'psc2-prelude-parity-'));
try{
  const output=path.join(temporary,'prelude.json');
  const binary=path.join(root,'.lake/build/bin/psc2_joint_closure_inventory'+(process.platform==='win32'?'.exe':''));
  execFileSync(binary,['--prelude',output],{cwd:root,timeout:60000,stdio:'pipe'});
  assert.deepEqual(JSON.parse(fs.readFileSync(output)),expected,
    'prelude declaration types, metadata, bodies or order changed');
  console.log('PSC2_PRELUDE_DECLARATION_PARITY: PASS ('+expected.length+' exact declarations)');
}finally{fs.rmSync(temporary,{recursive:true,force:true});}
