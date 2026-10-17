// One compact fixture per source-word profile, shared by every runtime.
// Compiler implementation and source admission remain native Lean.
import assert from 'node:assert/strict';
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
const mode = process.argv[2];
const directory = path.resolve(process.argv[3]);
const checks = JSON.parse(await readFile(path.join(directory, 'checks.json'), 'utf8'));
function run(tool, args) {
  const result = spawnSync(tool, args, {encoding:'utf8', maxBuffer:32*1024*1024});
  assert.equal(result.status, 0, tool + ' ' + args.join(' ') + '\n' + result.stdout + '\n' + result.stderr);
  return result.stdout.trim();
}
const foreign = name => name.replace(/[A-Z]/g, c => '-' + c.toLowerCase());
const exportsOf = wit => [...wit.matchAll(/export\s+%?([\w-]+):\s*func\(([^)]*)\)(?:\s*->\s*(\w+))?;/g)]
  .map(m => [m[1], m[2].replaceAll('%','').replace(/\s/g,''), m[3] ?? ''])
  .sort((a,b) => a[0].localeCompare(b[0]));
const rustBlocks = [];
for (const bits of [32,64]) {
  const stem = path.join(directory, 'words' + bits);
  if (mode === 'wasm') {
    const cli = path.resolve('.lake/build/bin/pscv0_native');
    run(cli, ['--word-size', String(bits), '--emit-all', stem + '.ps', stem]);
    run(cli, ['--word-size', String(bits), '--emit-wasm', stem + '.ps', stem, path.join(directory,'exports.json')]);
    const declared = exportsOf(run('wasm-tools', ['component','wit',stem + '.wit']));
    assert.deepEqual(exportsOf(run('wasm-tools', ['component','wit',stem + '.wasm'])), declared);
    // WIT permits %escaped identifiers, including %value. Compare the exact
    // parsed scalar signature, not a particular spelling of the parameter.
    assert.deepEqual(declared.find(e => e[0] === 'echo-unsigned'),
      ['echo-unsigned', 'value:u' + bits, 'u' + bits]);
    assert.deepEqual(declared.find(e => e[0] === 'echo-signed'),
      ['echo-signed', 'value:s' + bits, 's' + bits]);
    for (const kind of ['', '.core']) {
      run('wasm-tools',['validate',stem + kind + '.wasm']);
      run('wasm-tools',['parse',stem + kind + '.wat','-o',stem + kind + '.roundtrip.wasm']);
      run('wasm-tools',['validate',stem + kind + '.roundtrip.wasm']);
      for (const [input,output] of [
        [stem + kind + '.wasm',stem + kind + '.stripped.wasm'],
        [stem + kind + '.roundtrip.wasm',stem + kind + '.roundtrip.stripped.wasm']])
        run('wasm-tools',['strip','--delete','^(name|component-name)$',input,'-o',output]);
      assert.deepEqual(await readFile(stem + kind + '.stripped.wasm'),
        await readFile(stem + kind + '.roundtrip.stripped.wasm'));
    }
    const {instance} = await WebAssembly.instantiate(await readFile(stem + '.core.wasm'), {});
    const wat = await readFile(stem + '.core.wat', 'utf8');
    assert(!/\(memory\b/.test(wat), 'scalar GC core unexpectedly uses linear memory');
    for (const name of checks) {
      assert.equal(instance.exports[name](), 1, bits + ' V8 ' + name);
      assert.equal(run('wasmtime',['run','--invoke',foreign(name) + '()',stem + '.wasm']), 'true', bits + ' component ' + name);
    }
    assert.equal(instance.exports.echoSigned(bits === 32 ? -7 : -7n), bits === 32 ? -7 : -7n);
    assert.equal(run('wasmtime',['run','--invoke','echo-signed(-7)',stem + '.wasm']), '-7');
    assert.equal(run('wasmtime',['run','--invoke','echo-unsigned(' + ((1n << BigInt(bits))-1n) + ')',stem + '.wasm']),
      String((1n << BigInt(bits))-1n));
  } else if (mode === 'ecma') {
    const output = path.join(directory, 'ts' + bits);
    await mkdir(output,{recursive:true});
    run(process.argv[4], ['--ignoreConfig',stem + '.ts','--outDir',output,'--target','ES2022',
      '--module','ES2022','--moduleResolution','bundler','--strict','--noEmitOnError','--skipLibCheck','--pretty','false']);
    for (const filename of [stem + '.js',path.join(output,'words' + bits + '.js')]) {
      const application = await import(pathToFileURL(filename));
      for (const name of checks) assert.equal(application[name], true, filename + ':' + name);
      assert.equal(application.echoSigned(bits === 32 ? -7 : -7n), bits === 32 ? -7 : -7n);
      const max = bits === 32 ? 4294967295 : 18446744073709551615n;
      assert.equal(application.echoUnsigned(max), max);
    }
    for (const suffix of ['.js','.ts','.rs','.wasm']) {
      const manifest = JSON.parse(await readFile(stem + suffix + '.origins.json','utf8'));
      assert.equal(manifest.targetWordSize, bits, 'profile metadata ' + suffix);
    }
    const declaration = await readFile(stem + '.d.ts','utf8');
    assert.match(declaration,/echoUnsigned/);
  } else if (mode === 'rust') {
    const manifest = JSON.parse(await readFile(stem + '.rs.origins.json','utf8'));
    const names = new Map(manifest.symbols.map(s=>[s.semantic,s.output]));
    rustBlocks.push('mod words' + bits + ';');
    rustBlocks.push('fn check' + bits + '() {');
    for (const name of checks) {
      assert(names.has(name));
      rustBlocks.push('assert!(words' + bits + '::' + names.get(name) + '(), "' + name + '");');
    }
    rustBlocks.push('assert_eq!(words' + bits + '::' + names.get('echoSigned') + '(-7i' + bits + '), -7i' + bits + ');');
    rustBlocks.push('assert_eq!(words' + bits + '::' + names.get('echoUnsigned') + '(u' + bits + '::MAX), u' + bits + '::MAX);');
    rustBlocks.push('}');
  } else throw new Error('unknown platform harness mode ' + mode);
}
if (mode === 'rust') await writeFile(path.join(directory,'rust-checks.rs'),
  '#![forbid(unsafe_code)]\n' + rustBlocks.join('\n') +
  '\nfn main() { check32(); check64(); println!("PSCV0_PLATFORM_RUST: PASS both profiles"); }\n');
console.log('PSCV0_PLATFORM_' + mode.toUpperCase() + ': PASS ' + checks.length + ' shared probes per profile');
