import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { root, maskNonCode, validateCode, readSources } from '../scripts/source.mjs';
test('exact owned source closure validates',()=>assert.equal(readSources().manifest.files.length,36));
test('comments and strings are not executable forbidden words',()=> {
  validateCode('/- outer /- import Lean -/ unsafe -/\ndef text : String := "unsafe -- \\\" extern"\n',new Set());
});
test('unterminated comment or string fails closed',()=> {
  assert.throws(()=>maskNonCode('/- missing'));assert.throws(()=>maskNonCode('"missing'));
});
for(const source of ['import Lean','import Std.Data','import Ps.KernelCore.Data','import Ps.KernelOne.Name','unsafe def f := 0','axiom f : Nat','#eval 1','def f := sorry','def f := Lean.Environment']) {
  test(`reject profile escape: ${source}`,()=>assert.throws(()=>validateCode(source,new Set())));
}
test('only already supplied owned imports are allowed',()=> {
  assert.throws(()=>validateCode('import Ps.Kernel.Data',new Set()));
  assert.equal(validateCode('import Ps.Kernel.Data\ndef n : Nat := 0',new Set(['Ps.Kernel.Data'])),'def n : Nat := 0');
});
function copied(action) {
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'pskernel-source-test-'));
  try {fs.cpSync(path.join(root,'src'),path.join(dir,'src'),{recursive:true});fs.cpSync(path.join(root,'manifests'),path.join(dir,'manifests'),{recursive:true});action(dir);}
  finally {fs.rmSync(dir,{recursive:true,force:true});}
}
test('changed source is not blessed by a stale manifest',()=>copied(dir=> {
  fs.appendFileSync(path.join(dir,'src/Ps/Kernel/Data.lean'),'\n-- changed\n');
  assert.throws(()=>readSources(dir),/SOURCE_HASH_MISMATCH/);
}));
test('unmanifested semantic files are rejected',()=>copied(dir=> {
  fs.writeFileSync(path.join(dir,'src/Ps/Kernel/Extra.lean'),'def extra : Nat := 0');
  assert.throws(()=>readSources(dir),/UNMANIFESTED_SOURCE/);
}));
test('source symlinks are rejected',()=>copied(dir=> {
  const file=path.join(dir,'src/Ps/Kernel/Data.lean');fs.renameSync(file,file+'.saved');fs.symlinkSync(file+'.saved',file);
  assert.throws(()=>readSources(dir),/SYMLINK_SOURCE/);
}));
