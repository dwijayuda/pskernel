import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {chmod,mkdtemp,mkdir,readFile,readdir,rm,writeFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const build=await readFile(path.join(here,'build-wasm.sh'),'utf8');
const start=build.indexOf('\nstage0_lean=');
const end=build.indexOf('\n# stage1-configure has materialized',start);
assert.ok(start>=0&&end>start,'isolate the real stage0 readiness/probe block');
const probe=build.slice(start,end);
assert.match(probe,/LEAN_PATH="\$stage1_lean_path" "\$stage0_lean" --deps "\$lean_source\/src\/Lean\.lean"/);
for(const pkg of ['Init','Std','Lean']){
  assert.ok(probe.includes(`"$stage1_lean_path/${pkg}"`),`${pkg}: prepare future output package root`);
}
assert.ok(end<build.indexOf('cmake --build "$stage1_build" --target make_stdlib'),
  'the frontend probe must stay before the expensive stage1 build');

const temp=await mkdtemp(path.join(os.tmpdir(),'psc2-stage0-probe-'));
const leanBuild=path.join(temp,'build with spaces');
const stage1=path.join(leanBuild,'stage1');
const lib=path.join(stage1,'lib/lean');
const source=path.join(temp,'source');
const compiler=path.join(leanBuild,'stage0/bin/lean');
const pass='PSC2_LEAN_KERNEL_WASM_STAGE0_FRONTEND: PASS';
try{
  await mkdir(path.dirname(compiler),{recursive:true});
  await mkdir(path.join(source,'src'),{recursive:true});
  await writeFile(path.join(source,'src/Lean.lean'),'import Init\nimport Std\nimport Lean.Environment\n');
  // Shell-orchestration regression only. This stub models the package-root
  // lookup documented by Lean/Util/Path.lean and src/lean.mk.in. The real
  // native i386 parser and --deps invocation remain mandatory in build-wasm.sh.
  await writeFile(compiler,`#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == '--deps' && "$2" == "$lean_source/src/Lean.lean" ]]
for package in Init Std Lean; do
  if [[ ! -d "$PROBE_LIB/$package" ]]; then
    echo "unknown module prefix '$package'" >&2
    exit 2
  fi
done
[[ "$LEAN_PATH" == "$PROBE_LIB" ]]
if [[ "$PROBE_FAIL" == 1 ]]; then
  echo 'simulated stdout diagnostic'
  echo 'simulated frontend failure' >&2
  exit 7
fi
printf '%s\\n' "$PROBE_LIB/Init.olean" "$PROBE_LIB/Std.olean" "$PROBE_LIB/Lean/Environment.olean"
`);
  await chmod(compiler,0o755);
  const run=(script,extra={})=>spawnSync('bash',['-euo','pipefail','-c',script],{
    encoding:'utf8',timeout:10000,
    env:{...process.env,lean_build:leanBuild,stage1_build:stage1,lean_source:source,
      LEAN_PATH:'/must-not-use-host-oleans',PROBE_LIB:lib,PROBE_FAIL:'0',...extra},
  });
  // Reproduce the original missing-package failure with the actual probe block
  // but no preparation; no file is allowed to masquerade as a compiled olean.
  const missing=run(probe.replace(/^mkdir -p .*stage1_lean_path.*$/m,''));
  assert.notEqual(missing.status,0);
  assert.match(missing.stderr,/unknown module prefix 'Init'/);
  assert.ok(!missing.stdout.includes(pass));
  const success=run(probe);
  assert.ifError(success.error);
  assert.equal(success.status,0,success.stderr);
  assert.ok(success.stdout.includes(pass));
  assert.ok(success.stdout.includes(`${lib}/Init.olean`),'keep dependency output in the build log');
  for(const pkg of ['Init','Std','Lean']) assert.deepEqual(await readdir(path.join(lib,pkg)),[]);
  assert.deepEqual((await readdir(lib)).sort(),['Init','Lean','Std']);
  const broken=run(probe,{PROBE_FAIL:'1'});
  assert.equal(broken.status,7);
  assert.match(broken.stdout,/simulated stdout diagnostic/);
  assert.match(broken.stderr,/exit=7/);
  assert.match(broken.stderr,/simulated frontend failure/);
  assert.match(broken.stderr,/native 32-bit Lean stage0 frontend cannot parse/);
  assert.ok(!broken.stdout.includes(pass));
  await rm(compiler);
  const absent=run(probe);
  assert.notEqual(absent.status,0);
  assert.match(absent.stderr,/stage0 compiler was not produced/);
  assert.ok(!absent.stdout.includes(pass));
  console.log('PSC2_LEAN_KERNEL_WASM_FRONTEND_PROBE_CONTRACT: PASS (shell fixtures; empty target roots; isolated search path; fail-closed)');
}finally{
  await rm(temp,{recursive:true,force:true});
}
