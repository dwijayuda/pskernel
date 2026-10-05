import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { root, sha256, json, readSources } from './source.mjs';
const { manifest, flat } = readSources();
const pin = json(path.join(root, 'manifests/TOOLCHAIN.json'));
if (!process.env.PSC1) throw Error('PSC1_REQUIRED: set an explicit pinned seed executable; no fallback/download');
const seed = fs.realpathSync(process.env.PSC1);
if (sha256(fs.readFileSync(seed)) !== pin.psc1Sha256) throw Error('PSC1_DIGEST_MISMATCH');
const tsc = process.env.TSC || 'tsc';
const run = (exe, args) => execFileSync(exe, args, { encoding: 'utf8', timeout: 60000, maxBuffer: 16 * 1024 * 1024 });
// An explicit installed JS CLI also works on Windows without a shell shim.
const runTsc = args => /\.[cm]?js$/u.test(tsc) ? run(process.execPath, [tsc, ...args]) : run(tsc, args);
const tscVersion = runTsc(['--version']).trim();
if (tscVersion !== `Version ${pin.typescriptVersion}`) throw Error('TYPESCRIPT_VERSION_MISMATCH');
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'pskernel-core-build-'));
try {
  const lean = path.join(temporary, 'foundation.lean'), ps = path.join(temporary, 'foundation.ps');
  fs.writeFileSync(lean, flat);
  const leanCheck = run(seed, ['check', lean]).trim();
  run(seed, ['translate', lean, '--to', 'ps', '--out', ps]);
  const psCheck = run(seed, ['check', ps]).trim();
  const leanTs = run(seed, ['typescript', lean]), psTs = run(seed, ['typescript', ps]);
  if (!leanTs.trim() || leanTs !== psTs) throw Error('CANONICAL_PS_EMISSION_MISMATCH');
  fs.writeFileSync(path.join(temporary, 'foundation.ts'), leanTs);
  const output = path.join(temporary, 'output');
  runTsc(['--strict', '--target', 'ES2022', '--module', 'ES2022', '--declaration', '--noEmitOnError', '--outDir', output, path.join(temporary, 'foundation.ts')]);
  fs.copyFileSync(ps, path.join(output, 'foundation.ps'));
  fs.copyFileSync(lean, path.join(output, 'foundation.lean'));
  fs.copyFileSync(path.join(temporary, 'foundation.ts'), path.join(output, 'foundation.ts'));
  const outputs = fs.readdirSync(output).sort().map(name => ({ path: `dist/${name}`, sha256: sha256(fs.readFileSync(path.join(output, name))) }));
  const report = { schemaVersion: 1, packageVersion: json(path.join(root, 'package.json')).version, sourceManifestSha256: sha256(fs.readFileSync(path.join(root, 'manifests/SOURCE.json'))), seedSha256: pin.psc1Sha256, seedSourceCommit: pin.seedSourceCommit, typescriptVersion: pin.typescriptVersion, nodeVersion: process.version, leanCheck, psCheck, canonicalPsEmissionParity: true, generatedOutputEdited: false, canCheckProofs: false, outputs };
  fs.rmSync(path.join(root, 'dist'), { recursive: true, force: true });
  fs.mkdirSync(path.join(root, 'dist'));
  for (const entry of outputs) fs.copyFileSync(path.join(output, path.basename(entry.path)), path.join(root, entry.path));
  fs.writeFileSync(path.join(root, 'manifests/BUILD.json'), JSON.stringify(report, null, 2) + '\n');
  console.log(JSON.stringify(report, null, 2));
} finally { fs.rmSync(temporary, { recursive: true, force: true }); }
