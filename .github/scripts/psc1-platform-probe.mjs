// Focused host diagnosis against the exact qualified .3 tarball; not release qualification.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {fixtures} from '../../psc1/scripts/kernel435-fixtures.mjs';
const input=path.resolve('dist/platform-input');
const receipt=JSON.parse(fs.readFileSync(path.join(input,'package-receipt.json')));
const tar=path.join(input,'tarballs',receipt.tarball);
const hash=b=>createHash('sha256').update(b).digest('hex');
assert.equal(receipt.sha256,'9a0bc7727c009b071d9835db536a6856bb20b294b8e6d5ff18ef79e68bdb0b57');
assert.equal(hash(fs.readFileSync(tar)),receipt.sha256);
const temp=fs.realpathSync(os.tmpdir()),directory=fs.mkdtempSync(path.join(temp,'psc1 platform λ '));
const report={schema:'psc1-platform-host-probe/1',status:'diagnostic-only',platform:process.platform,
 arch:process.arch,node:process.version,testedCommit:process.env.GITHUB_SHA,tarballSha256:receipt.sha256};
const npmCandidates=[path.join(path.dirname(process.execPath),'node_modules/npm/bin/npm-cli.js'),
 path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js')];
const npm=npmCandidates.find(file=>fs.existsSync(file));assert.ok(npm,'npm CLI must be present');
const run=(exe,args)=>spawnSync(exe,args,{cwd:directory,encoding:'utf8',timeout:240000,maxBuffer:33554432,windowsHide:true});
const ok=(exe,args)=>{const r=run(exe,args);assert.equal(r.error,undefined);assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
try{
 fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');
 ok(process.execPath,[npm,'install','--offline','--ignore-scripts','--no-audit','--no-fund',
  '--registry','http://127.0.0.1:9','--cache',path.join(directory,'empty-cache'),tar]);
 report.offlineInstall=true;
 const root=path.join(directory,'node_modules/proofscript'),cli=path.join(root,'dist/psc.mjs');
 report.version=ok(process.execPath,[cli,'--version']).trim();
 report.identity=JSON.parse(ok(process.execPath,[cli,'--identity']));
 fs.writeFileSync(path.join(directory,'fixtures.json'),JSON.stringify(fixtures));
 fs.copyFileSync(path.join(input,'compiler-admissions.json'),path.join(directory,'compiler-admissions.json'));
 const program=path.join(directory,'probe.mjs');
 fs.writeFileSync(program,[
  "import fs from'node:fs';import assert from'node:assert/strict';import{checkCanonicalAdmissions,compile}from'proofscript';",
  "const r={};for(const fixture of JSON.parse(fs.readFileSync('fixtures.json'))){const k=await checkCanonicalAdmissions(fixture.input);assert.equal(k.accepted,fixture.accepted,fixture.id);assert.equal(k.leanVersion,'4.35.0');}",
  "r.kernelCases=14;const all=await checkCanonicalAdmissions(fs.readFileSync('compiler-admissions.json','utf8'));assert.equal(all.accepted,true);r.compilerAdmission=all.admissionsSha256;",
  "r.compilation=[];for(const engine of['js','ts']){try{const c=compile({engine,entryModule:'Main',sources:[{module:'Main',kind:'ps',text:'def answer : Nat := 42\\n'}]});r.compilation.push({engine,status:'accepted',logicalAdmission:c.logicalAdmission});}catch(error){r.compilation.push({engine,status:'blocked',error:error.message});}}",
  "console.log(JSON.stringify(r));"
 ].join('\n'));
 const compiler=JSON.parse(ok(process.execPath,[program]));Object.assign(report,compiler);
 const scratch=path.join(directory,'fs-probe');fs.mkdirSync(scratch);
 report.filesystem={};
 for(const mode of['r','r+']){
  const file=path.join(scratch,'data-'+mode.replace('+','w'));fs.writeFileSync(file,'data');
  let fd;try{fd=fs.openSync(file,mode);fs.fsyncSync(fd);report.filesystem['fileSync'+mode]='supported';}
  catch(error){report.filesystem['fileSync'+mode]=error.code;}
  finally{if(fd!==undefined)fs.closeSync(fd);}
 }
 let fd;try{fd=fs.openSync(scratch,'r');fs.fsyncSync(fd);report.filesystem.directorySync='supported';}
 catch(error){report.filesystem.directorySync=error.code;}
 finally{if(fd!==undefined)fs.closeSync(fd);}
 const pointer=path.join(scratch,'current.json');fs.writeFileSync(pointer,'old');
 for(let n=0;n<4;n++){const next=path.join(scratch,'next-'+n);fs.writeFileSync(next,'new'+n);fs.renameSync(next,pointer);assert.equal(fs.readFileSync(pointer,'utf8'),'new'+n);}
 report.filesystem.replaceExisting='four replacements passed; not a power-loss durability claim';
}catch(error){report.status='diagnostic-failed';report.error=error.stack;throw error;}
finally{
 const out=path.resolve('dist/platform-probe');fs.mkdirSync(out,{recursive:true});
 fs.writeFileSync(path.join(out,process.env.PSC1_PLATFORM_LABEL+'.json'),JSON.stringify(report,null,2)+'\n');
 console.log('PSC1_PLATFORM_HOST_PROBE '+JSON.stringify(report));
 const relative=path.relative(temp,directory);assert.ok(relative&&!relative.startsWith('..')&&!path.isAbsolute(relative));
 fs.rmSync(directory,{recursive:true,force:true});
}
