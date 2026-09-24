import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('..', import.meta.url));
const lock = JSON.parse(readFileSync(join(root, 'ORACLE_LOCK.json'), 'utf8'));
if (lock.lean !== '4.34.0') throw new Error('Oracle drift: Lean target changed');
if (lock.lean4export?.commit !== '076e8e57707e813375e8f9da8bf989799ace9680') throw new Error('Oracle drift: lean4export pin changed');
if (lock.lean4export?.format !== '3.1.0') throw new Error('Oracle drift: lean4export format changed');
if (lock.lean4export?.toolchain !== 'leanprover/lean4:v4.34.0') throw new Error('Oracle drift: lean4export toolchain changed');
const forbidden = [/lean\s*4\.3[0-3]/i, /equivmanager/i, /NativeEvaluator/, /LeanReduce(?:Nat|Bool)/];
function walk(p) { for (const n of readdirSync(p)) { const q=join(p,n); const s=statSync(q); if(s.isDirectory()) walk(q); else if(q.endsWith('.ts')) { const t=readFileSync(q,'utf8'); for(const r of forbidden) if(r.test(t)) throw new Error(`Anti-drift violation ${r} in ${q}`); } } }
walk(join(root,'src'));

// File URL pathnames are not filesystem paths on Windows (for example,
// /C:/work/...); all repository scripts must convert file URLs explicitly.
const unsafeFileUrlPathname=/import[.]meta[.]url\s*[)]\s*[.]pathname/;
function forbidUnsafeScriptFileUrlPaths(p) {
  for (const n of readdirSync(p)) {
    const q=join(p,n); const s=statSync(q);
    if (s.isDirectory()) forbidUnsafeScriptFileUrlPaths(q);
    else if ((q.endsWith('.mjs')||q.endsWith('.js')) && unsafeFileUrlPathname.test(readFileSync(q,'utf8'))) {
      throw new Error('Anti-drift violation: use fileURLToPath for import.meta.url filesystem paths in ' + q);
    }
  }
}
forbidUnsafeScriptFileUrlPaths(join(root,'scripts'));
if (existsSync(join(root,'src','kernel','reduction','native.ts'))) throw new Error('Anti-drift violation: final Lean 4.34 has no native-reduction compatibility layer');
if (existsSync(join(root,'packages','native-ir'))) throw new Error('Anti-drift violation: final Lean 4.34 has no native-ir kernel-extension package');

const dependencyExporter=readFileSync(join(root,'oracle','replay-probe','DependencyExport.lean'),'utf8');
for (const marker of [
  'if dv.safety == .safe then',
  'dumpConstants env ci.getUsedConstantsAsSet',
  'dumpDefinition dv',
]) {
  if (!dependencyExporter.includes(marker)) throw new Error('Anti-drift violation: safe DefinitionVal.all replay contract lost ' + marker);
}
if (dependencyExporter.includes('| .defnInfo dv =>\n      let group := if dv.all.isEmpty then [dv.name] else dv.all')) {
  throw new Error('Anti-drift violation: safe definitions must not be grouped by informational DefinitionVal.all');
}

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
