import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const pkg = path.join(root, 'packages/pskernel-one');
const out = path.join(root, 'dist/pskernel-one');
const hash = text => crypto.createHash('sha256').update(text).digest('hex');
const modules = ['Data', 'Name', 'Level'].map(n => `src/Ps/KernelOne/${n}.lean`).concat('src/Ps/KernelOne.lean');
const snapshot = modules.map(file => {
  const absolute = path.join(pkg, file);
  if (fs.realpathSync(absolute) !== absolute || !fs.lstatSync(absolute).isFile()) throw new Error(`SOURCE_ESCAPE: ${file}`);
  const source = fs.readFileSync(absolute, 'utf8');
  const imports = source.split('\n').filter(line => /^\s*import\b/.test(line));
  const allowed = new Set(modules.map(p => p.slice(4, -5).replaceAll('/', '.')));
  for (const line of imports) {
    const match = line.match(/^import (Ps\.KernelOne(?:\.[A-Za-z]+)?)$/);
    if (!match || !allowed.has(match[1])) throw new Error(`EXTERNAL_IMPORT: ${file}: ${line}`);
    const dependency = `src/${match[1].replaceAll('.', '/')}.lean`;
    if (modules.indexOf(dependency) >= modules.indexOf(file)) throw new Error(`SOURCE_ORDER: ${file}`);
  }
  // Secondary source guard only: the real frontend remains the source gate.
  if (/\b(unsafe|partial|axiom|sorry|implemented_by|extern|IO|Lean|Std)\b/.test(source)) throw new Error(`SOURCE_PROFILE: ${file}`);
  return {path: file, source, bytes: Buffer.byteLength(source), sha256: hash(source), imports};
});
const identity = {schema: 'pskernel-one-source/1', profile: 'level-slice-v1',
  files: snapshot.map(({source, ...rest}) => rest)};
const manifest = path.join(pkg, 'SOURCE_MANIFEST.json');
if (process.argv.includes('--write-manifest')) {
  fs.writeFileSync(manifest, JSON.stringify(identity, null, 2) + '\n');
  console.log(`PSKERNEL_ONE_MANIFEST: ${snapshot.length} files`);
  process.exit(0);
}
if (JSON.stringify(JSON.parse(fs.readFileSync(manifest, 'utf8'))) !== JSON.stringify(identity)) throw new Error('SOURCE_MANIFEST_MISMATCH');
fs.mkdirSync(out, {recursive: true});
const flat = snapshot.map(s => s.source.split('\n').filter(line => !/^import /.test(line)).join('\n')).join('\n');
const input = path.join(out, 'KernelOne.lean');
fs.writeFileSync(input, flat);
const executable = process.env.PSC1 ?? path.join(root, '.lake/build/bin/psc1');
const commandResults = [];
function run(args) {
  const result = spawnSync(executable, args, {cwd: root, encoding: 'utf8', timeout: 120000, maxBuffer: 32 * 1024 * 1024});
  commandResults.push({args, status: result.status, signal: result.signal, error: result.error?.message,
    stdout: result.stdout, stderr: result.stderr});
  fs.writeFileSync(path.join(out, 'profile-results.json'), JSON.stringify({identity,
    inputSha256: hash(flat), compilerSha256: hash(fs.readFileSync(executable)), commandResults}, null, 2) + '\n');
  if (result.status !== 0) {
    process.stderr.write(result.stderr ?? '');
    throw new Error(`PSC_COMMAND_FAILED: ${args[0]} (${result.status ?? result.signal})`);
  }
  return result.stdout;
}
process.stdout.write(run(['check', input]));
const canonical = path.join(out, 'KernelOne.ps');
run(['translate', input, '--to', 'ps', '--out', canonical]);
process.stdout.write(run(['check', canonical]));
console.log(`PSKERNEL_ONE_SOURCE: PASS (${snapshot.length} modules; Lean and canonical PS frontend)`);
if (process.argv.includes('--emit')) {
  const target = path.join(out, 'KernelOne.ts');
  if (fs.existsSync(target)) fs.unlinkSync(target);
  fs.writeFileSync(target, run(['typescript', canonical]));
  console.log('PSKERNEL_ONE_EMIT: PASS (tsc and execution are separate gates)');
}
