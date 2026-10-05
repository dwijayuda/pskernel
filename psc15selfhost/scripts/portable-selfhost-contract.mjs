import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  checkPortableSelfhostProfile,
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

  return {
    profile: profileResult.profile,
    packages: profileResult.packages,
    moduleCount: profileResult.moduleCount,
    targetCount: targets.length,
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
      '; closureModules=' +
      result.moduleCount +
      ')\n',
  );
}
