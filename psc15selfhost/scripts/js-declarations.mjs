import { artifactId, artifactKey, canonicalArtifact, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { decodePublicApi } from './public-api-artifact.mjs';
import { projectSourceSignature, sourceSignatureRuntimeType, printSourceSignatureType } from './public-api-signature.mjs';
import { decodeErasureDeclarations } from './erasure-declarations.mjs';
import { decodeIrArtifact } from './ir-artifact.mjs';
import { decodeJsIrArtifact, assertJsDeclarationInventory } from './target-ir-artifact.mjs';
import { verifyUniformSpecialization, uniformSpecializationContract } from './uniform-specialization.mjs';
import { verifySpecializationCorrespondence } from './specialization-correspondence.mjs';

export const directJsDeclarationProfile = 'psc-direct-js-declarations-closed-structural/1';
export const directJsUniformDeclarationProfile = 'psc-direct-js-declarations-uniform-structural/1';
export const directJsDeclarationsContract = 'psc-direct-javascript-declarations/1';
export const directJsDeclarationBindingContract = 'psc-direct-javascript-declaration-binding/1';
const fail = code => { throw new Error('PSC_JS_DECLARATIONS_' + code); };
const subjectKinds = Object.freeze({
  publicApi: ['public-api', 'psc-public-api-ir/1'],
  erasureTable: ['erasure-table', 'psc-erasure-declarations/1'],
  runtimeIr: ['runtime-ir', 'psc-runtime-ir-json/1'],
  verifiedIr: ['verified-ir', 'psc-runtime-ir-json/1'],
  jsIr: ['js-ir', 'psc-js-ir-json/1'],
  javaScript: ['javascript-output', 'psc-direct-javascript/es2022'],
});
function limits(maxBytes, maxTotalBytes) {
  if (![maxBytes, maxTotalBytes].every(n => Number.isSafeInteger(n) && n > 0)) fail('RESOURCE_POLICY');
}
function subjectIds(subjects, profile) {
  if (![directJsDeclarationProfile, directJsUniformDeclarationProfile].includes(profile)) fail('PROFILE');
  const kinds = { ...subjectKinds, ...(profile === directJsUniformDeclarationProfile ?
    { uniformSpecializedIr: ['uniform-specialized-ir', uniformSpecializationContract] } :
    { specializedIr: ['specialized-ir', 'psc-runtime-ir-json/1'] }) };
  if (!subjects || Object.keys(subjects).sort().join(',') !== Object.keys(kinds).sort().join(',')) fail('SUBJECTS');
  for (const [key, [domain, contract]] of Object.entries(kinds)) {
    const id = subjects[key];
    if (id?.domain !== domain || id?.contract !== contract) fail('SUBJECT_KIND');
    artifactKey(id);
  }
}
const same = (a, b) => artifactKey(a) === artifactKey(b);

/** Shared bounded wire request for the portable writer in either live host
 * transport. Bindings must first come from exact source/runtime/export checks.
 */
export function createPortableJsDeclarationRequest({ profile, bindings, maxBytes }) {
  if (![directJsDeclarationProfile, directJsUniformDeclarationProfile].includes(profile)) fail('PROFILE');
  if (!Array.isArray(bindings) || bindings.length > 4096 ||
      !Number.isSafeInteger(maxBytes) || maxBytes <= 0) throw new Error('PSC2_CHECKED_DECLARATION_REQUEST_RESOURCE');
  const requests = bindings.map(binding => {
    if (!Number.isSafeInteger(binding?.sourceIndex) || binding.sourceIndex < 0 || binding.sourceIndex > 1000000 ||
        typeof binding.exportName !== 'string') throw new Error('PSC2_CHECKED_DECLARATION_REQUEST_SHAPE');
    return [String(binding.sourceIndex), binding.exportName];
  });
  const request = JSON.stringify(['psc-ts-declaration-request/1', profile, String(Math.min(maxBytes, 67108864)), requests]);
  if (Buffer.byteLength(request) > Math.min(maxBytes, 1048576)) throw new Error('PSC2_CHECKED_DECLARATION_REQUEST_RESOURCE');
  return request;
}

/** Source signatures determine declaration types. Actual erasure/specialization
 * and JsIR inventories only bind names/calling conventions and reject drift.
 * No source type is recovered from a specialized instance or printed JS.
 */
function buildDirectJsDeclarations({ subjects, profile = directJsDeclarationProfile,
  maxBytes = 128 * 1024 * 1024, maxTotalBytes = 512 * 1024 * 1024 }, capturePositions) {
  limits(maxBytes, maxTotalBytes);
  const uniform = profile === directJsUniformDeclarationProfile;
  const ids = Object.fromEntries(Object.entries(subjects ?? {}).map(([key, value]) => [key, value?.identity]));
  subjectIds(ids, profile);
  let total = 0;
  for (const item of Object.values(subjects)) {
    if (item.identity.byteLength > maxBytes || (total += item.identity.byteLength) > maxTotalBytes) fail('RESOURCE');
    verifyArtifact(item.bytes, item.identity);
  }
  const api = decodePublicApi(subjects.publicApi.bytes, { maxBytes });
  const runtime = decodeIrArtifact(subjects.runtimeIr.bytes, { maxBytes });
  const specialized = uniform ? runtime : decodeIrArtifact(subjects.specializedIr.bytes, { maxBytes });
  const target = decodeJsIrArtifact(subjects.jsIr.bytes, { maxBytes });
  const table = decodeErasureDeclarations(subjects.erasureTable.bytes,
    { publicApi: subjects.publicApi.bytes, runtimeIr: subjects.runtimeIr.bytes, maxBytes });
  if (!Buffer.from(subjects.runtimeIr.bytes).equals(Buffer.from(subjects.verifiedIr.bytes))) fail('VALIDATION_CHANGED_IR');
  if (uniform) verifyUniformSpecialization(subjects.verifiedIr, subjects.uniformSpecializedIr, { maxBytes });
  else verifySpecializationCorrespondence(subjects.verifiedIr, subjects.specializedIr, { maxBytes });
  assertJsDeclarationInventory(specialized, target);
  if (runtime[1].length || target[1].length) fail('IMPORTS_UNSUPPORTED');
  const targetIndices = new Map(target[2].map((value, index) => [value[0], index]));
  const signatures = [], bindings = [], pieces = [];
  const positions = [];
  let cursor = 0, outputBytes = 0, line = 0, column = 0;
  function write(value, sourceIndex = null, role = null) {
    const start = capturePositions ? [outputBytes, line, column] : null;
    outputBytes += Buffer.byteLength(value);
    if (outputBytes > maxBytes || total + outputBytes > maxTotalBytes) fail('RESOURCE');
    pieces.push(value);
    if (capturePositions) {
      // This writer emits LF line terminators; source type spellings are ASCII.
      // UTF-16 columns remain explicit so a future spelling extension is safe.
      for (const char of value) {
        if (char === '\n') { line++; column = 0; } else column += char.length;
      }
      if (sourceIndex !== null) positions.push([sourceIndex, role, start, [outputBytes, line, column]]);
    }
  }
  for (let sourceIndex = 0; sourceIndex < table[2].length; sourceIndex++) {
    const entry = table[2][sourceIndex];
    if (entry[1][0] !== 'runtime') continue;
    const declaration = api[2][sourceIndex], lowered = runtime[4][cursor++];
    const signature = projectSourceSignature(declaration[4]);
    if (!uniform && (signature.typeParameters.length || lowered[1].length)) fail('GENERIC_EXPORT_UNAVAILABLE');
    if (signature.typeParameters.length !== lowered[1].length) fail('GENERIC_ARITY');
    if (signature.typeParameters.length && (signature.type[0] !== 'function' || !lowered[2].length))
      fail('GENERIC_VALUE_EXPORT_UNSUPPORTED');
    const projected = sourceSignatureRuntimeType(signature.type, lowered[1]);
    const actual = lowered[2].length ? ['function', lowered[2].map(parameter => parameter[1]), lowered[3]] : lowered[3];
    if (JSON.stringify(projected) !== JSON.stringify(actual)) fail('SOURCE_RUNTIME_SIGNATURE');
    const targetIndex = targetIndices.get(lowered[0]);
    if (targetIndex === undefined || specialized[4][targetIndex][0] !== lowered[0]) fail('SOURCE_EXPORT_MISSING');
    // The selected printer emits each JsIR declaration as an ES module export.
    // A local alias avoids TypeScript binding-name collisions with Array, etc.
    const exportName = lowered[0], localName = '$pscDeclaration' + sourceIndex;
    if (!/^[A-Za-z_$][A-Za-z0-9_$]*(?![\s\S])/u.test(exportName)) fail('EXPORT_NAME');
    const parameters = signature.typeParameters.length ?
      '<' + signature.typeParameters.map(parameter => parameter.name).join(', ') + '>' : '';
    const printed = parameters + printSourceSignatureType(signature.type);
    write('declare const ' + localName + ': ' + printed + ';\n', sourceIndex, 'declaration');
    write('export { ' + localName + ' as ' + exportName + ' };\n', sourceIndex, 'export');
    signatures.push({ sourceIndex, sourceName: entry[0], signature });
    bindings.push({ sourceIndex, exportName, targetIndex });
  }
  if (bindings.length !== target[2].length) fail('EXPORT_COVERAGE');
  if (!bindings.length) write('export {};\n');
  const bytes = Buffer.from(pieces.join(''));
  const declarations = { bytes, identity: artifactId(bytes, 'declarations-output', directJsDeclarationsContract) };
  const sourceSignatures = canonicalArtifact({
    schemaVersion: 1, contract: 'psc-source-declaration-signatures/1', publicApiId: subjects.publicApi.identity,
    signatures, scope: 'runtime-declarations-selected-by-observed-erasure', inferredFromTarget: false,
    projection: 'syntactic-structural-types-only', sourceProjectionSemanticsProved: false,
  }, 'declaration-signatures', 'psc-source-declaration-signatures/1');
  const binding = canonicalArtifact({
    schemaVersion: 1, contract: directJsDeclarationBindingContract, profile, subjects: ids,
    sourceSignaturesId: sourceSignatures.identity, declarationsId: declarations.identity, bindings,
    wordSize: 64, typePrecision: 'runtime-representation-without-source-refinements',
    sourceRuntimeSignatureChecked: true, exportInventoryChecked: true,
    assumptions: ['exact-checked-public-api-projection', 'observed-erasure-dispositions',
      'strict-runtime-and-target-ir-validity', 'selected-js-printer-exports-js-ir-inventory'],
    declarationTargetAccepted: false, globalPreservationProved: false, authority: 'descriptive-product-only',
  }, 'declaration-binding', directJsDeclarationBindingContract);
  if ([sourceSignatures, binding].some(item => item.bytes.byteLength > maxBytes) ||
      total + outputBytes + sourceSignatures.bytes.byteLength + binding.bytes.byteLength > maxTotalBytes) fail('RESOURCE');
  if (!capturePositions) return { declarations, sourceSignatures, binding };
  const declarationPositions = canonicalArtifact({
    schemaVersion: 1, contract: 'psc-js-declaration-positions/1',
    declarationsId: declarations.identity, bindingId: binding.identity,
    publicApiId: subjects.publicApi.identity, coordinateContract: 'utf8-byte+zero-based-utf16',
    granularity: 'source-declaration-chunks', positions, authority: 'debug-metadata-only',
  }, 'declaration-positions', 'psc-js-declaration-positions/1');
  if (declarationPositions.bytes.byteLength > maxBytes || total + outputBytes + sourceSignatures.bytes.byteLength +
      binding.bytes.byteLength + declarationPositions.bytes.byteLength > maxTotalBytes) fail('RESOURCE');
  return { declarations, sourceSignatures, binding, declarationPositions };
}

export function createDirectJsDeclarations(options) { return buildDirectJsDeclarations(options, false); }

/** Positions come from the same source-signature writer, never reverse parsing
 * target code. The original three products retain their historical identities.
 */
export function createDirectJsDeclarationPositions(options) { return buildDirectJsDeclarations(options, true); }

export async function verifyDirectJsDeclarations(product, {
  resolveArtifact, expectedSubjects, expectedProfile = directJsDeclarationProfile,
  maxBytes = 128 * 1024 * 1024, maxTotalBytes = 512 * 1024 * 1024,
} = {}) {
  limits(maxBytes, maxTotalBytes); subjectIds(expectedSubjects, expectedProfile);
  let total = 0;
  for (const key of ['declarations', 'sourceSignatures', 'binding']) {
    const record = product[key];
    if (!record || record.identity.byteLength > maxBytes || (total += record.identity.byteLength) > maxTotalBytes) fail('RESOURCE');
    verifyArtifact(record.bytes, record.identity);
  }
  const value = decodeComparatorJson(product.binding.bytes, { maxBytes, maxDepth: 512, maxNodes: 2000000 });
  subjectIds(value.subjects, value.profile);
  if (value.profile !== expectedProfile) fail('PROFILE');
  for (const key of Object.keys(expectedSubjects)) if (!same(value.subjects[key], expectedSubjects[key])) fail('SUBJECT_BINDING');
  const subjects = {};
  for (const [key, identity] of Object.entries(expectedSubjects)) {
    if (identity.byteLength > maxBytes || (total += identity.byteLength) > maxTotalBytes) fail('RESOURCE');
    const bytes = await resolveArtifact(identity); verifyArtifact(bytes, identity);
    subjects[key] = { identity, bytes };
  }
  const rebuilt = createDirectJsDeclarations({ subjects, profile: expectedProfile, maxBytes, maxTotalBytes });
  for (const key of ['declarations', 'sourceSignatures', 'binding'])
    if (!same(rebuilt[key].identity, product[key].identity)) fail('PRODUCT_BINDING');
  return { contract: directJsDeclarationBindingContract, sourceRuntimeSignatureChecked: true,
    exportInventoryChecked: true, declarationTargetAccepted: false, globalPreservationProved: false,
    authority: 'descriptive-product-only' };
}
