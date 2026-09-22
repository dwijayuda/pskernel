import assert from 'node:assert/strict';
import {parseLeanVersion} from '../src/index.mjs';

const a=parseLeanVersion('Lean (version 4.34.0, x86_64-w64-windows-gnu, commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b, Release)');
assert.equal(a.version,'4.34.0');
assert.equal(a.commit,'293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
assert.equal(a.build,'Release');

const b=parseLeanVersion('Lean (version 4.34.0)');
assert.equal(b.version,'4.34.0');

const c=parseLeanVersion('not lean');
assert.equal(c.version,null);

console.log('ok - @proofscript/lean4export version parser');
