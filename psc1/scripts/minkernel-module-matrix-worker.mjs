// Actual stable standalone API; project execution is Linux Actions only.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import assert from 'node:assert/strict';
assert.equal(process.platform,'linux');assert.equal(process.env.GITHUB_ACTIONS,'true');
const {checkBytes,metadata}=await import(pathToFileURL(path.resolve('dist/pskernel-min/module-matrix/sdk/index.mjs')).href);
assert.equal(metadata.fullCompilerSupported,false);
const bytes=new Uint8Array(fs.readFileSync(process.argv[2]));
const start=performance.now(),result=checkBytes(bytes);
assert.equal(result.delegated,false);
console.log(JSON.stringify({...result,elapsedMs:performance.now()-start,resourceUsage:process.resourceUsage()}));
