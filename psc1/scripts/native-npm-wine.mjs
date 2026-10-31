// Linux-only CI compatibility qualification with actual Windows Node/npm.
// Never represents Wine execution as a native Windows-host qualification.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
assert.equal(process.platform,'linux');assert.equal(process.env.GITHUB_ACTIONS,'true');
const out=path.resolve('dist/native-npm');
const environment={...process.env};delete environment.GH_TOKEN;
const wine=['/usr/bin/wine','/usr/lib/wine/wine64'].find(fs.existsSync);assert.ok(wine);
function run(exe,args,label,timeout=120000){
  const r=spawnSync(exe,args,{env:environment,encoding:'utf8',timeout,maxBuffer:32*1024*1024});
  fs.writeFileSync(path.join(out,'wine-'+label+'.stdout.txt'),r.stdout||'');
  fs.writeFileSync(path.join(out,'wine-'+label+'.stderr.txt'),r.stderr||'');
  assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,(r.stderr||'')+'\n'+(r.stdout||'').slice(-8000));return r.stdout.trim();
}
try{
  run(wine,['wineboot','--init'],'boot');
  run('/usr/bin/wineserver',['-p'],'persistent');
  run(wine,['reg','add','HKCU\\Software\\Wine','/v','Version','/t','REG_SZ','/d','win10','/f'],'version');
  const convert=(file,label)=>run('/usr/bin/winepath',['-w',file],label).split('\n').at(-1).trim();
  const node=path.join(out,'windows-node/node-v22.23.3-win-x64/node.exe');assert.ok(fs.existsSync(node));
  const identity=JSON.parse(run(wine,[node,'-p','JSON.stringify({platform:process.platform,arch:process.arch,version:process.version})'],'node'));
  assert.deepEqual(identity,{platform:'win32',arch:'x64',version:'v22.23.3'});
  const script=convert(path.join(out,'tests/native-npm-installed.mjs'),'path-test');
  const tarball=convert(path.join(out,'delivery/proofscript-0.1.0-psc1-native.1.tgz'),'path-package');
  const receipt=convert(path.join(out,'delivery/QUALIFICATION-win32-x64.json'),'path-receipt');
  const report=run(wine,[node,script,tarball,receipt],'installed',12*60*1000);
  console.log(report);
  assert.equal(JSON.parse(fs.readFileSync(path.join(out,'delivery/QUALIFICATION-win32-x64.json'))).status,'passed');
}finally{
  spawnSync('/usr/bin/wineserver',['-k'],{env:environment,encoding:'utf8',timeout:30000});
}
