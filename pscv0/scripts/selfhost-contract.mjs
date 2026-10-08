import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import {
  checkSelfhostProfile,
  selfhostRoot,
} from './selfhost-profile.mjs';

const nativeSuffix = process.platform === 'win32' ? '.exe' : '';

function resolvePsc() {
  const explicit = process.env.PSC_SELFHOST_CONTRACT_PSC;
  if (explicit) {
    const resolved = path.resolve(explicit);
    if (!existsSync(resolved)) {
      throw new Error(`PSC2_SELFHOST_CONTRACT_PSC_MISSING: ${resolved}`);
    }
    return resolved;
  }
  for (const name of ['psc', 'psc1']) {
    const candidate = path.join(selfhostRoot, '.lake', 'build', 'bin', name + nativeSuffix);
    if (existsSync(candidate)) return candidate;
  }
  throw new Error(
    'PSC2_SELFHOST_CONTRACT_PSC_MISSING: run lake build psc (or lake build psc1) first',
  );
}

function runPsc(psc, args, options = {}) {
  const result = spawnSync(psc, args, {
    cwd: selfhostRoot,
    encoding: 'utf8',
    windowsHide: true,
    maxBuffer: 64 * 1024 * 1024,
    timeout: 180000,
    ...options,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(
      [
        `PSC2_SELFHOST_CONTRACT_COMMAND_FAILED: ${args.join(' ')}`,
        result.stdout,
        result.stderr,
      ].filter(Boolean).join('\n'),
    );
  }
  return result.stdout;
}

function translatedRelativePath(sourcePath) {
  const relative = path.relative(selfhostRoot, sourcePath);
  if (relative.startsWith('..') || path.isAbsolute(relative)) {
    throw new Error(`PSC2_SELFHOST_CONTRACT_SOURCE_OUTSIDE_ROOT: ${sourcePath}`);
  }
  if (!relative.endsWith('.lean')) {
    throw new Error(`PSC2_SELFHOST_CONTRACT_SOURCE_KIND: ${relative}`);
  }
  return relative.replace(/\.lean$/u, '.ps').split(path.sep).join('/');
}

function sha256(text) {
  return createHash('sha256').update(text, 'utf8').digest('hex');
}

async function translate(psc, input, target, output) {
  await mkdir(path.dirname(output), { recursive: true });
  runPsc(psc, ['translate', input, '--to', target, '--out', output]);
}

export async function checkSelfhostContract() {
  const { profile, closure } = await checkSelfhostProfile();
  const psc = resolvePsc();

  // Gate 1: the authoritative Lean-compatible compiler closure itself must check.
  runPsc(psc, ['check', closure.entry]);

  const scratch = await mkdtemp(path.join(tmpdir(), 'psc2-selfhost-contract-'));
  try {
    const canonicalRoot = path.join(scratch, 'canonical');
    const psRoundRoot = path.join(scratch, 'ps-roundtrip');
    await mkdir(path.join(canonicalRoot, 'packages'), { recursive: true });

    const generated = [];
    for (const item of closure.ordered) {
      const relativePs = translatedRelativePath(item.path);
      const canonicalPs = path.join(canonicalRoot, ...relativePs.split('/'));
      const roundPs = path.join(psRoundRoot, ...relativePs.split('/'));

      await translate(psc, item.path, 'ps', canonicalPs);
      await translate(psc, canonicalPs, 'ps', roundPs);

      const [left, right] = await Promise.all([
        readFile(canonicalPs, 'utf8'),
        readFile(roundPs, 'utf8'),
      ]);
      if (left !== right) {
        throw new Error(`PSC2_SELFHOST_CONTRACT_CANONICAL_ROUNDTRIP_MISMATCH: ${relativePs}`);
      }
      generated.push(relativePs);
    }

    // The project loader uses this marker to identify the generated PSC workspace.
    await writeFile(
      path.join(canonicalRoot, '.proofscript-bootstrap.json'),
      JSON.stringify({
        schemaVersion: 1,
        kind: 'psc2-selfhost-contract-workspace',
        profile: profile.profile,
        entry: translatedRelativePath(closure.entry),
        sourceCount: generated.length,
        generated: [...generated].sort(),
      }, null, 2) + '\n',
      'utf8',
    );

    const generatedEntry = path.join(
      canonicalRoot,
      ...translatedRelativePath(closure.entry).split('/'),
    );

    // Gate 2: the canonical PSC form of the entire closure must independently check.
    runPsc(psc, ['check', generatedEntry]);

    // Gate 3: both source representations must produce exactly the same kernel input.
    const leanAdmissions = runPsc(psc, ['admissions', closure.entry]);
    const psAdmissions = runPsc(psc, ['admissions', generatedEntry]);
    if (leanAdmissions !== psAdmissions) {
      throw new Error('PSC2_SELFHOST_CONTRACT_ADMISSIONS_PARITY');
    }

    // Gate 4: both source representations must produce exactly the same TS backend text.
    const leanTypeScript = runPsc(psc, ['typescript', closure.entry]);
    const psTypeScript = runPsc(psc, ['typescript', generatedEntry]);
    if (leanTypeScript !== psTypeScript) {
      throw new Error('PSC2_SELFHOST_CONTRACT_TYPESCRIPT_PARITY');
    }

    return {
      profile: profile.profile,
      modules: closure.ordered.length,
      admissionsSha256: sha256(leanAdmissions),
      typeScriptSha256: sha256(leanTypeScript),
      psc,
    };
  } finally {
    await rm(scratch, { recursive: true, force: true });
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const result = await checkSelfhostContract();
  process.stdout.write(
    [
      'PSC2_SELFHOST_CONTRACT: PASS',
      `profile=${result.profile}`,
      `modules=${result.modules}`,
      `admissions.sha256=${result.admissionsSha256}`,
      `typescript.sha256=${result.typeScriptSha256}`,
      `psc=${result.psc}`,
    ].join('\n') + '\n',
  );
}
