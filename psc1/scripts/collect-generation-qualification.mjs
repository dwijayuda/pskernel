// Extract audited G3 identities from immutable successful CI artifacts.
// A subset is evidence only; the package builder still requires all four engines.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { readQualifiedArtifact, sha256 as sha } from './kernel435-qualified-artifact.mjs';
import { auditQualifiedCompilerGeneration } from './qualified-compiler-assets.mjs';
const request = JSON.parse(fs.readFileSync('../.github/qualification-requests/psc1-selfhost-events.json'));
assert.equal(request.schema, 'psc1-qualified-generation-evidence-request/1');
const output = { schema: 'psc1-qualified-compiler-generation-inputs/1',
  sourceClosureDigest: request.sourceClosureDigest, engines: {} };
const records = [];
for (const [engine, reference] of Object.entries(request.engines)) {
  assert.ok(['js', 'ts', 'rust', 'wasm-core'].includes(engine));
  const archive = await readQualifiedArtifact(reference, path.resolve('dist/selfhost-events', engine, 'input'));
  const directory = path.join(archive, 'generated-unified-' + engine + '-compiler');
  const q = JSON.parse(fs.readFileSync(path.join(directory, 'qualification.json')));
  assert.equal(q.status, 'passed'); assert.equal(q.mode, '--self-host');
  const manifestFile = path.join(directory, 'G3-service/artifact.json');
  const manifest = JSON.parse(fs.readFileSync(manifestFile));
  const selected = { ...reference, manifestSha256: sha(fs.readFileSync(manifestFile)),
    executableSha256: sha(fs.readFileSync(path.join(path.dirname(manifestFile), manifest.executable))) };
  const { qualification, compilerAdmissions } =
    auditQualifiedCompilerGeneration(directory, engine, selected, request.sourceClosureDigest);
  output.engines[engine] = selected;
  const row = { engine, ...selected, profile: qualification.profile,
    sourceModules: qualification.sourceModules,
    sourceClosureDigest: qualification.sourceClosureDigest,
    admissionsSha256: sha(compilerAdmissions),
    originalIrSha256: qualification.bootstrap.originalIrSha256,
    sourceSha256: qualification.bootstrap.sourceSha256,
    selfCompileEvents: qualification.events.filter(event =>
      event.role === 'generated-compiler' && ['G2-self', 'G3-self'].includes(event.id)),
    fixedPoint: qualification.fixedPoint };
  records.push(row); console.log('PSC1_AUDITED_GENERATION: ' + JSON.stringify(row));
}
fs.mkdirSync('dist/selfhost-events', { recursive: true });
fs.writeFileSync('dist/selfhost-events/qualified-inputs.json', JSON.stringify(output, null, 2) + '\n');
fs.writeFileSync('dist/selfhost-events/qualification.json', JSON.stringify({
  schema: 'psc1-qualified-generation-evidence/1', observedAt: new Date().toISOString(),
  testedCommit: process.env.GITHUB_SHA, records,
  allFourEngines: Object.keys(output.engines).sort().join(',') === 'js,rust,ts,wasm-core',
  npmQualification: 'not-run',
}, null, 2) + '\n');
