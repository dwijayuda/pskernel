import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';

export function parsePeakRss(text) {
  const match = /^PSKERNEL_PEAK_RSS_KIB=(\d+)\s*$/.exec(text);
  assert.ok(match, 'Missing/invalid native peak RSS');
  const value = Number(match[1]);
  assert.ok(Number.isSafeInteger(value) && value > 0, 'Invalid native peak RSS');
  return value;
}
// GNU timeout terminates the whole child process group. The outer timeout is
// only a guard for the measurement wrapper; time records the executable's RSS.
export function runMeasuredNative(binary, args, log) {
  assert.equal(process.platform, 'linux', 'Native memory measurement requires Linux');
  const rssFile = `${log}.rss`;
  const result = spawnSync('/usr/bin/timeout', ['--kill-after=2s', '30s',
    '/usr/bin/time', '-f', 'PSKERNEL_PEAK_RSS_KIB=%M', '-o', rssFile, binary, ...args],
  { encoding: 'utf8', timeout: 35_000, maxBuffer: 4 * 1024 * 1024, windowsHide: true });
  writeFileSync(log, (result.stdout ?? '') + (result.stderr ?? ''));
  if (result.error || result.status !== 0) throw Error(`Native sample failed: ${result.error ?? result.status}; ${log}`);
  return { stdout: result.stdout, peakRssKiB: parsePeakRss(readFileSync(rssFile, 'utf8')) };
}
