import { spawnSync } from 'node:child_process';
import { unlinkSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  checkPortableSelfhostProfile,
  collectPortableSelfhostEntryRoots,
  collectPortableSelfhostPackages,
  readPortableSelfhostProfile,
} from './portable-selfhost-profile.mjs';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const workspaceRoot = path.resolve(scriptDir, '..');

function sourcePathForDisplay(sourcePath) {
  return path.relative(workspaceRoot, sourcePath).split(path.sep).join('/');
}

export async function checkPortableSelfhostContract(packageFilter) {
  const profileResult = await checkPortableSelfhostProfile(packageFilter);
  const profile = await readPortableSelfhostProfile();
  const packages = await collectPortableSelfhostPackages(profile, packageFilter);

  if (profile.executableContract?.pscCheckSourceRoots !== true) {
    throw new Error('PSC1_PORTABLE_SELFHOST_EXECUTABLE_CONTRACT_DISABLED');
  }

  if (profile.executableContract?.pscTypeScriptEntryRoots !== true) {
    throw new Error('PSC1_PORTABLE_SELFHOST_EMISSION_CONTRACT_DISABLED');
  }
  if (profile.executableContract?.pscProofScriptEntryRoots !== true) {
    throw new Error('PSC1_PORTABLE_SELFHOST_PS_EMISSION_CONTRACT_DISABLED');
  }

  const targetMap = new Map();
  for (const pkg of packages) {
    for (const sourcePath of pkg.roots) {
      const displayPath = sourcePathForDisplay(sourcePath);
      targetMap.set(displayPath, sourcePath);
    }
  }

  const targets = [...targetMap.entries()]
    .sort(([left], [right]) => left.localeCompare(right));

  if (targets.length === 0) {
    throw new Error('PSC1_PORTABLE_SELFHOST_CONTRACT_NO_TARGETS');
  }

  for (const [displayPath] of targets) {
    process.stdout.write(
      'PSC1_PORTABLE_SELFHOST_CHECK: ' + displayPath + '\n',
    );
    const result = spawnSync(
      'lake',
      ['exe', 'psc1', 'check', displayPath],
      {
        cwd: workspaceRoot,
        env: process.env,
        stdio: 'inherit',
      },
    );
    if (result.error) {
      throw new Error(
        'PSC1_PORTABLE_SELFHOST_CHECK_EXEC_FAILED: ' +
          displayPath +
          ': ' +
          result.error.message,
      );
    }
    if (result.status !== 0) {
      throw new Error(
        'PSC1_PORTABLE_SELFHOST_CHECK_FAILED: ' +
          displayPath +
          ': exit=' +
          String(result.status),
      );
    }
  }

  const emissionTargetMap = new Map();
  for (const pkg of packages) {
    const entries = await collectPortableSelfhostEntryRoots(
      pkg,
      profile.includeImportClosure === true,
    );
    for (const sourcePath of entries) {
      const displayPath = sourcePathForDisplay(sourcePath);
      emissionTargetMap.set(displayPath, sourcePath);
    }
  }

  const emissionTargets = [...emissionTargetMap.entries()]
    .sort(([left], [right]) => left.localeCompare(right));

  if (emissionTargets.length === 0) {
    throw new Error('PSC1_PORTABLE_SELFHOST_EMISSION_NO_TARGETS');
  }

  for (const [displayPath, sourcePath] of emissionTargets) {
    process.stdout.write(
      'PSC1_PORTABLE_SELFHOST_EMIT: ' + displayPath + '\n',
    );
    const result = spawnSync(
      'lake',
      ['exe', 'psc1', 'typescript', displayPath],
      {
        cwd: workspaceRoot,
        env: process.env,
        encoding: 'utf8',
        maxBuffer: 64 * 1024 * 1024,
      },
    );
    if (result.error) {
      throw new Error(
        'PSC1_PORTABLE_SELFHOST_EMIT_EXEC_FAILED: ' +
          displayPath +
          ': ' +
          result.error.message,
      );
    }
    if (result.status !== 0) {
      if (result.stdout) process.stderr.write(result.stdout);
      if (result.stderr) process.stderr.write(result.stderr);
      throw new Error(
        'PSC1_PORTABLE_SELFHOST_EMIT_FAILED: ' +
          displayPath +
          ': exit=' +
          String(result.status),
      );
    }
    if (typeof result.stdout !== 'string' || result.stdout.length === 0) {
      throw new Error(
        'PSC1_PORTABLE_SELFHOST_EMIT_EMPTY: ' + displayPath,
      );
    }

    process.stdout.write(
      'PSC1_PORTABLE_SELFHOST_EMIT_PS: ' + displayPath + '\n',
    );
    const psEmission = spawnSync(
      'lake',
      ['exe', 'psc1', 'emit-ps', displayPath],
      {
        cwd: workspaceRoot,
        env: process.env,
        encoding: 'utf8',
        maxBuffer: 64 * 1024 * 1024,
      },
    );
    if (psEmission.error) {
      throw new Error(
        'PSC1_PORTABLE_SELFHOST_EMIT_PS_EXEC_FAILED: ' +
          displayPath +
          ': ' +
          psEmission.error.message,
      );
    }
    if (psEmission.status !== 0) {
      if (psEmission.stdout) process.stderr.write(psEmission.stdout);
      if (psEmission.stderr) process.stderr.write(psEmission.stderr);
      throw new Error(
        'PSC1_PORTABLE_SELFHOST_EMIT_PS_FAILED: ' +
          displayPath +
          ': exit=' +
          String(psEmission.status),
      );
    }
    if (
      typeof psEmission.stdout !== 'string' ||
      psEmission.stdout.length === 0
    ) {
      throw new Error(
        'PSC1_PORTABLE_SELFHOST_EMIT_PS_EMPTY: ' + displayPath,
      );
    }

    const generatedPath = sourcePath + '.portable-selfhost.generated.ps';
    const generatedDisplay = sourcePathForDisplay(generatedPath);
    writeFileSync(generatedPath, psEmission.stdout, 'utf8');
    try {
      const psCheck = spawnSync(
        'lake',
        ['exe', 'psc1', 'check', generatedDisplay],
        {
          cwd: workspaceRoot,
          env: process.env,
          stdio: 'inherit',
        },
      );
      if (psCheck.error) {
        throw new Error(
          'PSC1_PORTABLE_SELFHOST_PS_CHECK_EXEC_FAILED: ' +
            displayPath +
            ': ' +
            psCheck.error.message,
        );
      }
      if (psCheck.status !== 0) {
        throw new Error(
          'PSC1_PORTABLE_SELFHOST_PS_CHECK_FAILED: ' +
            displayPath +
            ': exit=' +
            String(psCheck.status),
        );
      }

      const psCanonical = spawnSync(
        'lake',
        ['exe', 'psc1', 'emit-ps', generatedDisplay],
        {
          cwd: workspaceRoot,
          env: process.env,
          encoding: 'utf8',
          maxBuffer: 64 * 1024 * 1024,
        },
      );
      if (psCanonical.error || psCanonical.status !== 0) {
        throw new Error(
          'PSC1_PORTABLE_SELFHOST_PS_CANONICAL_FAILED: ' + displayPath,
        );
      }
      if (psCanonical.stdout !== psEmission.stdout) {
        throw new Error(
          'PSC1_PORTABLE_SELFHOST_PS_FIXED_POINT_MISMATCH: ' + displayPath,
        );
      }

      const psTypeScript = spawnSync(
        'lake',
        ['exe', 'psc1', 'typescript', generatedDisplay],
        {
          cwd: workspaceRoot,
          env: process.env,
          encoding: 'utf8',
          maxBuffer: 64 * 1024 * 1024,
        },
      );
      if (psTypeScript.error || psTypeScript.status !== 0) {
        throw new Error(
          'PSC1_PORTABLE_SELFHOST_PS_TYPESCRIPT_FAILED: ' + displayPath +
          ': exit=' + String(psTypeScript.status) +
          '; signal=' + String(psTypeScript.signal) +
          '; ' + (psTypeScript.error?.message ?? '') + '\n' +
          (psTypeScript.stderr ?? '').slice(-5000) + '\n' +
          (psTypeScript.stdout ?? '').slice(-2000),
        );
      }
      if (psTypeScript.stdout !== result.stdout) {
        throw new Error(
          'PSC1_PORTABLE_SELFHOST_PS_TYPESCRIPT_PARITY: ' + displayPath,
        );
      }
    } finally {
      unlinkSync(generatedPath);
    }
  }

  return {
    profile: profileResult.profile,
    packages: profileResult.packages,
    moduleCount: profileResult.moduleCount,
    targetCount: targets.length,
    emissionTargetCount: emissionTargets.length,
    proofScriptEmissionTargetCount: emissionTargets.length,
  };
}

if (
  process.argv[1] &&
  path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
) {
  const packageIndex = process.argv.indexOf('--package');
  const packageFilter =
    packageIndex >= 0 ? process.argv[packageIndex + 1] : undefined;
  const result = await checkPortableSelfhostContract(packageFilter);
  process.stdout.write(
    'PSC1_PORTABLE_SELFHOST_CONTRACT: PASS (' +
      result.profile.profile +
      '; packages=' +
      result.packages.join(',') +
      '; roots=' +
      result.targetCount +
      '; emitRoots=' +
      result.emissionTargetCount +
      '; closureModules=' +
      result.moduleCount +
      ')\n',
  );
}
