import { readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';

const dir = process.argv[2];
const files = readdirSync(dir).filter(x => x.endsWith('.cpuprofile'));
if (files.length !== 1) throw Error('Expected exactly one bounded profile');
const profile = JSON.parse(readFileSync(path.join(dir, files[0]), 'utf8'));
const nodes = new Map(profile.nodes.map(n => [n.id, n]));
const counts = new Map();
for (const id of profile.samples) {
  const frame = nodes.get(id).callFrame;
  const name = `${frame.functionName || '(anonymous)'} ${frame.url.split('/').at(-1)}:${frame.lineNumber + 1}`;
  counts.set(name, (counts.get(name) ?? 0) + 1);
}
console.log('CPU sample attribution for the shared-workload worker (loading, guards, warmup and measured calls; admission cases are measured in separate workers):');
for (const [name, count] of [...counts].sort((a, b) => b[1] - a[1]).slice(0, 25)) {
  console.log(`${(100 * count / profile.samples.length).toFixed(2)}% ${name}`);
}
