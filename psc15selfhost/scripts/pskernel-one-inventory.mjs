import {execFileSync} from 'node:child_process';
import {writeFileSync} from 'node:fs';
import {gzipSync} from 'node:zlib';

// Run from the repository root after fetching advertised branch tips.
const git = (...args) => execFileSync('git', args, {encoding: 'utf8', maxBuffer: 64 * 1024 * 1024});
const tips = git('for-each-ref', '--format=%(refname:strip=3)\t%(objectname)', 'refs/remotes/origin/')
  .trim().split('\n').filter(s => !s.startsWith('HEAD\t')).map(s => {
    const [branch, commit] = s.split('\t'); return {branch, commit};
  });
const blobs = new Map();
let occurrences = 0;
const binary = [];
for (const [index, tip] of tips.entries()) {
  let count = 0;
  for (const entry of git('ls-tree', '-rz', tip.commit).split('\0')) {
    if (!entry) continue;
    const [meta, path] = entry.split('\t');
    const [mode, type, blob] = meta.split(' ');
    if (type !== 'blob' || mode === '120000') continue;
    if (/\.(pdf|docx|odt)$/i.test(path)) binary.push({tip: index, path, blob});
    if (!/\.(md|markdown|rst|adoc|txt|org)$/i.test(path) && !/(^|\/)(README|LICENSE|NOTICE|COPYING|CHANGELOG|CONTRIBUTING)$/i.test(path)) continue;
    count++; occurrences++;
    const record = blobs.get(blob) ?? {blob, paths: {}, review: 'inventoried-and-mechanically-searched'};
    (record.paths[path] ??= []).push(index);
    blobs.set(blob, record);
  }
  tip.documentOccurrences = count;
}
let bytes = 0;
for (const record of blobs.values()) {
  const content = git('cat-file', 'blob', record.blob);
  record.bytes = Buffer.byteLength(content); bytes += record.bytes;
  record.topics = ['kernel', 'bootstrap', 'self.host', 'PSC1', 'admission', 'Lean'].filter(term => new RegExp(term, 'i').test(content));
}
const result = {schema: 'pskernel-one-branch-docs/1', fetchedAt: new Date().toISOString(),
  scope: 'Fetched branch tips only; filename-based text inventory, blob deduplication, mechanical topic search. No claim of close reading.',
  summary: {branches: tips.length, occurrences, uniqueBlobs: blobs.size, bytes, binaryNotRead: binary.length},
  tips, documents: [...blobs.values()], binaryNotRead: binary};
writeFileSync('psc15selfhost/docs/pskernel-one/branch-docs.json.gz', gzipSync(JSON.stringify(result) + '\n'));
console.log(JSON.stringify(result.summary));
