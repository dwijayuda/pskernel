import { artifactId, artifactKey, canonicalArtifact, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';

export const directJsSourceMapLinkContract = 'psc-direct-js-source-map-link/1';
export const directJsLinkedJavaScriptContract = 'psc-direct-js-linked-javascript/1';
export const directJsLinkedDeclarationsContract = 'psc-direct-js-linked-declarations/1';
const fail = code => { throw new Error('PSC_JS_MAP_LINK_' + code); };
const same = (a, b) => artifactKey(a) === artifactKey(b);
const inputKinds = Object.freeze({
  javaScript: ['javascript-output', 'psc-direct-javascript/es2022'],
  declarations: ['declarations-output', 'psc-direct-javascript-declarations/1'],
  sourceMap: ['source-map-output', 'psc-direct-javascript-source-map/1'],
  declarationMap: ['declaration-map-output', 'psc-direct-js-declaration-map/1'],
});
function check(record, domain, contract, maxBytes) {
  if (!(record?.bytes instanceof Uint8Array) || record.bytes.byteLength > maxBytes ||
      record.identity?.domain !== domain || record.identity?.contract !== contract) fail('INPUT');
  verifyArtifact(record.bytes, record.identity);
}
function policy(stem, maxBytes, maxTotalBytes) {
  if (typeof stem !== 'string' || !/^[a-zA-Z0-9_-][a-zA-Z0-9._-]{0,253}$/u.test(stem) ||
      stem.includes('..')) fail('FILE_STEM');
  if (![maxBytes, maxTotalBytes].every(n => Number.isSafeInteger(n) && n > 0) || maxTotalBytes < maxBytes)
    fail('RESOURCE_POLICY');
}
function append(record, url, maxBytes) {
  const original = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(record.bytes);
  if (/(?:^|[\r\n])[ \t]*\/\/[#@][ \t]*sourceMappingURL[ \t]*=/u.test(original)) fail('EXISTING_DIRECTIVE');
  const annotation = Buffer.from('\n//# sourceMappingURL=' + url + '\n');
  if (record.bytes.byteLength + annotation.byteLength > maxBytes) fail('RESOURCE');
  return Buffer.concat([record.bytes, annotation]);
}
/** Selected packaging changes only trailing unmapped metadata comments. The
 * unlinked printer/declaration products and their original map anchors are
 * immutable checked-build graph inputs, not rewritten target products.
 */
export function createDirectJsSourceMapLinks({ javaScript, declarations, sourceMap, declarationMap,
  outputStem, maxBytes = 128 * 1024 * 1024, maxTotalBytes = 512 * 1024 * 1024 }) {
  policy(outputStem, maxBytes, maxTotalBytes);
  const values = { javaScript, declarations, sourceMap, declarationMap };
  for (const [name, [domain, contract]] of Object.entries(inputKinds))
    check(values[name], domain, contract, maxBytes);
  let total = Object.values(values).reduce((sum, record) => sum + record.bytes.byteLength, 0);
  if (total > maxTotalBytes) fail('RESOURCE');
  const jsName = outputStem + '.js', declarationName = outputStem + '.d.ts';
  for (const [record, filename] of [[sourceMap, jsName], [declarationMap, declarationName]]) {
    const map = decodeComparatorJson(record.bytes, { maxBytes, maxDepth: 32, maxNodes: 2000000 });
    if (map.version !== 3 || map.file !== filename || typeof map.mappings !== 'string' ||
        !Array.isArray(map.sources) || !Array.isArray(map.sourcesContent)) fail('MAP_FILE');
  }
  const linkedJsBytes = append(javaScript, jsName + '.map', maxBytes);
  const linkedDeclarationBytes = append(declarations, declarationName + '.map', maxBytes);
  total += linkedJsBytes.byteLength + linkedDeclarationBytes.byteLength;
  if (total > maxTotalBytes) fail('RESOURCE');
  const linkedJavaScript = { bytes: linkedJsBytes,
    identity: artifactId(linkedJsBytes, 'linked-javascript-output', directJsLinkedJavaScriptContract) };
  const linkedDeclarations = { bytes: linkedDeclarationBytes,
    identity: artifactId(linkedDeclarationBytes, 'linked-declarations-output', directJsLinkedDeclarationsContract) };
  const recipe = canonicalArtifact({ schemaVersion: 1, contract: directJsSourceMapLinkContract,
    outputStem, javaScriptId: javaScript.identity, declarationsId: declarations.identity,
    sourceMapId: sourceMap.identity, declarationMapId: declarationMap.identity,
    linkedJavaScriptId: linkedJavaScript.identity, linkedDeclarationsId: linkedDeclarations.identity,
    placement: 'append-unmapped-sourceMappingURL-after-original-output',
    semanticPreservationProved: false, authority: 'debug-packaging-only' },
  'source-map-link-recipe', directJsSourceMapLinkContract);
  if (recipe.bytes.byteLength > maxBytes || total + recipe.bytes.byteLength > maxTotalBytes) fail('RESOURCE');
  return { linkedJavaScript, linkedDeclarations, recipe };
}
/** Independent deterministic reconstruction. It does not imply that source
 * maps establish expression origins or runtime semantic preservation.
 */
export function verifyDirectJsSourceMapLinks({ linkedJavaScript, linkedDeclarations, recipe }, {
  javaScript, declarations, sourceMap, declarationMap, expectedStem,
  maxBytes = 128 * 1024 * 1024, maxTotalBytes = 512 * 1024 * 1024 } = {}) {
  policy(expectedStem, maxBytes, maxTotalBytes);
  check(linkedJavaScript, 'linked-javascript-output', directJsLinkedJavaScriptContract, maxBytes);
  check(linkedDeclarations, 'linked-declarations-output', directJsLinkedDeclarationsContract, maxBytes);
  check(recipe, 'source-map-link-recipe', directJsSourceMapLinkContract, maxBytes);
  const actual = { linkedJavaScript, linkedDeclarations, recipe };
  const rebuilt = createDirectJsSourceMapLinks({ javaScript, declarations, sourceMap, declarationMap,
    outputStem: expectedStem, maxBytes, maxTotalBytes });
  for (const key of Object.keys(actual))
    if (!same(rebuilt[key].identity, actual[key].identity) ||
        !Buffer.from(rebuilt[key].bytes).equals(actual[key].bytes)) fail('REPLAY');
  return Object.freeze({ integrityVerified: true, semanticPreservationProved: false });
}
