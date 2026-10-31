// Runs with real Linux Node or real Windows Node under Wine. No platform spoofing.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath,pathToFileURL} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url));
const [tarArgument,reportArgument]=process.argv.slice(2),tarball=path.resolve(tarArgument);
const fixtures=JSON.parse(fs.readFileSync(path.join(here,'fixtures.json'),'utf8'));
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const windows=process.platform==='win32',platform=process.platform+'-'+process.arch;
assert.ok(['linux-x64','win32-x64'].includes(platform));assert.equal(process.version,'v22.23.3');
const npm=[path.join(path.dirname(process.execPath),'node_modules/npm/bin/npm-cli.js'),path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js')].find(fs.existsSync);assert.ok(npm);
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'psc1 native npm λ '));
const env={...process.env,PATH:path.dirname(process.execPath)+(windows?path.delimiter+path.join(process.env.SystemRoot||'C:\\windows','System32'):''),
  npm_config_registry:'http://127.0.0.1:9',npm_config_cache:path.join(tmp,'npm-cache'),npm_config_audit:'false',npm_config_fund:'false',npm_config_update_notifier:'false'};
for(const key of Object.keys(env))if(key==='NODE_OPTIONS'||key.startsWith('LEAN_')||key.startsWith('ELAN_')||key.startsWith('RUST')||key.startsWith('CARGO')||key.startsWith('LD_')||key.startsWith('DYLD_')||key==='GH_TOKEN')delete env[key];
const run=(executable,args,options={})=>{
  const start=performance.now();const result=spawnSync(executable,args,{cwd:tmp,env,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024,windowsHide:true,...options});
  assert.equal(result.error,undefined,String(result.error));
  if(!options.negative)assert.equal(result.status,0,(result.stderr||'')+'\n'+(result.stdout||'').slice(-3000));
  else assert.notEqual(result.status,0,'negative case accepted');
  return {...result,wallMs:performance.now()-start};
};
const observations=[],samples=[],negatives=[],installs=[],kernelCases=[];
try{
  for(const kind of ['local','global']){
    const prefix=path.join(tmp,kind+' installation');fs.mkdirSync(prefix);
    if(kind==='local')fs.writeFileSync(path.join(prefix,'package.json'),'{"private":true,"type":"module"}');
    run(process.execPath,[npm,'install',...(kind==='global'?['--global']:[]),'--prefix',prefix,'--offline','--ignore-scripts','--no-audit','--no-fund',tarball]);
    const packageRoot=path.join(prefix,kind==='global'&&!windows?'lib/node_modules':'node_modules','proofscript');
    const meta=JSON.parse(fs.readFileSync(path.join(packageRoot,'package.json')));assert.equal(meta.name,'proofscript');assert.equal(meta.version,'0.1.0-psc1-native.1');
    const cli=path.join(packageRoot,'bin/psc.mjs');
    const call=(args,negative=false)=>run(process.execPath,[cli,...args],{negative});
    const identity=JSON.parse(call(['--identity']).stdout);assert.equal(identity.verified,true);assert.equal(identity.platform,platform);assert.equal(identity.compiler,'generated-rust-native-G1');
    const manifest=JSON.parse(fs.readFileSync(path.join(packageRoot,'NATIVE_MANIFEST.json'))),selected=manifest.platforms[platform];
    assert.equal(call(['--version']).stdout.trim(),meta.version);
    const shim=kind==='local'?path.join(prefix,'node_modules/.bin','psc'+(windows?'.cmd':'')):
      path.join(prefix,windows?'psc.cmd':'bin/psc');
    assert.ok(fs.existsSync(shim),'missing npm command shim');
    let invoked;
    if(windows){
      const command=path.join(process.env.SystemRoot||'C:\\windows','System32/cmd.exe');
      invoked=run(command,['/d','/s','/c','""'+shim+'" --identity"'],{windowsVerbatimArguments:true});
    }else invoked=run(shim,['--identity']);
    assert.equal(JSON.parse(invoked.stdout).verified,true,'actual installed psc shim');
    installs.push({kind,offline:true,ignoreScripts:true,realNpmShim:true,identity});
    const api=await import(pathToFileURL(path.join(packageRoot,'index.mjs')).href);
    for(const item of fixtures.corpus){
      const previous=process.env.PATH;let result;
      try{process.env.PATH=env.PATH;result=api.compile({sources:item.sources.map(s=>({...s,kind:item.grammar})),entryModule:item.entry,assurance:item.assurance});}
      finally{process.env.PATH=previous;}
      assert.equal(result.status,'accepted');assert.equal(result.logicalAdmission,'accepted');
      assert.equal(result.source,item.reference.source);
      for(const key of ['originalIrSha256','specializedIrSha256','admissionsSha256'])assert.equal(result.receipt[key],item.reference[key]);
      const target=path.join(tmp,'target.mjs'),observer=path.join(tmp,'observe.mjs');fs.writeFileSync(target,result.source);
      fs.writeFileSync(observer,"import * as m from './target.mjs';\n"+item.consumer+'\nconsole.log(JSON.stringify('+item.observationExpression+'));\n');
      assert.deepEqual(JSON.parse(run(process.execPath,[observer]).stdout),item.expected);
      observations.push({kind,id:item.id,actualExecution:true,exactSourceIrAdmissions:true});
    }
    for(const grammar of ['ps','lean']){
      const source=path.join(tmp,'Main.'+grammar);
      fs.writeFileSync(source,grammar==='ps'?'def invert(flag : Bool) : Bool := if (flag) { false } else { true }\n':'def invert (flag : Bool) : Bool := if flag then false else true\n');
      const measured=call(['compile',source]),result=JSON.parse(measured.stdout);assert.equal(result.logicalAdmission,'accepted');
      samples.push({kind,grammar,wallMs:measured.wallMs,...result.timings});
    }
    const source=path.join(tmp,'Main.ps'),invalid=path.join(tmp,'Wrong.ps'),output=path.join(tmp,kind+' output');
    fs.writeFileSync(invalid,'def wrong : Nat := true\n');
    call(['compile',invalid],true);negatives.push(kind+':typing-refusal');
    const built=JSON.parse(call(['build',source,'--out',output]).stdout);assert.equal(built.logicalAdmission,'accepted');
    const pointer=path.join(output,'current.json'),before=fs.readFileSync(pointer);
    call(['build',invalid,'--out',output],true);assert.deepEqual(fs.readFileSync(pointer),before);negatives.push(kind+':prior-publication-retained');
    if(kind==='local'){
      const checker=path.join(packageRoot,...selected.checkerPath.split('/'));
      for(const item of fixtures.kernelFixtures){
        const r=spawnSync(checker,['--check'],{cwd:tmp,env,input:item.input,encoding:'utf8',timeout:120000,maxBuffer:32*1024*1024,windowsHide:true});
        assert.equal(r.error,undefined);const value=JSON.parse(r.stdout);assert.equal(value.accepted,item.accepted,item.id);
        assert.equal(value.leanVersion,'4.35.0');if(item.errorKind)assert.equal(value.errorKind,item.errorKind);
        kernelCases.push({id:item.id,accepted:value.accepted});
      }
      const changedResources=[selected.compilerPath,selected.checkerPath,windows?selected.guardPath:'dist/host-tools/generated-rust-guard.mjs'];
      for(const relative of changedResources){
        const file=path.join(packageRoot,...relative.split('/')),bytes=fs.readFileSync(file),changed=Buffer.from(bytes);changed[changed.length-1]^=1;
        fs.writeFileSync(file,changed);
        try{const result=call(['compile',source],true);assert.match(result.stderr,/RESOURCE_IDENTITY/);}
        finally{fs.writeFileSync(file,bytes);}
        assert.equal(JSON.parse(call(['check',source]).stdout).logicalAdmission,'accepted');negatives.push('tamper-refusal:'+relative);
      }
      if(windows){
        const {testWindowsJob}=await import('./native-windows-job-tests.mjs');
        const result=await testWindowsJob({packageRoot,selected,fixturesDirectory:here,env});
        assert.equal(result.passed,true);negatives.push(...result.cases);
      }
    }
  }
  const report={schema:'psc1-native-npm-installed/1',status:'passed',platform,node:process.version,
    windowsExecutionEnvironment:windows?'Windows Node/npm under Wine on Linux Actions':'not-applicable',nativeWindowsHostQualified:false,
    rootTarballSha256:sha(fs.readFileSync(tarball)),installs,observations,kernelCases,negatives,samples,
    compilerSdkRequired:false,installScripts:false,registryAccess:false,nativeCompiler:true,nativeKernel:true,nodeHostRequired:true,
    outputTargets:['js'],nativeG2G3:'not-qualified'};
  fs.mkdirSync(path.dirname(path.resolve(reportArgument)),{recursive:true});fs.writeFileSync(reportArgument,JSON.stringify(report,null,2)+'\n');
  console.log('PSC1_NATIVE_NPM_INSTALLED: '+JSON.stringify(report));
}finally{fs.rmSync(tmp,{recursive:true,force:true,maxRetries:20,retryDelay:100});}
