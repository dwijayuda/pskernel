import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = relative => JSON.parse(fs.readFileSync(path.join(root, relative), 'utf8'));
function requireCondition(value, message) { if (!value) throw new Error(message); }
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const files = read('FILE_SHA256.json');
for (const entry of files.files) {
  const full = path.resolve(root, entry.path);
  requireCondition(full.startsWith(root + path.sep), 'Unsafe manifest path: ' + entry.path);
  requireCondition(fs.existsSync(full), 'Missing artifact: ' + entry.path);
  const bytes = fs.readFileSync(full);
  requireCondition(bytes.length === entry.bytes && sha(bytes) === entry.sha256, 'Integrity mismatch: ' + entry.path);
  requireCondition(!/\.(ttf|otf|woff2?)$/i.test(entry.path), 'Font file must not be redistributed: ' + entry.path);
}
const manifest = read('MANIFEST.json');
const coverage = read('research/COVERAGE.json');
requireCondition(coverage.pages.length === 222, 'Coverage path count');
requireCondition(coverage.pages.filter(p => p.output).length === 218, 'Article count');
requireCondition(coverage.pages.filter(p => !p.output).length === 4, 'Placeholder count');
for (const page of coverage.pages) if (page.output) requireCondition(fs.existsSync(path.join(root,page.output)), 'Missing covered article');
requireCondition(read('research/API_INVENTORY.json').length === 3661, 'Reference-entry count');
const edits = read('research/PRESENTATION_EDITS.json');
requireCondition(edits.length === 369, 'Presentation block count');
for (const item of edits) {
  requireCondition(sha(Buffer.from(item.originalText)) === item.originalSha256, 'Original example hash');
  requireCondition(sha(Buffer.from(item.candidateText)) === item.candidateSha256, 'Candidate example hash');
  let rebuilt = item.originalText;
  for (const edit of item.edits.slice().reverse()) rebuilt = rebuilt.slice(0,edit.start) + edit.replacement + rebuilt.slice(edit.end);
  requireCondition(rebuilt === item.candidateText, 'Presentation reconstruction');
  let offset = 0;
  const shifted = item.edits.map(edit => {
    const out = {...edit,start:edit.start+offset,end:edit.start+offset+edit.replacement.length};
    offset += edit.replacement.length - (edit.end-edit.start);
    return out;
  });
  for (const edit of shifted.reverse()) rebuilt = rebuilt.slice(0,edit.start) + edit.old + rebuilt.slice(edit.end);
  requireCondition(rebuilt === item.originalText, 'Presentation inverse');
}
const tests = read('research/NATIVE_TEST_RESULTS.json');
requireCondition(tests.results.length === 7, 'Native fixture count');
for (const result of tests.results) {
  requireCondition((result.status === 0) === result.expectedAccept, 'Historical native expectation: ' + result.name);
  requireCondition(sha(fs.readFileSync(path.join(root,'examples',result.name+'.lean'))) === result.sourceSha256, 'Native fixture identity');
}
const nav = read('research/LINK_AUDIT.json');
requireCondition(nav.missingFiles.length === 0 && nav.missingFragments.length === 0, 'Recorded navigation audit must pass');
requireCondition(manifest.grammarRevision === 'ps-0.9-r2', 'Grammar identity');
requireCondition(manifest.evidence.productionProofScriptParserExecuted === false, 'Do not promote evidence');
console.log(JSON.stringify({status:'passed',filesChecked:files.files.length,htmlPaths:222,articles:218,presentationBlocks:edits.length,nativeRecordedExpectations:tests.results.length,scope:'Artifact integrity and collection consistency only. Does not execute PSC, prove semantic preservation, or rerun native tests.'},null,2));
