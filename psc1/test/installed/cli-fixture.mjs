// Actual npm consumers of the assembled tarballs; no checking or compilation mocks.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
export function fixture({consumers = false} = {}) {
  const distribution = path.resolve('dist/slim-universal');
  const assembly = JSON.parse(fs.readFileSync(path.join(distribution, 'package-receipt.json')));
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-watch-runtime-'));
  const runtime = process.env.PSC1_TEST_RUNTIME || process.execPath;
  const bun = path.basename(runtime).startsWith('bun');
  const flags = bun ? ['--no-install', '--no-macros', '--no-env-file'] : [];
  const env = {...process.env, PATH: [...new Set([path.dirname(runtime), path.dirname(process.execPath)])].join(path.delimiter)};
  for (const key of Object.keys(env))
    if (key === 'NODE_OPTIONS' || key.startsWith('PSC1_') || key.startsWith('LEAN') ||
        key.startsWith('ELAN') || key.startsWith('LD_') || key.startsWith('DYLD_'))
      delete env[key];
  const run = (executable, args, cwd = directory) => {
    const r = spawnSync(executable, args, {cwd, env, encoding: 'utf8', timeout: 240000, maxBuffer: 32 * 1024 * 1024});
    assert.equal(r.error, undefined, String(r.error)); return r;
  };
  const ok = (executable, args, cwd) => {
    const r = run(executable, args, cwd); assert.equal(r.status, 0, r.stdout + r.stderr); return r.stdout;
  };
  fs.writeFileSync(path.join(directory, 'package.json'), '{"private":true,"type":"module"}');
  const tarballs = path.join(distribution, 'tarballs');
  const npm = path.resolve(path.dirname(process.execPath), '../lib/node_modules/npm/bin/npm-cli.js');
  const install = tars => ok(process.execPath, [npm, 'install', '--offline', '--registry', 'http://127.0.0.1:9',
    '--ignore-scripts', '--no-audit', '--no-fund', '--cache', path.join(directory, 'empty-cache'),
    ...tars.map(t => path.join(tarballs, t))]);
  install([assembly.tarball]);
  const root = path.join(directory, 'node_modules/proofscript');
  const manifest = JSON.parse(fs.readFileSync(path.join(root, 'UNIVERSAL_DISTRIBUTION.json')));
  const meta = JSON.parse(fs.readFileSync(path.join(root, 'package.json')));
  assert.equal(meta.engines.node, '>=22.0.0');
  const engines = assembly.input.packages;
  const extras = ['rust', 'wasm-core'].map(k => engines[k].tarball);
  if (consumers) {
    extras.push(manifest.targetConsumers.ts.tarball, manifest.targetConsumers.rust.tarball);
    extras.push(...manifest.targetConsumers.ts.dependencies.map(p => p.tarball));
  }
  install(extras);
  const cli = path.join(root, 'npm-cli/proofscript-cli.mjs');
  const call = (args, cwd) => run(runtime, [...flags, cli, ...args], cwd);
  const invoke = (args, cwd) => ok(runtime, [...flags, cli, ...args], cwd);
  const observe = receipt => ok(runtime, [...flags, '--input-type=module', '-e',
    'let m=await import(' + JSON.stringify(pathToFileURL(receipt.runtimeArtifact || receipt.artifact).href) +
    ');if(m.default)m=m.default;console.log(String(m.answer));']).trim();
  return {directory, runtime, flags, env, cli, root, assembly, manifest, run, ok, call, invoke, observe};
}
