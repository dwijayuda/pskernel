// Import-closure guard and source inventory, not a full v7 conformance claim.
import assert from 'node:assert/strict';
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const packages = ['foundation','syntax','core','environment','meta','elab',
  'bridge','compiler-ir','erasure','compiler','codegen','backend-ts'];
const sourceRoots = packages.map(name => 'packages/' + name + '/src');
const hostRoots = [...sourceRoots, 'host/src', 'packages/pskernel-lean/provider'];
const sha = text => createHash('sha256').update(text).digest('hex');

function withoutComments(source) {
  let result = '', depth = 0, string = false;
  for (let i = 0; i < source.length; i++) {
    const pair = source.slice(i, i + 2), ch = source[i];
    if (depth) {
      if (pair === '/-') { depth++; i++; }
      else if (pair === '-/') { depth--; i++; }
      else if (ch === '\n') result += '\n';
    } else if (string) {
      result += ch;
      if (ch === '\\') { result += source[++i] ?? ''; }
      else if (ch === '"') string = false;
    } else if (pair === '/-') { depth = 1; result += ' '; i++; }
    else if (pair === '--') {
      while (i < source.length && source[i] !== '\n') i++;
      result += '\n';
    } else { result += ch; if (ch === '"') string = true; }
  }
  assert.equal(depth, 0, 'unclosed source comment');
  return result;
}

async function closure(roots, portable) {
  const visited = new Map();
  async function visit(name) {
    if (visited.has(name)) return;
    if (/^(Init|Lean|Std)(\.|$)/.test(name)) {
      assert(!portable || name === 'Init' || name.startsWith('Init.'),
        'host/library dependency needs explicit portable admission: ' + name);
      return;
    }
    let source, relative;
    for (const dir of portable ? sourceRoots : hostRoots) {
      const candidate = dir + '/' + name.replaceAll('.', '/') + '.lean';
      try { source = await readFile(path.join(root, candidate), 'utf8'); relative = candidate; break; }
      catch (error) { if (error.code !== 'ENOENT') throw error; }
    }
    assert(relative, 'unmapped dependency: ' + name);
    assert(!relative.includes('pskernel-core'), 'excluded checker dependency');
    const clean = withoutComments(source);
    if (portable) assert(!/^\s*(?:(?:private|protected)\s+)?(?:unsafe|partial)\s+def\b/m.test(clean),
      'nonportable definition: ' + relative);
    const imports = [...clean.matchAll(/^\s*(?:(?:public|meta)\s+)*import\s+(?:all\s+)?([^\n]+)/gm)]
      .flatMap(m => m[1].trim().split(/\s+/));
    visited.set(name, {module: name, path: relative, sha256: sha(source), imports});
    for (const dependency of imports) await visit(dependency);
  }
  for (const name of roots) await visit(name);
  return [...visited.values()].sort((a,b) => a.module.localeCompare(b.module));
}

const portable = await closure(['Ps.Compiler.Pscv0', 'Ps.BackendTs.Readable', 'Ps.CompilerIr.Checked'], true);
const native = await closure(['Ps.Host.NativeV7'], false);
const toolchain = (await readFile(path.join(root, 'v7-native/lean-toolchain'), 'utf8')).trim();
assert.equal(toolchain, 'leanprover/lean4:v4.35.0-rc4');
const report = {
  schema: 'pscv0-native-source-profile/1', source: process.env.GITHUB_SHA ?? null, toolchain,
  portable, native,
  policy: {compilerAuthoring: 'lean', kernel: 'official-native-lean',
    pskernelCore: false, compilerPsGeneration: false, selfhostGeneration: false},
  limits: 'Source/import guard only; full authoring-language and runtime primitive coverage remains pending.'
};
await mkdir(path.join(root, 'dist/pscv0-native'), {recursive:true});
await writeFile(path.join(root, 'dist/pscv0-native/source-profile.json'), JSON.stringify(report, null, 2) + '\n');
console.log('PSCV0_NATIVE_PROFILE: PASS ' + portable.length + ' portable modules; ' + native.length + ' native closure modules; no pskernel-core');
