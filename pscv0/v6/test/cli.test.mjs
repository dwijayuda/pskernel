import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const cli = new URL('../packages/cli/bin/psc-core.mjs',import.meta.url);
const run = (...args) => spawnSync(process.execPath,[cli.pathname,...args],{encoding:'utf8',timeout:10000});

test('CLI identifies its actual limited capabilities and rejects a falsely verified build', () => {
  const caps = run('capabilities');
  assert.equal(caps.status,0,caps.stderr);
  assert.equal(JSON.parse(caps.stdout).pscvCertificationImplemented,false);
  const build = run('build','src/Main.ps','--verified');
  assert.notEqual(build.status,0);
  assert.match(build.stderr,/PSCV_CLI_UNSUPPORTED_COMMAND/u);
});

test('CLI identifies .ps bytes without parsing or checking them', () => {
  const dir=mkdtempSync(path.join(os.tmpdir(),'pscv-core-test-'));
  try{
    const file=path.join(dir,'Main.ps');
    writeFileSync(file,'function f(x: Nat): Nat := x\n');
    const result=run('inspect',file);
    assert.equal(result.status,0,result.stderr);
    const payload=JSON.parse(result.stdout);
    assert.equal(payload.kind,'source-identity-only');
    assert.equal(payload.kernelChecked,false);
  }finally {rmSync(dir,{recursive:true,force:true});}
});
