import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
const folder=path.resolve('dist/scoped-correctness/php-utf8');
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
function run(cmd,args,timeout=30000){
 const r=spawnSync(cmd,args,{encoding:'utf8',timeout,maxBuffer:8*1024*1024});
 assert.equal(r.error,undefined,r.error?.message);assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;
}
run('.lake/build/bin/psc1_php_utf8_tests',[]);
const php=process.env.PSC1_PHP||'php';
const module=path.join(folder,'module.php'),runtime=path.join(folder,'runtime.php'),echo=path.join(folder,'echo.php');
for(const file of [module,runtime,echo])run(php,['-l',file]);
const observed=JSON.parse(run(php,['scripts/php-utf8-consumer.php',module,runtime],15000));
assert.equal(observed.passed,true);assert.equal(observed.iterations,100000);
assert.equal(observed.inputBytes,500000);assert.ok(observed.elapsedSeconds>=0&&observed.elapsedSeconds<=5);
run(php,['-n','-r',"$api=require $argv[1];if($api['echo']('A😀é')!=='A😀é')exit(1);try{$api['echo'](chr(255));exit(2);}catch(TypeError $e){if(!str_contains($e->getMessage(),'PSC1_PHP_ARGUMENT_TYPE'))exit(3);}",echo]);
const receipt={schema:'psc1-php-utf8-runtime/1',testedCommit:process.env.GITHUB_SHA,
 branchHeadCommit:process.env.PSC1_HEAD_SHA,passed:true,strictInputIr:true,phpVersion:run(php,['-r','echo PHP_VERSION;']).trim(),
 nativeFixtureSha256:sha('test/PhpUtf8Tests.lean'),consumerSha256:sha('scripts/php-utf8-consumer.php'),
 moduleSha256:sha(module),runtimeSha256:sha(runtime),echoSha256:sha(echo),
 requirements:JSON.parse(fs.readFileSync(path.join(folder,'requirements.json'))),...observed,
 scope:'Backend runtime test; actual independently checked application remains required.'};
fs.writeFileSync(path.join(folder,'results.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_PHP_UTF8_RUNTIME: '+JSON.stringify(receipt));
