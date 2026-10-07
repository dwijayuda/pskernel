import { artifactId, artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { verifyEvidenceEnvelope } from './evidence-envelope.mjs';
import { verifyObservedBuildArchive } from './observed-build-archive.mjs';

export const releaseEvidenceBundleContract = 'psc-release-evidence-bundle/1';
const fail = code => { throw new Error('PSC_RELEASE_EVIDENCE_' + code); };
const same = (left,right) => artifactKey(left) === artifactKey(right);
const copy = value => JSON.parse(canonicalBytes(value));
const defaults = Object.freeze({ maxBundleBytes: 512*1024*1024, maxEnvelopeBytes: 16*1024*1024,
  maxArchiveBytes: 256*1024*1024, maxArtifacts: 4096, maxArtifactBytes: 128*1024*1024 });
function limits(values={}) {
  const result={...defaults,...values};
  if(Object.keys(result).some(key=>!Object.hasOwn(defaults,key)) ||
      Object.values(result).some(value=>!Number.isSafeInteger(value)||value<0)) fail('LIMIT_POLICY');
  return result;
}
function exact(value, fields) {
  if(!value||typeof value!=='object'||Array.isArray(value)||
      Object.keys(value).sort().join(',')!==[...fields].sort().join(',')) fail('SCHEMA');
}
function embedded(bytes, identity, maxBytes) {
  if(!(bytes instanceof Uint8Array)||bytes.byteLength>maxBytes) fail('RESOURCE_EXHAUSTED');
  verifyArtifact(bytes,identity);
  return { identity:copy(identity), data:Buffer.from(bytes).toString('base64') };
}
function decodeEmbedded(value, maxBytes) {
  exact(value,['identity','data']);
  if(typeof value.data!=='string'||value.identity.byteLength>maxBytes||
      value.data.length!==Math.ceil(value.identity.byteLength/3)*4) fail('BASE64');
  const bytes=Buffer.from(value.data,'base64');
  if(bytes.toString('base64')!==value.data) fail('BASE64');
  verifyArtifact(bytes,value.identity);
  return {identity:value.identity,bytes};
}

/** Self-contained top-level release evidence. It intentionally packages only
 * the EvidenceEnvelope and observed build archive; all graph artifacts remain
 * in the archive so there is a single byte source for offline replay.
 */
export function createReleaseEvidenceBundle({ envelope, buildArchive }, resourceLimits) {
  const bound=limits(resourceLimits);
  verifyArtifact(envelope.bytes,envelope.identity); verifyArtifact(buildArchive.bytes,buildArchive.identity);
  if(envelope.identity.domain!=='evidence-envelope'||envelope.identity.contract!=='psc-evidence-envelope/1'||
      buildArchive.identity.domain!=='observed-build-archive'||buildArchive.identity.contract!=='psc-observed-build-archive/1')
    fail('IDENTITY');
  const envelopeValue=JSON.parse(envelope.bytes);
  if(!same(envelopeValue.buildArchive,buildArchive.identity)) fail('ARCHIVE_BINDING');
  const bytes=canonicalBytes({
    schemaVersion:1,
    contract:releaseEvidenceBundleContract,
    envelope:embedded(envelope.bytes,envelope.identity,bound.maxEnvelopeBytes),
    buildArchive:embedded(buildArchive.bytes,buildArchive.identity,bound.maxArchiveBytes),
    authority:'audit-record-only',
    semanticClaimsVerified:false,
    executablePreservation:'not-established',
    releaseAccepted:false,
  },{maxBytes:bound.maxBundleBytes});
  return {bytes,identity:artifactId(bytes,'release-evidence-bundle',releaseEvidenceBundleContract)};
}

function archiveResolver(archiveBytes, archiveIdentity, bound) {
  verifyArtifact(archiveBytes,archiveIdentity);
  const archive=decodeComparatorJson(archiveBytes,{maxBytes:bound.maxArchiveBytes});
  exact(archive,['contract','graphId','artifacts']);
  if(archive.contract!=='psc-observed-build-archive/1'||!Array.isArray(archive.artifacts)||
      archive.artifacts.length>bound.maxArtifacts) fail('ARCHIVE_SCHEMA');
  const blobs=new Map();
  for(const item of archive.artifacts){
    exact(item,['identity','data']);
    if(item.identity.byteLength>bound.maxArtifactBytes||typeof item.data!=='string'||
        item.data.length!==Math.ceil(item.identity.byteLength/3)*4) fail('ARCHIVE_ARTIFACT');
    const bytes=Buffer.from(item.data,'base64');
    if(bytes.toString('base64')!==item.data) fail('ARCHIVE_ARTIFACT');
    verifyArtifact(bytes,item.identity);
    const key=artifactKey(item.identity);
    if(blobs.has(key)) fail('ARCHIVE_DUPLICATE');
    blobs.set(key,bytes);
  }
  return {graphId:archive.graphId,resolveArtifact:id=>{
    if(same(id,archiveIdentity)) return Buffer.from(archiveBytes);
    const bytes=blobs.get(artifactKey(id));
    if(!bytes) fail('MISSING_ARTIFACT');
    return bytes;
  }};
}

export async function verifyReleaseEvidenceBundle(record,{
  expectedBundleId,
  allowedAssumptions,
  requireRuntimeInterface=true,
  resourceLimits,
}={}) {
  try{
    const bound=limits(resourceLimits);
    if(!expectedBundleId||!same(record.identity,expectedBundleId)) fail('EXPECTED_ID');
    if(!(record.bytes instanceof Uint8Array)||record.bytes.byteLength>bound.maxBundleBytes) fail('RESOURCE_EXHAUSTED');
    verifyArtifact(record.bytes,record.identity);
    if(record.identity.domain!=='release-evidence-bundle'||record.identity.contract!==releaseEvidenceBundleContract) fail('IDENTITY');
    const value=decodeComparatorJson(record.bytes,{maxBytes:bound.maxBundleBytes});
    exact(value,['schemaVersion','contract','envelope','buildArchive','authority','semanticClaimsVerified','executablePreservation','releaseAccepted']);
    if(value.schemaVersion!==1||value.contract!==releaseEvidenceBundleContract||value.authority!=='audit-record-only'||
        value.semanticClaimsVerified!==false||value.executablePreservation!=='not-established'||value.releaseAccepted!==false)
      fail('SCHEMA');
    const envelope=decodeEmbedded(value.envelope,bound.maxEnvelopeBytes);
    const archive=decodeEmbedded(value.buildArchive,bound.maxArchiveBytes);
    const envelopeValue=decodeComparatorJson(envelope.bytes,{maxBytes:bound.maxEnvelopeBytes});
    if(!same(envelopeValue.buildArchive,archive.identity)) fail('ARCHIVE_BINDING');
    const opened=archiveResolver(archive.bytes,archive.identity,bound);
    if(!same(envelopeValue.buildGraph,opened.graphId)) fail('GRAPH_BINDING');
    const build=await verifyObservedBuildArchive(archive.bytes,{
      expectedGraphId:envelopeValue.buildGraph,allowedAssumptions,resourceLimits:{
        maxArchiveBytes:bound.maxArchiveBytes,maxArtifactBytes:bound.maxArtifactBytes,
      }});
    if(build.kind!=='accepted') fail('BUILD_ARCHIVE_REJECTED:'+build.reason);
    const checkedEnvelope=await verifyEvidenceEnvelope(envelope,{
      resolveArtifact:opened.resolveArtifact,requireRuntimeInterface,
    });
    if(checkedEnvelope.kind!=='accepted') fail('ENVELOPE_REJECTED');
    return Object.freeze({
      kind:'accepted',
      bundleId:copy(record.identity),
      envelopeId:copy(envelope.identity),
      buildArchiveId:copy(archive.identity),
      executableArtifact:copy(checkedEnvelope.executableArtifact),
      observedBuild:build,
      integrityVerified:true,
      semanticClaimsVerified:false,
      executablePreservation:'not-established',
      authority:'audit-record-only',
      releaseAccepted:false,
    });
  }catch(error){
    return Object.freeze({
      kind:/EXHAUSTED/u.test(error.message)?'resourceExhausted':'rejectedInvalid',
      reason:error.message,
      authority:'audit-record-only',
      releaseAccepted:false,
    });
  }
}
