// Actual ordinary-checked source -> independently admitted IR -> generated Python/PHP.
// Retained-original oracle data comes from native runtime-reference tests.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
const directory=path.resolve('dist/python-php-runtime-admission');
fs.mkdirSync(directory,{recursive:true});
const env={...process.env,PSC1_HOST_TOOLS:path.resolve('host-tools/artifacts.mjs')};
function run(command,args){
 const r=spawnSync(command,args,{env,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
 assert.equal(r.error,undefined,r.error?.message);assert.equal(r.status,0,(r.stdout||'')+(r.stderr||''));
 return r.stdout;
}
const oracle=path.join(directory,'oracle.json');
run('.lake/build/bin/psc1_script_runtime_normalization_tests',[oracle]);
const records=JSON.parse(fs.readFileSync(oracle));
const python=String.raw`import importlib.util,json,sys
spec=importlib.util.spec_from_file_location("runtime_probe",sys.argv[1])
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
assert sorted(m.__all__)==["dependencies","runtimeText","stateSummary"]
records=json.load(open(sys.argv[2],encoding="utf-8"))
for name,pybody,pydeps,phpbody,phpdeps in records:
 assert m.runtimeText(True,name)==pybody
 assert m.runtimeText(False,name)==phpbody
 assert m.dependencies(True,name)==pydeps
 assert m.dependencies(False,name)==phpdeps
for value in [0,1,37,1000000]:
 assert m.stateSummary(value,False)==value+1
 assert m.stateSummary(value,True)==0
print(json.dumps({"queries":len(records)*4,"stateQueries":8,"passed":True}))
`;
const php=String.raw`$m=require $argv[1];
$names=array_keys($m);sort($names);if($names!==['dependencies','runtimeText','stateSummary'])throw new RuntimeException('API');
$records=json_decode(file_get_contents($argv[2]),true,512,JSON_THROW_ON_ERROR);
foreach($records as [$name,$pybody,$pydeps,$phpbody,$phpdeps]){
 foreach([[$m['runtimeText'](true,$name),$pybody],[$m['runtimeText'](false,$name),$phpbody],[$m['dependencies'](true,$name),$pydeps],[$m['dependencies'](false,$name),$phpdeps]] as [$actual,$expected]){
  if($actual!==$expected)throw new RuntimeException('RETAINED_RUNTIME_MISMATCH');
 }
}
foreach([0,1,37,1000000] as $value){
 if(gmp_cmp($m['stateSummary'](gmp_init($value),false),$value+1)!==0||gmp_cmp($m['stateSummary'](gmp_init($value),true),0)!==0)throw new RuntimeException('STATE');
}
echo json_encode(['queries'=>count($records)*4,'stateQueries'=>8,'passed'=>true],JSON_THROW_ON_ERROR);
`;
const results=[];
for(const target of ['python','php'])for(const grammar of ['lean','ps']){
 const output=path.join(directory,target+'-'+grammar,'module.'+(target==='python'?'py':'php'));
 fs.mkdirSync(path.dirname(output),{recursive:true});
 run('.lake/build/bin/psc1',['build','test/fixtures/ScriptRuntimeProbe.'+grammar,'--target',target,'--assurance','ordinary','--out',output]);
 const manifest=JSON.parse(fs.readFileSync(output+'.bundle.json'));
 assert.equal(manifest.logicalCheckerCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
 assert.equal(manifest.behaviorallyVerified,false);assert.equal(manifest.assurance,'ordinary-checked');
 const observed=JSON.parse(target==='python'?run('python3',['-I','-c',python,output,oracle]):
  run('php',['-d','memory_limit=1G','-r',php,output,oracle]));
 assert.equal(observed.queries,records.length*4);assert.equal(observed.passed,true);
 results.push({target,grammar,...observed,logicalCheckerCommit:manifest.logicalCheckerCommit,scope:'Generated normalized runtime library, not a generated compiler or self-host qualification'});
}
fs.writeFileSync(path.join(directory,'results.json'),JSON.stringify({schema:'psc1-script-runtime-admission/1',testedCommit:process.env.GITHUB_SHA,results},null,2)+'\n');
console.log('PSC1_SCRIPT_RUNTIME_ADMITTED_EXECUTION: '+JSON.stringify(results));
