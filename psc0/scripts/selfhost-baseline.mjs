import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, '../..');
export const baseline = Object.freeze(JSON.parse(readFileSync(
  new URL('../docs/continuity/PSC0_SOURCE_TREE_BASELINE.json', import.meta.url), 'utf8',
)));

export function classifyPortablePackageTrees(actual, expected = baseline.portablePackageTrees) {
  const changed = [];
  for (const [name, sha] of Object.entries(expected)) {
    if (actual[name] !== sha) changed.push(name);
  }
  return Object.freeze({ unchanged: changed.length === 0, changed });
}

function runGit(args) {
  const run = spawnSync('git', args, { cwd: repoRoot, encoding: 'utf8', windowsHide: true });
  if (run.error || run.status !== 0) {
    throw new Error('PSC0_BASELINE_GIT_FAILED: ' + args.join(' ') + ': ' +
      String(run.error?.message ?? run.stderr?.trim() ?? run.status));
  }
  return run.stdout.trim();
}

export function readPortablePackageTrees() {
  const actual = {};
  const paths = Object.keys(baseline.portablePackageTrees).map(name => 'psc0/packages/' + name);
  for (const name of Object.keys(baseline.portablePackageTrees)) {
    actual[name] = runGit(['rev-parse', 'HEAD:psc0/packages/' + name]);
  }
  // The recorded Git trees are about committed contents, not dirty worktree files.
  const dirty = spawnSync('git', ['diff', '--quiet', 'HEAD', '--', ...paths], {
    cwd: repoRoot, encoding: 'utf8', windowsHide: true,
  });
  if (dirty.error || (dirty.status !== 0 && dirty.status !== 1)) {
    throw new Error('PSC0_BASELINE_DIRTY_CHECK_FAILED');
  }
  const untracked = runGit(['ls-files', '--others', '--exclude-standard', '--', ...paths]);
  return Object.freeze({ actual, dirty: dirty.status === 1 || untracked.length > 0 });
}

export function baselineStatus() {
  const { actual, dirty } = readPortablePackageTrees();
  const comparison = classifyPortablePackageTrees(actual);
  return Object.freeze({ ...comparison, dirty, fastEligible: comparison.unchanged && !dirty,
    sourceCount: baseline.sourceCount, baselineCommit: baseline.authorityCommit });
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const argv = process.argv.slice(2);
  if (argv.some(arg => !['--assert-unchanged', '--json'].includes(arg))) {
    throw new Error('usage: selfhost-baseline.mjs [--assert-unchanged] [--json]');
  }
  const state = baselineStatus();
  if (argv.includes('--json')) console.log(JSON.stringify(state));
  else console.log('PSC0_PORTABLE_BASELINE: ' + (state.fastEligible ? 'UNCHANGED' : 'CHANGED') +
    ' (modules=' + state.sourceCount + '; changed=' + state.changed.join(',') + '; dirty=' + state.dirty + ')');
  if (argv.includes('--assert-unchanged') && !state.fastEligible) {
    throw new Error('PSC0_FAST_SELFHOST_REQUIRES_IMMUTABLE_BASELINE: perform full rebuild and fixed-point check for any changed portable package');
  }
}
