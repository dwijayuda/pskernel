import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here=path.dirname(fileURLToPath(import.meta.url));
const packageRoot=path.resolve(here,'..');
const repoRoot=path.resolve(packageRoot,'../../..');
const pin=JSON.parse(await readFile(path.join(packageRoot,'EMSCRIPTEN_PIN.json'),'utf8'));
assert.equal(pin.version,'6.0.9');
assert.notEqual(pin.version,'latest');
assert.notEqual(pin.version,'tot');

const build=await readFile(path.join(here,'build-wasm.sh'),'utf8');
assert.match(build,/-DCMAKE_TOOLCHAIN_FILE=/);
assert.match(build,/-S "\$lean_source\/src"/);
assert.match(build,/-DSTAGE=1/);
assert.match(build,/-DPREV_STAGE="\$host_lean_prefix"/);
assert.doesNotMatch(build,/STAGE0_CMAKE_TOOLCHAIN_FILE/);
assert.doesNotMatch(build,/STAGE0_CMAKE_AR/);
assert.match(build,/-DUSE_GMP=OFF/);
assert.match(build,/-DUSE_LAKE=OFF/);
assert.match(build,/-DMMAP=OFF/);
assert.match(build,/lean4-4\.34\.0-emscripten-uv-stubs\.patch/);
assert.match(build,/pskernel-lean\.wasm/);
assert.doesNotMatch(build,/emsdk\s+(install|activate)\s+(latest|tot)/);

// A native i386 bootstrap compiler was proven semantically broken in CI. The
// WASM artifact must instead build Lean 4.34's *current* src/ tree as STAGE=1
// with Emscripten, using the exact pinned native Lean 4.34 toolchain only as
// PREV_STAGE. This keeps generated C and the target runtime/kernel on one ABI.
assert.doesNotMatch(build,/-m32/);
assert.doesNotMatch(build,/i386-linux-gnu/);
assert.doesNotMatch(build,/STAGE0_CMAKE_C_FLAGS/);
assert.doesNotMatch(build,/STAGE0_CMAKE_CXX_FLAGS/);
assert.doesNotMatch(build,/STAGE0_LEAN_EXTRA_CXX_FLAGS/);
assert.doesNotMatch(build,/STAGE0_LEANC_OPTS/);
assert.doesNotMatch(build,/stage1-configure/);
assert.doesNotMatch(build,/--target stage0(?:\s|$)/);
assert.doesNotMatch(build,/--target stage1(?:\s|$)/);
assert.doesNotMatch(build,/target_lean_path/);
assert.doesNotMatch(build,/stage0\/bin\/lean/);
assert.doesNotMatch(build,/PSC2_STAGE0_PARSER_PROBE/);

assert.match(build,/cmake --build "\$lean_build" -j2/);
assert.match(build,/host_lean=.*command -v lean/);
assert.match(build,/host_lean_prefix=.*lean --print-prefix/);
assert.match(build,/host_lean_path=.*lib\/lean/);
assert.match(build,/wasm_leanc="\$lean_build\/leanc\.sh"/);
assert.match(build,/provider_overlay/);
assert.match(build,/provider_olean_dir/);
assert.match(build,/provider_c_dir/);
assert.match(build,/provider_modules=/);
assert.match(build,/PsKernelLean\/Convert/);
assert.match(build,/PsKernelLean\/Prelude/);
assert.match(build,/PsKernelLean\/Main/);
assert.match(build,/LEAN_PATH=.*host_lean_path/);
assert.match(build,/"\$host_lean"/);
assert.match(build,/--c=/);
assert.match(build,/"\$wasm_leanc" -O3 -c/);
assert.doesNotMatch(build,/LEAN_CC=.*emcc/);
assert.doesNotMatch(build,/"\$stage0_lake"\s+build\s+provider/);
assert.doesNotMatch(build,/\[\[lean_lib\]\]/);

const currentLeanBuildIndex=build.indexOf('cmake --build "$lean_build" -j2');
const providerCompileIndex=build.indexOf('provider_modules=');
assert.ok(currentLeanBuildIndex>=0,'current-source Emscripten Lean build must exist');
assert.ok(providerCompileIndex>=0,'direct provider module compile list must exist');
assert.ok(currentLeanBuildIndex<providerCompileIndex,'WASM Lean runtime/kernel must exist before provider C compilation');

assert.match(build,/packages\/foundation\/src\/Ps/);
assert.match(build,/packages\/core\/src\/Ps/);
assert.match(build,/packages\/environment\/src\/Ps/);
assert.match(build,/packages\/bridge\/src\/Ps/);
assert.match(build,/packages\/pskernel-lean\/provider\/PsKernelLean/);

// The target leanc.sh wrapper contributes compiler/platform flags and -L, but
// intentionally does not add Lean's toolchain libraries. Mirror Lean 4.34's
// own Emscripten TOOLCHAIN_STATIC_LINKER_FLAGS exactly for the provider link.
const finalLinkStart=build.lastIndexOf('"$wasm_leanc" \\\n');
assert.ok(finalLinkStart>=0,'final WASM provider link invocation must exist');
const finalLink=build.slice(finalLinkStart);
const leanEmscriptenStaticLinkClosure=[
  '-lleancpp',
  '-lInit',
  '-lStd',
  '-lLean',
  '-lnodefs.js',
  '-lleanrt',
  '-lstdc++',
];
let previousLinkFlag=-1;
for(const flag of leanEmscriptenStaticLinkClosure){
  const index=finalLink.indexOf(flag);
  assert.ok(index>=0,`final provider link is missing Lean Emscripten flag ${flag}`);
  assert.ok(index>previousLinkFlag,`Lean Emscripten link flag order drifted at ${flag}`);
  previousLinkFlag=index;
}

// Emscripten 6.0.9 does not automatically pull the C++ runtime when the final
// link is driven by emcc. Lean's kernel libraries contain C++, and run 49
// reached the final link then failed on operator new/delete. Keep generated C
// compilation on leanc/emcc, but force only the final link through em++.
assert.match(build,/for tool in cmake emcc em\+\+ emar lean node/);
assert.match(build,/LEAN_CC="\$\(command -v em\+\+\)" "\$wasm_leanc" \\\n/);

// Emscripten emits CommonJS Node glue (`require(...)`) for this CLI artifact.
// This npm package intentionally has `type: module`, so a .js launcher is
// interpreted as ESM and fails before Lean main runs. Keep the package ESM but
// mark only the generated launcher as CommonJS with the .cjs extension.
assert.match(build,/-o "\$out_dir\/pskernel-lean\.cjs"/);
assert.match(build,/node "\$out_dir\/pskernel-lean\.cjs" --health/);
assert.doesNotMatch(build,/-o "\$out_dir\/pskernel-lean\.js"/);

// Health proves the generated launcher can initialize. Require the artifact
// build itself to execute the actual admission path in WASM: one well-typed
// declaration must be accepted and one ill-typed declaration must be rejected
// by the Lean kernel.
assert.match(build,/PSC2_LEAN_KERNEL_WASM_ACCEPT_SMOKE/);
assert.match(build,/PSC2_LEAN_KERNEL_WASM_REJECT_SMOKE/);
const checkInvocations=build.match(/node "\$out_dir\/pskernel-lean\.cjs" --check/g)??[];
assert.ok(checkInvocations.length>=2,'WASM build must execute accepted and rejected --check smoke requests');
assert.match(build,/Test\.True/);
assert.match(build,/Test\.Bad/);
assert.match(build,/value\.accepted!==true/);
assert.match(build,/value\.accepted!==false/);
assert.match(build,/value\.errorKind!=="kernel-rejection"/);
const acceptedFixtureLine=build.split('\n').find(line=>line.startsWith('accepted_request='));
const rejectedFixtureLine=build.split('\n').find(line=>line.startsWith('rejected_request='));
assert.ok(acceptedFixtureLine?.includes(`'{"protocol"`),'accepted smoke fixture must be literal JSON without shell escape backslashes');
assert.ok(rejectedFixtureLine?.includes(`'{"protocol"`),'rejected smoke fixture must be literal JSON without shell escape backslashes');
assert.match(acceptedFixtureLine??'',/"format":"proofscript-checked-admissions"/);
assert.match(acceptedFixtureLine??'',/"version":2/);
assert.match(acceptedFixtureLine??'',/"admissions":\[/);
assert.match(rejectedFixtureLine??'',/"format":"proofscript-checked-admissions"/);
assert.match(rejectedFixtureLine??'',/"version":2/);
assert.match(rejectedFixtureLine??'',/"admissions":\[/);
assert.doesNotMatch(acceptedFixtureLine??'',/ps-canonical-admissions-v2/);
assert.doesNotMatch(rejectedFixtureLine??'',/ps-canonical-admissions-v2/);
assert.doesNotMatch(acceptedFixtureLine??'',/"declarations":\[/);
assert.doesNotMatch(rejectedFixtureLine??'',/"declarations":\[/);

const patch=await readFile(path.join(packageRoot,'patches/lean4-4.34.0-emscripten-uv-stubs.patch'),'utf8');
assert.match(patch,/runtime\/uv\/event_loop\.cpp/);
assert.match(patch,/lean_uv_event_loop_alive/);
assert.match(patch,/runtime\/uv\/system\.cpp/);
assert.match(patch,/lean_uv_os_get_group/);

// Keep the frozen stage0 compatibility hunks while this branch still carries
// them, but the production WASM provider must not build/link the stage0 closure.
const sectionFor = marker => {
  const start=patch.indexOf(marker);
  assert.ok(start>=0,`compatibility patch is missing ${marker}`);
  const next=patch.indexOf('\ndiff --git ',start+1);
  return patch.slice(start,next<0?patch.length:next);
};
const stage0Event=sectionFor('diff --git a/study/lean4-4.34.0/stage0/src/runtime/uv/event_loop.cpp');
assert.match(stage0Event,/LEAN_EXPORT uint8_t lean_uv_event_loop_alive\(\)/);
assert.match(stage0Event,/return false;/);
const stage0System=sectionFor('diff --git a/study/lean4-4.34.0/stage0/src/runtime/uv/system.cpp');
assert.match(stage0System,/lean_uv_os_get_group\(uint64_t gid\)/);
assert.match(stage0System,/\(void\)gid;/);

const workflow=await readFile(path.join(repoRoot,'.github/workflows/psc2-lean-kernel-wasm.yml'),'utf8');
assert.match(workflow,/6\.0\.9/);
assert.match(workflow,/emcc --version/);
assert.match(workflow,/build-wasm\.sh/);
assert.match(workflow,/wasm\/pskernel-lean\.cjs/);
assert.doesNotMatch(workflow,/wasm\/pskernel-lean\.js(?:\s|$)/m);
assert.doesNotMatch(workflow,/dpkg --add-architecture i386/);
assert.doesNotMatch(workflow,/gcc-multilib/);
assert.doesNotMatch(workflow,/g\+\+-multilib/);
assert.doesNotMatch(workflow,/libuv1-dev:i386/);
assert.doesNotMatch(workflow,/libssl-dev:i386/);
assert.doesNotMatch(workflow,/pkgconf:i386/);

console.log('PSC2_LEAN_KERNEL_WASM_BUILD_CONTRACT: PASS');
