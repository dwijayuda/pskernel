// Publishless end-to-end npm-library acceptance for an installed global PSC0 CLI.
// Builds an ordinary third-party npm tarball, installs it locally, and imports
// .ps / .lean source without executing a guest JavaScript plugin.
import assert from 'node:assert/strict';
import {existsSync} from 'node:fs';
import {mkdir,writeFile,readFile,rm} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
import {pathToFileURL} from 'node:url';

const [variant,root,cli]=process.argv.slice(2);
if(!['ps','lean'].includes(variant)||!root||!cli)throw Error('usage: npm-library-canary.mjs ps|lean <dir> <psc-bin>');
const ext='.'+variant;
const library=path.join(root,'third-party-pslib'),project=path.join(root,'third-party-project');
await mkdir(path.join(library,'src','Demo'),{recursive:true});
await writeFile(path.join(library,'package.json'),JSON.stringify({
  name:'@psc-demo/math',version:'0.0.1',private:false,type:'module',
  files:['src/'],
  exports:{'./package.json':'./package.json'},
  proofscript:{library:{schemaVersion:1,modulePrefix:'Demo',sourceRoot:'src'}},
},null,2)+'\n');
await writeFile(path.join(library,'src','Demo','Math'+ext),'def demoAnswer : Nat := 42\n');
await mkdir(path.join(project,'src'),{recursive:true});
await writeFile(path.join(project,'package.json'),JSON.stringify({
  name:'psc-library-test',version:'0.0.0',private:true,type:'module',
  proofscript:{libraries:{Demo:'@psc-demo/math'}},
},null,2)+'\n');
const subprocess=(command,args,at,{negative=false,timeout=180000}={})=>{
  const run=spawnSync(command,args,{cwd:at,encoding:'utf8',timeout,maxBuffer:4*1024*1024});
  if(run.error||(!negative&&run.status!==0)||(negative&&run.status===0)){
    throw Error('PSC_NPM_LIBRARY_TEST_FAILED '+command+' '+args.join(' ')+
      ' status='+run.status+' '+String(run.error?.message||run.stderr||run.stdout).slice(0,3000));
  }
  return run;
};
const pack=path.join(root,'library-tarball');
await mkdir(pack,{recursive:true});
const result=subprocess('npm',['pack',library,'--pack-destination',pack,'--json','--ignore-scripts'],root);
const name=JSON.parse(result.stdout)[0]?.filename;
if(!name)throw Error('PSC_NPM_LIBRARY_PACK_MISSING');
subprocess('npm',['install','--prefix',project,'--offline','--ignore-scripts','--no-audit','--no-fund',
  '--no-package-lock',path.join(pack,name)],root,{timeout:180000});
await writeFile(path.join(project,'src','Main'+ext),
  'import Demo.Math\n\ndef answer : Nat := demoAnswer\n');
const checked=subprocess(process.execPath,[cli,'check','src/Main'+ext],project,{timeout:180000});
const built=subprocess(process.execPath,[cli,'build','src/Main'+ext,'--out','src/Main.js'],project,{timeout:240000});
const program=await import(pathToFileURL(path.join(project,'src','Main.js')).href);
const value=typeof program.answer==='function'?program.answer():program.answer;
assert.equal(value,42n,'third-party library linking result mismatch');
// Changing the library namespace metadata cannot silently switch modules.
const installed=path.join(project,'node_modules','@psc-demo','math','package.json');
const original=JSON.parse(await readFile(installed,'utf8'));
original.proofscript.library.modulePrefix='Other';
await writeFile(installed,JSON.stringify(original,null,2)+'\n');
const bad=subprocess(process.execPath,[cli,'build','src/Main'+ext,'--out','src/Invalid.js'],
  project,{negative:true,timeout:90000});
assert.equal(existsSync(path.join(project,'src','Invalid.js')),false,'forged package metadata emitted JS');
console.log('PSC_NPM_THIRD_PARTY_LIBRARY: PASS '+JSON.stringify({
  variant,installedPackage:'@psc-demo/math@0.0.1',check:true,build:true,
  answer:'42',wrongNamespaceRefused:true,sourceCodeOnly:true,
}));
