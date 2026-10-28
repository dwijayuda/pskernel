// CI-only native portability comparison. Requires prebuilt binaries in both roots.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';

const args=process.argv.slice(2);
assert.equal(args.length,6,'--baseline ROOT --current ROOT --out DIRECTORY');
function option(name){const i=args.indexOf(name);assert.ok(i>=0&&args[i+1]);return path.resolve(args[i+1]);}
const baseline=option('--baseline'),current=option('--current'),output=option('--out');
assert.notEqual(baseline,current);assert.ok(!fs.existsSync(output));
fs.mkdirSync(path.join(output,'logs'),{recursive:true});fs.mkdirSync(path.join(output,'fixtures'));
fs.mkdirSync(path.join(output,'requests'));
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const json=value=>JSON.stringify(value,null,2)+'\n';
const put=(relative,bytes)=>fs.writeFileSync(path.join(output,relative),bytes);
const protocol=await import(pathToFileURL(path.join(current,'host-tools/compiler-host-protocol.mjs')).href);
const report={schema:'psc1-native-port-equivalence/1',status:'running',startedAt:new Date().toISOString(),
  baselineCommit:null,currentCommit:null,toolPins:[],fixturePins:[],observations:[],comparisons:[],
  scope:'finite exact native source-port behavior and independent admission; not a compiler preservation proof'};
const save=()=>put('comparison.json',json(report));
function run(label,cwd,executable,commandArgs,expectedFailure=false){
  const started=Date.now(),r=spawnSync(executable,commandArgs,{cwd,encoding:'utf8',timeout:300000,maxBuffer:32*1024*1024,killSignal:'SIGKILL'});
  const stdout=r.stdout??'',stderr=r.stderr??'';
  put('logs/'+label+'.stdout',stdout);put('logs/'+label+'.stderr',stderr);
  const row={label,executable,args:commandArgs,status:r.status,signal:r.signal,error:r.error?String(r.error):null,
    elapsedMs:Date.now()-started,stdoutSha256:sha(stdout),stderrSha256:sha(stderr)};
  report.observations.push(row);save();
  assert.equal(r.error,undefined,label+': '+String(r.error));assert.equal(r.signal,null,label);
  if(expectedFailure)assert.notEqual(r.status,0,label+' unexpectedly accepted');
  else assert.equal(r.status,0,label+': '+stderr);
  return{stdout,stderr,row};
}
function fixture(label,relative){
  const bytes=fs.readFileSync(path.join(baseline,relative));
  const destination=path.join(output,'fixtures',label);
  fs.writeFileSync(destination,bytes);
  report.fixturePins.push({label,origin:'baseline',path:relative,bytes:bytes.length,sha256:sha(bytes)});
  return destination;
}
function compare(label,before,after){
  assert.equal(after.row.status,before.row.status,label+' exit status');
  assert.equal(after.stdout,before.stdout,label+' stdout differs');
  assert.equal(after.stderr,before.stderr,label+' stderr differs');
  report.comparisons.push({label,status:'equal',stdoutSha256:sha(before.stdout),stderrSha256:sha(before.stderr)});
  save();
}
try{
  report.baselineCommit=run('baseline-commit',baseline,'git',['rev-parse','HEAD']).stdout.trim();
  report.currentCommit=run('current-commit',current,'git',['rev-parse','HEAD']).stdout.trim();
  assert.equal(report.baselineCommit,'29c82adc77cbd1bf271acab75b6f8d51ef0a9ee6');
  assert.equal(report.currentCommit,process.env.GITHUB_SHA);
  const tools=Object.fromEntries([['baseline',baseline],['current',current]].map(([name,root])=>[name,{
    producer:path.join(root,'.lake/build/bin/psc1_modular_pilot'),
    checker:path.join(root,'.lake/build/bin/psc1_independent_checker'),
    bridge:path.join(root,'.lake/build/bin/psc1_bridge_tests')
  }]));
  for(const[name,roles]of Object.entries(tools))for(const[role,file]of Object.entries(roles)){
    const stat=fs.lstatSync(file);assert.ok(stat.isFile()&&!stat.isSymbolicLink());
    report.toolPins.push({generation:name,role,file,bytes:stat.size,sha256:sha(fs.readFileSync(file))});
  }
  function sources(rows){return rows.map(([module,relative])=>{
    const bytes=fs.readFileSync(path.join(baseline,relative)),text=bytes.toString('utf8');
    assert.ok(Buffer.from(text,'utf8').equals(bytes),'exact UTF-8 fixture required');
    report.fixturePins.push({module,origin:'baseline',path:relative,bytes:bytes.length,sha256:sha(bytes)});
    return{module,kind:'lean',text};
  });}
  const legacy=sources([
    ['Ps.Foundation.Name','packages/foundation/src/Ps/Foundation/Name.lean'],
    ['Pilot.Consumer','test/modular/Consumer.lean']
  ]);
  const extended=sources([
    ['Ps.Foundation.List','packages/foundation/src/Ps/Foundation/List.lean'],
    ['Ps.Foundation.Name','packages/foundation/src/Ps/Foundation/Name.lean'],
    ['Ps.Foundation.Text','packages/foundation/src/Ps/Foundation/Text.lean'],
    ['Ps.Bridge.Json','packages/bridge/src/Ps/Bridge/Json.lean'],
    ['Pilot.Consumer','test/modular/Extended.lean']
  ]);
  function request(label,sourceRows,version='1'){
    const digest=protocol.compilerSourceClosureDigest(sourceRows);
    return['psc1-modular-pilot/'+version,'native-port-'+label,digest,'lean','checked',
      sourceRows.at(-1).module,sourceRows.map(s=>[s.module,s.text])];
  }
  const malformed=JSON.parse(JSON.stringify(legacy));
  malformed[1].text='import Ps.Foundation.Name\n\ndef broken : Nat :=\n';
  const illtyped=JSON.parse(JSON.stringify(legacy));
  illtyped[1].text='import Ps.Foundation.Name\n\ndef broken : Nat := true\n';
  const cases=[
    {label:'legacy',sources:legacy,wire:request('legacy',legacy),accepted:true},
    {label:'extended',sources:extended,wire:request('extended',extended,'2'),accepted:true},
    {label:'wire-protocol',wire:['psc1-modular-pilot/3'],accepted:false},
    {label:'wire-arity',wire:request('wire-arity',legacy).slice(0,6),accepted:false},
    {label:'parse-refusal',wire:request('parse-refusal',malformed),accepted:false},
    {label:'elaboration-refusal',wire:request('elaboration-refusal',illtyped),accepted:false}
  ];
  for(const test of cases){
    const bytes=Buffer.from(JSON.stringify(test.wire)),requestFile=path.join(output,'requests',test.label+'.json');
    fs.writeFileSync(requestFile,bytes);
    const executions={};
    for(const[generation,root]of [['baseline',baseline],['current',current]]){
      const selected=tools[generation];
      const execution=run(test.label+'-'+generation,root,'/usr/bin/prlimit',
        ['--as=4294967296','--stack=8388608','--cpu=240','--',selected.producer,requestFile],!test.accepted);
      assert.equal(sha(fs.readFileSync(requestFile)),sha(bytes),'request changed');
      if(test.accepted){
        const candidate=JSON.parse(execution.stdout);
        assert.equal(candidate.candidateOnly,true);assert.equal(candidate.admission,'not-run');
        assert.equal(candidate.requestId,test.wire[1]);assert.equal(candidate.sourceClosureDigest,test.wire[2]);
        const session=protocol.createCompilerHostSession({requestId:test.wire[1],target:'js',
          sources:test.sources,canonicalAdmissions:candidate.admissions,checkerExecutable:selected.checker});
        const receipt=session.admit(JSON.stringify(candidate.admissionRequest));
        assert.equal(receipt.accepted,true);
        put('logs/'+test.label+'-'+generation+'.admission.json',json(receipt));
        report.observations.push({label:test.label+'-'+generation+'-independent-admission',executed:true,
          checkerSha256:sha(fs.readFileSync(selected.checker)),admissionsSha256:sha(candidate.admissions),
          receiptSha256:sha(json(receipt)),receipt});
        save();
      }else assert.match(execution.stderr,/PSC1_MODULE_/);
      executions[generation]=execution;
    }
    compare(test.label,executions.baseline,executions.current);
    report.comparisons.at(-1).requestSha256=sha(bytes);
    report.comparisons.at(-1).requestBytes=bytes.length;
  }
  for(const relative of ['test/modular/Plan.lean','test/modular/ExtendedPlan.lean','test/modular/Provenance.lean']){
    const label=path.basename(relative,'.lean').toLowerCase(),file=fixture(label+'.lean',relative);
    const before=run(label+'-baseline',baseline,'lake',['env','lean','--run',file]);
    const after=run(label+'-current',current,'lake',['env','lean','--run',file]);
    compare(label,before,after);
  }
  assert.equal(sha(fs.readFileSync(path.join(baseline,'test/BridgeTests.lean'))),
    sha(fs.readFileSync(path.join(current,'test/BridgeTests.lean'))),'bridge suite fixture changed');
  compare('bridge-suite',run('bridge-baseline',baseline,tools.baseline.bridge,[]),
    run('bridge-current',current,tools.current.bridge,[]));
  for(const name of ['native-bridge-observer.lean','native-api-observer.lean']){
    const bytes=fs.readFileSync(path.join(current,'standalone',name)),file=path.join(output,'fixtures',name);
    fs.writeFileSync(file,bytes);report.fixturePins.push({path:'standalone/'+name,origin:'current-shared-observer',
      bytes:bytes.length,sha256:sha(bytes)});
    const label=name.slice(0,-5);
    compare(label,run(label+'-baseline',baseline,'lake',['env','lean','--run',file]),
      run(label+'-current',current,'lake',['env','lean','--run',file]));
  }
  for(const pin of report.toolPins){const bytes=fs.readFileSync(pin.file);
    assert.equal(bytes.length,pin.bytes);assert.equal(sha(bytes),pin.sha256,'native tool changed');}
  report.status='passed';report.finishedAt=new Date().toISOString();save();
  console.log('PSC1_NATIVE_PORT_EQUIVALENCE: '+JSON.stringify(report));
}catch(error){report.status='failed';report.finishedAt=new Date().toISOString();
  report.failure={message:String(error.message),stack:error.stack};save();throw error;}
