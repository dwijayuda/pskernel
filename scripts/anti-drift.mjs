import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('..', import.meta.url));
const lock = JSON.parse(readFileSync(join(root, 'ORACLE_LOCK.json'), 'utf8'));
if (lock.lean !== '4.34.0') throw new Error('Oracle drift: Lean target changed');
if (lock.leanTag !== 'v4.34.0') throw new Error('Oracle drift: Lean tag changed');
if (lock.leanCommit !== '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b') throw new Error('Oracle drift: exact Lean v4.34.0 commit changed');
if (lock.lean4export?.commit !== '076e8e57707e813375e8f9da8bf989799ace9680') throw new Error('Oracle drift: lean4export pin changed');
if (lock.lean4export?.format !== '3.1.0') throw new Error('Oracle drift: lean4export format changed');
if (lock.lean4export?.toolchain !== 'leanprover/lean4:v4.34.0') throw new Error('Oracle drift: lean4export toolchain changed');
const forbidden = [/lean\s*4\.3[0-3]/i, /equivmanager/i];
function walk(p) { for (const n of readdirSync(p)) { const q=join(p,n); const s=statSync(q); if(s.isDirectory()) walk(q); else if(q.endsWith('.ts')) { const t=readFileSync(q,'utf8'); for(const r of forbidden) if(r.test(t)) throw new Error(`Anti-drift violation ${r} in ${q}`); } } }
walk(join(root,'src'));
const nativePath=join(root,'src','kernel','reduction','native.ts');
if (!existsSync(nativePath)) throw new Error('Anti-drift violation: Lean v4.34.0 native-reduction boundary is missing');
const nativeSource=readFileSync(nativePath,'utf8');
for (const marker of ['NativeEvaluator','LeanReduceNat','LeanReduceBool'])
  if (!nativeSource.includes(marker)) throw new Error(`Anti-drift violation: native-reduction boundary lost ${marker}`);
const pinnedTypeChecker=join(root,'study','lean4-4.34.0','src','kernel','type_checker.cpp');
if (!existsSync(pinnedTypeChecker)) throw new Error('Anti-drift violation: pinned Lean 4.34 type_checker.cpp is missing');
const pinnedTypeCheckerSource=readFileSync(pinnedTypeChecker,'utf8');
for (const marker of ['reduce_native','g_lean_reduce_nat','g_lean_reduce_bool'])
  if (!pinnedTypeCheckerSource.includes(marker)) throw new Error(`Anti-drift violation: pinned Lean v4.34.0 oracle lost ${marker}`);

// Package implementation source is TypeScript-first. Runtime .js is generated
// under dist; hand-authored .mjs in packages would reintroduce two source
// languages and bypass strict tsc checking.
function forbidPackageMjs(p) {
  for (const n of readdirSync(p)) {
    const q=join(p,n); const s=statSync(q);
    if (s.isDirectory()) forbidPackageMjs(q);
    else if (q.endsWith('.mjs')) throw new Error('Anti-drift violation: hand-authored .mjs package source in ' + q);
  }
}
forbidPackageMjs(join(root,'packages'));
const syntaxPkg = JSON.parse(readFileSync(join(root,'packages','syntax','package.json'),'utf8'));
if (syntaxPkg.proofscript?.sourceLanguage !== 'typescript') throw new Error('Anti-drift violation: @proofscript/syntax must remain TypeScript-authored');
if (syntaxPkg.proofscript?.specVersion !== '0.7.0' || syntaxPkg.proofscript?.leanSemantics !== '4.34.0') throw new Error('Anti-drift violation: @proofscript/syntax semantic pin drifted');
console.log('anti-drift: PASS (Lean 4.34.0 pinned; packages TypeScript-first)');
