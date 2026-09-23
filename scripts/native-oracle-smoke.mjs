import {spawnSync} from 'node:child_process';
import {mkdtempSync,rmSync,writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {delimiter,join,resolve} from 'node:path';
import fs from 'node:fs';
import {createLeanNativeEvaluator} from './lean-native-evaluator.mjs';
import {nameFromDotted} from '../dist/src/core/name.js';

const leanExe=process.platform==='win32'?'lean.exe':'lean';
const candidates=[
  process.env.LEAN434_BIN,
  '/mnt/data/work/lean4src/lean4-4.34.0/build/release/stage1/bin',
  ...(process.env.PATH??'').split(delimiter),
].filter(Boolean).map(p=>resolve(p));
const bin=candidates.find(p=>fs.existsSync(join(p,leanExe)));
if(!bin)throw new Error('native-oracle-smoke: set LEAN434_BIN or put Lean 4.34.0 on PATH');
const lean=join(bin,leanExe);
const expectedVersion=/^Lean \\(version 4\\.34\\.0(?:,|\\)).*Release\\)?$/;
const expectedGitHash='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';
const versionRun=spawnSync(lean,['--version'],{encoding:'utf8',timeout:5000});
const version=versionRun.stdout.trim();
if(versionRun.error||versionRun.status!==0||!expectedVersion.test(version)){
  throw new Error('native-oracle-smoke: Lean version drift/failure: '+(versionRun.error?.message??versionRun.stderr??version));
}
const hashRun=spawnSync(lean,['--githash'],{encoding:'utf8',timeout:5000});
const leanGitHash=hashRun.stdout.trim();
if(hashRun.error||hashRun.status!==0||leanGitHash!==expectedGitHash){
  throw new Error('native-oracle-smoke: Lean git hash drift/failure: expected '+expectedGitHash+', got '+(hashRun.error?.message??hashRun.stderr??leanGitHash));
}

const tmp=mkdtempSync(join(tmpdir(),'pskernel-native-smoke-'));
try{
  const source=join(tmp,'NativeEvalFixture.lean');
  const olean=join(tmp,'NativeEvalFixture.olean');
  writeFileSync(source,`import Lean

namespace NativeEvalFixture

def n : Nat := 20 + 22

unsafe def bImpl : Bool := false

@[implemented_by bImpl]
def b : Bool := true

end NativeEvalFixture
`);

  const compile=spawnSync(lean,['-o',olean,source],{
    encoding:'utf8',
    timeout:30000,
    env:{...process.env,PATH:`${bin}${delimiter}${process.env.PATH??''}`},
  });
  if(compile.error)throw compile.error;
  if(compile.status!==0||compile.signal){
    throw new Error(
      `native-oracle-smoke: fixture compilation failed code=${compile.status} signal=${compile.signal??'none'}\n${compile.stderr??''}`,
    );
  }

  const env={
    ...process.env,
    PATH:`${bin}${delimiter}${process.env.PATH??''}`,
    LEAN_PATH:process.env.LEAN_PATH
      ?`${tmp}${delimiter}${process.env.LEAN_PATH}`
      :tmp,
  };
  const evaluator=createLeanNativeEvaluator({
    lean,
    moduleName:'NativeEvalFixture',
    cwd:resolve('.'),
    env,
  });

  const natResult=evaluator.evaluate(null,{
    kind:'nat',
    constant:nameFromDotted('NativeEvalFixture.n'),
  });
  if(natResult.kind!=='nat'||natResult.value!==42n){
    throw new Error(`native-oracle-smoke: Nat result mismatch: ${String(natResult.value)}`);
  }

  // This is deliberately stronger than a simple Bool evaluation: the logical
  // body is true while @[implemented_by] executes bImpl and must produce false.
  const boolResult=evaluator.evaluate(null,{
    kind:'bool',
    constant:nameFromDotted('NativeEvalFixture.b'),
  });
  if(boolResult.kind!=='bool'||boolResult.value!==false){
    throw new Error(
      'native-oracle-smoke: @[implemented_by] was not observed by compiler evaluation',
    );
  }

  console.log(JSON.stringify({
    ok:true,
    lean:version,
    leanGitHash,
    nat:42,
    implementedByBool:false,
  },null,2));
} finally {
  rmSync(tmp,{recursive:true,force:true});
}
