import assert from 'node:assert/strict';
import fs from 'node:fs';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { readOwnedCompilerSources } from '../host-tools/compiler-source-inputs.mjs';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';

const baseline = '4c977654b8ca39b5fb3568ca9ebea03eee9d4339';
const file = 'psc1/packages/syntax/src/Ps/Syntax/Lexer.lean';
const result = spawnSync('git', ['show', baseline + ':' + file], { encoding: 'utf8' });
assert.equal(result.status, 0);
const original = result.stdout, current = fs.readFileSync(file.slice(5), 'utf8');
const before = '(psLexAdvanceChar position close)', after = '(psLexAdvanceTwo position first close)';
assert.equal(original.split(before).length, 2, 'unique diagnosed branch');
const start = original.indexOf('def psLexReadCharacterBody');
const stop = original.indexOf('def psLexPairEq', start);
assert.ok(start > 0 && stop > start);
const legacy = original.slice(start, stop).replace('def psLexReadCharacterBody', 'def legacyPsLexReadCharacterBody');
const tests = fs.readFileSync('test/CharacterDiagnosticTests.lean', 'utf8');
assert.equal(tests.split(legacy).length, 2, 'proof reference matches the qualified Git object verbatim');
assert.equal(/sorry|admit|axiom|unsafe|partial def|set_option\s+(maxRecDepth|maxHeartbeats)/.test(tests), false,
  'correspondence must remain an ordinary kernel checked theorem');
if (process.argv.includes('--reference-only')) {
  console.log('PSC1_CHARACTER_REFERENCE: PASS immutable qualified leaf and axiom-free proof source');
  process.exit(0);
}
assert.equal(current, original.replace(before, after), 'only the diagnosed span calculation changes');
const sourceRows = readOwnedCompilerSources('Ps.CompilerUnified.Service');
assert.equal(sourceRows.length, 121);
const digest = compilerSourceClosureDigest(sourceRows.map(s => ({ ...s, kind: 'lean' })));
const diagnosticRow = sourceRows.find(s => s.module === 'Ps.Syntax.Lexer');
assert.ok(diagnosticRow);
const restored = sourceRows.map(s => ({ ...s, kind: 'lean',
  text: s.module === 'Ps.Syntax.Lexer' ? original : s.text }));
assert.equal(compilerSourceClosureDigest(restored),
  '7a49ccbd8b11d029e54fa0d78da9e8fe66943193cc73d00c29b4ed392126a000',
  'all other unified compiler module bytes retain their qualified identity');
const existing = spawnSync('git', ['diff', '--name-only', baseline, 'HEAD', '--',
  'packages', 'host', 'host-tools', 'npm-cli', 'lean-toolchain',
  'scripts/bounded-process.py', 'scripts/selfhost-qualification-profiles.mjs',
  'scripts/slim-universal-input.json', 'scripts/slim-universal-package.mjs'], { encoding: 'utf8' });
assert.equal(existing.status, 0);
assert.deepEqual(existing.stdout.trim().split('\n').filter(Boolean),
  [file], 'no other production, frozen package or resource-policy input changes');
const receipt = {
  schema: 'psc1-character-diagnostic-correspondence/1',
  implementation: process.env.GITHUB_SHA ?? null, baseline, productionChange: file,
  sourceModules: 121, sourceClosureSha256: digest,
  baselineClosureSha256: '7a49ccbd8b11d029e54fa0d78da9e8fe66943193cc73d00c29b4ed392126a000',
  baselineLeafSha256: crypto.createHash('sha256').update(legacy).digest('hex'),
  scopedTheorems: ['characterDiagnostic_preserves_observation', 'characterDiagnostic_uses_actual_prefix'],
  theoremScope: 'character lexer leaf only; all input/cursor states; success fields and error constructor/reason',
  wholeCompilerFormalPreservation: false, newFrozenSelfHostQualification: false,
};
fs.mkdirSync('dist/character-diagnostics', { recursive: true });
fs.writeFileSync('dist/character-diagnostics/correspondence.json', JSON.stringify(receipt, null, 2) + '\n');
console.log('PSC1_CHARACTER_CORRESPONDENCE: PASS ' + JSON.stringify(receipt));
