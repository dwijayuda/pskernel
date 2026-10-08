import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import { validateCompilerExecutionPolicy } from './compiler-execution-policy.mjs';

const root = new URL('../', import.meta.url);
const json = async path => JSON.parse(await readFile(new URL(path, root), 'utf8'));
const policy = await json('contracts/compiler/COMPILER_EXECUTION_POLICY_V1.json');
const context = { languageAuthority: await json('language-authority.json'),
  config: await json('psconfig.json'), toolchain: await readFile(new URL('lean-toolchain', root), 'utf8') };
const copy = value => structuredClone(value);

test('host implementation selection is independent of target PSCV semantics and grants no authority', () => {
  const result = validateCompilerExecutionPolicy(policy, context);
  assert.equal(result.selfHostingRequired, false);
  assert.equal(result.verifiedExecutableAuthority, false);
  assert.equal(result.sourceLanguage, 'PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md');
  assert.notEqual(policy.hostToolchain.commit, policy.languageAuthority.normativeLeanCommit);
});

test('changing host constraints cannot promote incomplete implementation or weaken PSCV identities', () => {
  for (const change of [
    value => { value.conformance.pscvLanguageConformant = true; },
    value => { value.conformance.globalPreservationProved = true; },
    value => { value.conformance.assuredRelease = true; },
    value => { value.languageAuthority.verificationProfile = 'psc2-language-v1'; },
    value => { value.languageAuthority.sha256 = '0'.repeat(64); },
    value => { value.languageAuthority.certificatePolicy = 'pscv-cert/1'; },
    value => { value.kernelScope = 'modify-kernel'; },
    value => { value.requiredValidation = value.requiredValidation.filter(x => x !== 'production-authority'); },
  ]) {
    const changed = copy(policy); change(changed);
    assert.throws(() => validateCompilerExecutionPolicy(changed, context), /PSCV_EXECUTION_POLICY_/);
  }
});

test('hosted implementation no longer requires self-hosting but retains exact historical profiles', () => {
  for (const change of [
    value => { value.selfHosting.requiredForImplementation = true; },
    value => { value.selfHosting.psc1PatternsRequired = true; },
    value => { value.selfHosting.historicalEvidence = 'upgrade-to-current'; },
    value => { value.hostToolchain.commit = '0'.repeat(40); },
  ]) {
    const changed = copy(policy); change(changed);
    assert.throws(() => validateCompilerExecutionPolicy(changed, context), /PSCV_EXECUTION_POLICY_/);
  }
  const changed = copy(context); changed.config.implementationProfile = 'PSC1-selfhost-stable/1';
  assert.throws(() => validateCompilerExecutionPolicy(policy, changed), /CONFIG_IMPLEMENTATION/);
});
