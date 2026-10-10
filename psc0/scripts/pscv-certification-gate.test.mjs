import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFile } from 'node:fs/promises';
import {
  pscvGateState, previewPSCVProposal, authorizePSCVExecutable,
} from './pscv-certification-gate.mjs';
import { buildChecked } from './checked-build.mjs';
import {
  requiredObligationsProtocol, verificationProposalProtocol,
  canonicalRequiredObligations,
} from '../packages/verification/src/preflight.mjs';

const h = c => c.repeat(64);
const required = {
  protocol:requiredObligationsProtocol, sourceSha256:h('1'),
  environmentSha256:h('2'), specificationSha256:h('3'),
  semanticsSha256:h('4'), assurancePolicy:'pscv-closed-v1',
  roots:['Demo.guarded'],
  obligations:[{id:'demo.post',rootId:'Demo.guarded',
    kind:'postcondition',goalSha256:h('5')}],
};
const proposal = {
  protocol:verificationProposalProtocol,
  requirementsSha256:canonicalRequiredObligations(required).requirementsSha256,
  proofCandidates:[{obligationId:'demo.post',goalSha256:h('5'),proofSha256:h('6')}],
};

test('release-owned PSCV gate advertises no certified branch or profile activation', () => {
  assert.equal(pscvGateState.verifiedExecutableSupported,false);
  assert.equal(pscvGateState.proofClosureValidated,false);
  assert.equal(pscvGateState.environmentManifestFrozen,false);
  assert(Object.isFrozen(pscvGateState));
  const preflight = previewPSCVProposal({required,proposal});
  assert.equal(preflight.status,'uncertified');
  assert.equal(preflight.verifiedExecutableAuthorized,false);
  assert.equal(preflight.pscvVerified,false);
  assert.equal(preflight.gate,pscvGateState);
  assert(Object.isFrozen(preflight));
});

test('no self-issued certificate, empty coverage or policy flag can authorize PSCV emission', () => {
  for(const candidate of [undefined,{},true,
    {verified:true,pscvVerified:true,certificate:'PSCV-CERT-v1'},
    {passed:true,obligations:[],proofs:[]},
    {profile:'pscv-v1',assurancePolicy:'pscv-boundary-v1',
      missing:[],certified:true}]) {
    assert.throws(()=>authorizePSCVExecutable(candidate),
      /PSC_PSCV_CERT_GATE_UNQUALIFIED/u);
  }
});

test('ordinary checked compiler entry cannot issue PSCV output or downgrade it', async () => {
  for (const profile of ['pscv','pscv-v1','pscv-closed-v1']) {
    await assert.rejects(buildChecked({
      profile,entryPath:'does-not-exist.ps',outputPath:'forbidden.ts',
      checkOnly:false,
    }),/PSC0_PROFILE_UNAVAILABLE/u);
  }
});

test('profile candidate is data only, private and explicit about unresolved pins', async () => {
  const packageFile = new URL('../packages/pscv/package.json', import.meta.url);
  const profileFile = new URL('../packages/pscv/profile.json', import.meta.url);
  const pkg = JSON.parse(await readFile(packageFile,'utf8'));
  const p = JSON.parse(await readFile(profileFile,'utf8'));
  assert.equal(pkg.name,'@proofscript/pscv');
  assert.equal(pkg.private,true);
  assert.equal(pkg.type,'module');
  assert.equal(pkg.main,undefined);
  assert.equal(pkg.bin,undefined);
  assert.equal(pkg.scripts,undefined);
  assert.equal(p.status,'experimental-preflight-only');
  assert.equal(p.installedPackageGrantsAuthority,false);
  assert.equal(p.allowedToEmitVerifiedExecutable,false);
  assert.equal(p.runtimeCodeEntry,null);
  assert.deepEqual(p.packageCapabilities,[]);
  assert.deepEqual(p.verifiedFeatures,[]);
  assert.equal(p.leanSemanticReference.version,'4.35.0-rc3');
  assert.equal(p.leanSemanticReference.commit,
    '470d5ce1400764999581fd26d5d72b00d990b0f4');
  assert.equal(p.standardEnvironment.registrySha256,null);
  assert.equal(p.standardEnvironment.status,'not-generated-or-frozen');
  assert.equal(p.referenceSha256,
    '4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71');
});
