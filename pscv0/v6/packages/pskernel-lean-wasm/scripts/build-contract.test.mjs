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
assert.match(build,/-S "\$lean_source"(?:\s|\\)/);
assert.doesNotMatch(build,/-S "\$lean_source\/src"/);
assert.match(build,/-DSTAGE0_USE_GMP=OFF/);
assert.doesNotMatch(build,/-DSTAGE0_CMAKE_C_FLAGS=/,'match Lean 4.34 WASM bootstrap: do not override stage0 global C flags');
assert.doesNotMatch(build,/-DSTAGE0_CMAKE_CXX_FLAGS=/,'match Lean 4.34 WASM bootstrap: do not override stage0 global C++ flags');
assert.match(build,/-DSTAGE0_LEAN_EXTRA_CXX_FLAGS='-m32 -msse2 -mfpmath=sse -DLEAN_DEFAULT_THREAD_STACK_SIZE=8388608'/);
assert.match(build,/-DSTAGE0_LEANC_OPTS='-m32 -msse2 -mfpmath=sse'/);
assert.match(build,/-DSTAGE0_CMAKE_CXX_COMPILER=clang\+\+/);
assert.match(build,/-DSTAGE0_CMAKE_C_COMPILER=clang/);
assert.match(build,/-DSTAGE0_CMAKE_LIBRARY_PATH=\/usr\/lib\/i386-linux-gnu\//);
assert.match(build,/-DSTAGE0_PKG_CONFIG_EXECUTABLE=\/usr\/bin\/i386-linux-gnu-pkg-config/);
assert.match(build,/-DMULTI_THREAD=OFF/);
assert.match(build,/-DUSE_GMP=OFF/);
assert.match(build,/-DUSE_LAKE=OFF/);
assert.match(build,/-DMMAP=OFF/);
assert.match(build,/--target stage1-configure -j2/);
assert.match(build,/stage0_lean="\$lean_build\/stage0\/bin\/lean"/);
assert.match(build,/stage1_build="\$lean_build\/stage1"/);
assert.match(build,/stage1_lean_path="\$stage1_build\/lib\/lean"/);
assert.match(build,/stage1_leanc="\$stage1_build\/leanc\.sh"/);
assert.doesNotMatch(build,/-DPREV_STAGE="\$host_lean_prefix"/);
assert.match(build,/lean4-4\.34\.0-emscripten-uv-stubs\.patch/);
assert.match(build,/pskernel-lean\.wasm/);
assert.doesNotMatch(build,/emsdk\s+(install|activate)\s+(latest|tot)/);

// Build only the target stage1 static prerequisites consumed by the kernel
// provider. The default Lean ALL graph continues into shell/shared targets and
// would combine stock initialize.cpp with our Emscripten-only kernel shim.
const targetedLeanBuild='cmake --build "$stage1_build" --target make_stdlib leanrt leancpp_1 -j2';
assert.ok(build.includes(targetedLeanBuild),'targeted wasm32 stage1 static build must exist');
assert.doesNotMatch(build,/cmake --build "\$stage1_build" -j2/);
assert.doesNotMatch(build,/cmake --build "\$lean_build" --target stage1(?:\s|$)/);

// Installed x86_64 Lean verifies the exact pin only. Provider C must be emitted
// by the runnable native i386 stage0, but imports must resolve against the
// wasm32 stage1 .olean sysroot produced by target make_stdlib. Stage0 itself is
// C_ONLY and is therefore not an olean sysroot.
assert.match(build,/host_lean=.*command -v lean/);
assert.match(build,/actual_lean_commit=.*host_lean --githash/);
assert.match(build,/provider_overlay/);
assert.match(build,/provider_olean_dir/);
assert.match(build,/provider_c_dir/);
assert.match(build,/provider_modules=/);
assert.match(build,/PsKernelLean\/Convert/);
assert.match(build,/PsKernelLean\/Prelude/);
assert.match(build,/PsKernelLean\/Main/);
assert.match(build,/stage1_lean_path\/Lean\.olean/);
assert.doesNotMatch(build,/stage0_lean_path\/Lean\.olean/);
assert.match(build,/LEAN_PATH="\$provider_olean_dir:\$stage1_lean_path"/);
assert.match(build,/"\$stage0_lean" \\\n/);
assert.match(build,/--c=/);
assert.doesNotMatch(build,/"\$host_lean" \\\n\s+-o /,'x86_64 host Lean must not emit provider C');
assert.match(build,/"\$stage1_leanc" -O3 -c/);
assert.doesNotMatch(build,/LEAN_CC=.*emcc/);
assert.doesNotMatch(build,/\[\[lean_lib\]\]/);

const targetLeanBuildIndex=build.indexOf(targetedLeanBuild);
const targetSysrootCheckIndex=build.indexOf('stage1_lean_path/Lean.olean');
const providerCompileIndex=build.indexOf('provider_modules=');
assert.ok(targetLeanBuildIndex>=0,'target wasm32 static build must exist');
assert.ok(targetSysrootCheckIndex>=0,'target wasm32 olean sysroot check must exist');
assert.ok(providerCompileIndex>=0,'direct provider module compile list must exist');
assert.ok(targetLeanBuildIndex<targetSysrootCheckIndex,'stage1 make_stdlib must run before checking target oleans');
assert.ok(targetSysrootCheckIndex<providerCompileIndex,'target olean sysroot must be verified before provider C compilation');

assert.match(build,/packages\/foundation\/src\/Ps/);
assert.match(build,/packages\/core\/src\/Ps/);
assert.match(build,/packages\/environment\/src\/Ps/);
assert.match(build,/packages\/bridge\/src\/Ps/);
assert.match(build,/packages\/pskernel-lean\/provider\/PsKernelLean/);

// The target leanc.sh wrapper contributes target/platform flags and -L, but
// intentionally does not add Lean's complete toolchain libraries. Mirror the
// static closure required by the kernel-only provider using libleancpp_1,
// which excludes Lean's stock initialize.cpp.
const finalLinkStart=build.lastIndexOf('"$stage1_leanc" \\\n');
assert.ok(finalLinkStart>=0,'final WASM provider link invocation must exist');
const finalLink=build.slice(finalLinkStart);
const leanEmscriptenStaticLinkClosure=[
  '-lleancpp_1',
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
assert.doesNotMatch(finalLink,/(?:^|\s)-lleancpp(?:\s|\\|$)/m,'final provider link must not include stock initialize.cpp');

// Emscripten does not automatically pull the C++ runtime when the final link is
// driven by emcc. Keep C generation/compilation on the target leanc wrapper,
// but drive only the final link through em++.
assert.match(build,/for tool in cmake clang clang\+\+ emcc em\+\+ emar lean node git/);
assert.match(build,/LEAN_CC="\$\(command -v em\+\+\)" "\$stage1_leanc" \\\n/);

// Emscripten emits CommonJS Node glue for this CLI artifact. The npm package is
// `type: module`, so keep the generated launcher explicitly .cjs.
assert.match(build,/-o "\$out_dir\/pskernel-lean\.cjs"/);
assert.match(build,/node "\$out_dir\/pskernel-lean\.cjs" --health/);
assert.doesNotMatch(build,/-o "\$out_dir\/pskernel-lean\.js"/);

// Health alone is insufficient. The build must execute a real accepted
// admission and a real Lean-kernel rejection before reporting success.
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

// Lean 4.34 forces Emscripten LTO in its archived WASM path. On emsdk 6.0.9
// that can produce typed-WASM signature conflicts. Keep this provider on the
// same source/semantic closure but compile without LTO.
const emscriptenSettingsLine=patch.split('\n').find(line=>line.startsWith('+  set(EMSCRIPTEN_SETTINGS '));
assert.ok(emscriptenSettingsLine,'compatibility patch must set Emscripten settings');
assert.match(emscriptenSettingsLine,/-fwasm-exceptions/);
assert.doesNotMatch(emscriptenSettingsLine,/-flto(?:\s|"|$)/,'Lean WASM provider must disable LTO to preserve typed C ABI');

// Keep the frozen stage0 compatibility hunks while the native i386 stage0 is
// part of the production bootstrap, but those native objects must never enter
// the final wasm32 link.
const sectionFor=marker=>{
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
assert.match(workflow,/WASM target-width bootstrap contract/);
assert.match(workflow,/dpkg --add-architecture i386/);
assert.match(workflow,/gcc-multilib/);
assert.match(workflow,/g\+\+-multilib/);
assert.match(workflow,/libuv1-dev:i386/);
assert.match(workflow,/libssl-dev:i386/);
assert.match(workflow,/pkgconf:i386/);

console.log('PSC2_LEAN_KERNEL_WASM_BUILD_CONTRACT: PASS');
