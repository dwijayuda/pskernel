// Real process/resource supervision must not depend on the source project's cwd.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {boundedRun} from '../../host-tools/generated-target-tools.mjs';

const before=process.cwd(),temporary=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-process-location-'));
try{
 const source=path.join(temporary,'unrelated-source'),child=path.join(temporary,'consumer');
 fs.mkdirSync(source);fs.mkdirSync(child);process.chdir(source);
 assert.equal(fs.existsSync('scripts'),false);assert.equal(fs.existsSync('host-tools'),false);
 const result=boundedRun(process.execPath,['-e','process.stdout.write(process.cwd()+"\\n");'],{cwd:child,timeoutMs:10000,timeoutPolicy:'standard-240s'});
 assert.equal(result.error,null);assert.equal(result.status,0,result.stderr);
 assert.equal(result.stdout,child+'\n');assert.equal(result.timeoutPolicy,'standard-240s');
 assert.throws(()=>boundedRun(process.execPath,['-e','process.exit(99)'],{timeoutMs:240001,timeoutPolicy:'standard-240s'}),/PSC1_TIMEOUT_OUTSIDE_PROFILE/);
 console.log('PSC1_PROCESS_LOCATION: PASS module-owned supervisor, distinct source/child cwd, original timeout ceiling');
}finally{process.chdir(before);fs.rmSync(temporary,{recursive:true,force:true});}
