import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {runJsonProvider} from './run-provider.mjs';

test('Emscripten-compatible stdin handles exact large admission payloads',()=>{
  const directory=mkdtempSync(path.join(tmpdir(),'psc0-wasm-transport-test-'));
  try{
    const mock=path.join(directory,'checker.cjs');
    writeFileSync(mock,`
const fs=require('node:fs');
const crypto=require('node:crypto');
const source=fs.readFileSync(0);
process.stdout.write(JSON.stringify({
  length:source.length,
  sha256:crypto.createHash('sha256').update(source).digest('hex')
})+'\\n');
`);
    const source=JSON.stringify({format:'proofscript-checked-admissions',
      version:2,payload:'x'.repeat(4*1024*1024)});
    const returned=runJsonProvider(process.execPath,[mock],source);
    assert.equal(returned.length,Buffer.byteLength(source));
    assert.equal(returned.sha256,createHash('sha256').update(source).digest('hex'));
  }finally{rmSync(directory,{recursive:true,force:true});}
});

test('subprocess failure is transport failure, never kernel rejection',()=>{
  assert.throws(()=>runJsonProvider(process.execPath,['-e','process.exit(13)']),
    /provider transport failure/);
  assert.throws(()=>runJsonProvider(process.execPath,['-e',
    'process.stdout.write(\"not-json\")']),/malformed JSON/);
  assert.throws(()=>runJsonProvider(process.execPath,['-e',
    'process.stdout.write(\"null\")']),/JSON object/);
});

test('stdin argument type and process configuration are validated',()=>{
  assert.throws(()=>runJsonProvider(process.execPath,[],{}),TypeError);
  assert.throws(()=>runJsonProvider(process.execPath,[],undefined,0),TypeError);
});
