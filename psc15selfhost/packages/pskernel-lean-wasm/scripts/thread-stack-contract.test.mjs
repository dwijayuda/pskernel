import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {mkdtemp,readFile,rm,writeFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const build=await readFile(path.join(here,'build-wasm.sh'),'utf8');
const leanSource=path.resolve(here,'../../../../study/lean4-4.34.0');
const flags=build.match(/-DSTAGE0_LEAN_EXTRA_CXX_FLAGS='([^']+)'/)?.[1];
assert.ok(flags,'native stage0 C++ flags must be explicit');
const stackFlag=flags.split(/\s+/).find(flag=>flag.startsWith('-DLEAN_DEFAULT_THREAD_STACK_SIZE='));
assert.equal(stackFlag,'-DLEAN_DEFAULT_THREAD_STACK_SIZE=8388608');
assert.equal((build.match(/-DLEAN_DEFAULT_THREAD_STACK_SIZE=/g)??[]).length,1,
  'the stack override must remain scoped to native stage0, not global target flags');
assert.match(flags,/-m32 -msse2 -mfpmath=sse/);
assert.doesNotMatch(flags,/-DLEAN_EMSCRIPTEN/,'native stage0 must remain a native runtime');

const runtime=await readFile(path.join(leanSource,'stage0/src/runtime/thread.cpp'),'utf8');
const blocks=[...runtime.matchAll(/^#ifndef LEAN_DEFAULT_THREAD_STACK_SIZE\n#ifdef LEAN_EMSCRIPTEN\n#define LEAN_DEFAULT_THREAD_STACK_SIZE[^\n]*\n#else\n#define LEAN_DEFAULT_THREAD_STACK_SIZE[^\n]*\n#endif\n#endif/gm)];
assert.equal(blocks.length,1,'pinned overridable thread-stack default must be unique');
const defaults=blocks[0][0];
assert.match(runtime,/m_thread_stack_size = LEAN_DEFAULT_THREAD_STACK_SIZE/);
assert.match(runtime,/pthread_attr_setstacksize\(&m_attr, m_thread_stack_size\)/);

// Exercise actual pthread reservations under a fixed address-space budget.
// This is a resource/flag regression, not a replacement for compiling Prelude
// and the full target sysroot with the native i386 Lean frontend in CI.
const source=`#include <pthread.h>
#include <sys/resource.h>
#include <errno.h>
#include <stdio.h>
${defaults}
static pthread_mutex_t lock=PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t ready=PTHREAD_COND_INITIALIZER;
static int release_threads=0;
static void *worker(void *unused){
  (void)unused;
  pthread_mutex_lock(&lock);
  while(!release_threads) pthread_cond_wait(&ready,&lock);
  pthread_mutex_unlock(&lock);
  return NULL;
}
int main(void){
  struct rlimit budget={256UL*1024*1024,256UL*1024*1024};
  if(setrlimit(RLIMIT_AS,&budget)) return 90;
  pthread_attr_t attr;
  if(pthread_attr_init(&attr)) return 91;
  if(pthread_attr_setstacksize(&attr,LEAN_DEFAULT_THREAD_STACK_SIZE)) return 92;
  pthread_t threads[4];
  int created=0,error=0;
  for(;created<4;created++){
    error=pthread_create(&threads[created],&attr,worker,NULL);
    if(error) break;
  }
  pthread_mutex_lock(&lock);
  release_threads=1;
  pthread_cond_broadcast(&ready);
  pthread_mutex_unlock(&lock);
  for(int i=0;i<created;i++) if(pthread_join(threads[i],NULL)) return 93;
  pthread_attr_destroy(&attr);
  printf("stack=%zu created=%d error=%d\\n",(size_t)LEAN_DEFAULT_THREAD_STACK_SIZE,created,error);
#ifdef EXPECT_EXHAUSTION
  return created==0&&error==EAGAIN?0:94;
#else
  return created==4&&error==0?0:95;
#endif
}
`;
const temp=await mkdtemp(path.join(os.tmpdir(),'psc2-thread-stack-'));
function success(command,args){
  const result=spawnSync(command,args,{encoding:'utf8',timeout:30000});
  assert.ifError(result.error);
  assert.equal(result.signal,null);
  assert.equal(result.status,0,`${command}: ${result.stdout}${result.stderr}`);
  return result.stdout;
}
try{
  const file=path.join(temp,'stack.c');
  await writeFile(file,source);
  for(const bits of [32,64]){
    for(const mode of ['old-native','stage0-override','emscripten-default']){
      const executable=path.join(temp,`stack-${bits}-${mode}`);
      const extra=mode==='old-native'?['-DEXPECT_EXHAUSTION']:
        mode==='stage0-override'?[stackFlag]:['-DLEAN_EMSCRIPTEN'];
      success('clang',[`-m${bits}`,'-pthread','-O1',...extra,file,'-o',executable]);
      const output=success(executable,[]);
      assert.match(output,mode==='old-native'?/stack=1073741824 created=0 error=/:
        /stack=8388608 created=4 error=0/);
    }
  }
  console.log('PSC2_LEAN_KERNEL_WASM_THREAD_STACK_CONTRACT: PASS (native32/native64 pthreads; bounded address space; old-default negative controls; stage0-only override)');
}finally{
  await rm(temp,{recursive:true,force:true});
}
