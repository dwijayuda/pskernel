import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {gunzipSync} from 'node:zlib';
import {fileURLToPath} from 'node:url';
import {validatePreludeExtensions} from './prelude-extension-contract.mjs';
const root=fileURLToPath(new URL('../',import.meta.url));
const expected=JSON.parse(gunzipSync(fs.readFileSync(path.join(root,
  'docs/continuity/joint-inventory-7f8c078e/declarations.json.gz')))).prelude;
const extensionContract=JSON.parse(fs.readFileSync(path.join(root,
  'prelude-extension-contract.json'),'utf8'));
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'psc2-prelude-parity-'));
try{
  const output=path.join(temporary,'prelude.json');
  const binary=path.join(root,'.lake/build/bin/psc2_joint_closure_inventory'+(process.platform==='win32'?'.exe':''));
  execFileSync(binary,['--prelude',output],{cwd:root,timeout:60000,stdio:'pipe'});
  const actual=JSON.parse(fs.readFileSync(output));
  const frozenCore=validatePreludeExtensions(actual,extensionContract);
  assert.deepEqual(frozenCore,expected,
    'frozen core prelude declaration types, metadata, bodies or order changed');
  console.log(
    'PSC2_PRELUDE_DECLARATION_PARITY: PASS ('+
      expected.length+
      ' exact frozen-core declarations; '+
      extensionContract.extensions.length+
      ' exact declared extensions)'
  );
}finally{fs.rmSync(temporary,{recursive:true,force:true});}
