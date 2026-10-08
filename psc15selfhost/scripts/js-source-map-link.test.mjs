import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactId, canonicalBytes } from './artifact-evidence.mjs';
import { createDirectJsSourceMapLinks, verifyDirectJsSourceMapLinks } from './js-source-map-link.mjs';

const input = (value, domain, contract) => {
  const bytes = typeof value === 'string' ? Buffer.from(value) : canonicalBytes(value);
  return { bytes, identity: artifactId(bytes, domain, contract) };
};
function fixture(stem = 'output') {
  const javaScript = input('export const value = "🙂";\n', 'javascript-output', 'psc-direct-javascript/es2022');
  const declarations = input('export declare const value: string;\n', 'declarations-output', 'psc-direct-javascript-declarations/1');
  const map = filename => ({ version: 3, file: filename, sources: ['input.ps'],
    sourcesContent: ['def value := "🙂"'], names: [], mappings: 'AAAA' });
  const sourceMap = input(map(stem + '.js'), 'source-map-output', 'psc-direct-javascript-source-map/1');
  const declarationMap = input(map(stem + '.d.ts'), 'declaration-map-output', 'psc-direct-js-declaration-map/1');
  return { javaScript, declarations, sourceMap, declarationMap, outputStem: stem };
}
test('linked outputs reference both exact maps and replay without modifying original bytes', () => {
  const args = fixture(), before = args.javaScript.bytes.toString('hex') + args.declarations.bytes.toString('hex');
  const linked = createDirectJsSourceMapLinks(args);
  assert.equal(linked.linkedJavaScript.bytes.toString('utf8').endsWith('\n//# sourceMappingURL=output.js.map\n'), true);
  assert.equal(linked.linkedDeclarations.bytes.toString('utf8').endsWith('\n//# sourceMappingURL=output.d.ts.map\n'), true);
  assert.equal(args.javaScript.bytes.toString('hex') + args.declarations.bytes.toString('hex'), before);
  assert.equal(verifyDirectJsSourceMapLinks(linked, { ...args, expectedStem: 'output' }).integrityVerified, true);
  assert.equal(JSON.parse(linked.recipe.bytes).semanticPreservationProved, false);
  assert.notEqual(linked.linkedJavaScript.identity.digest, args.javaScript.identity.digest);
});
test('linked replay fails closed on map name, source mutation, identity mutation and unsafe output stems', () => {
  const args = fixture(), linked = createDirectJsSourceMapLinks(args);
  assert.throws(() => createDirectJsSourceMapLinks({ ...args, outputStem: '../other' }), /FILE_STEM/);
  assert.throws(() => createDirectJsSourceMapLinks({ ...args, outputStem: 'different' }), /MAP_FILE/);
  assert.throws(() => verifyDirectJsSourceMapLinks(linked, { ...args, expectedStem: 'other' }), /MAP_FILE/);
  assert.throws(() => verifyDirectJsSourceMapLinks({ ...linked, linkedJavaScript: {
    ...linked.linkedJavaScript, bytes: Buffer.from('tampered') } }, { ...args, expectedStem: 'output' }));
  assert.throws(() => verifyDirectJsSourceMapLinks(linked, { ...args,
    javaScript: input('export const value = 42;\n','javascript-output','psc-direct-javascript/es2022'), expectedStem: 'output' }), /REPLAY/);
  assert.throws(() => createDirectJsSourceMapLinks({ ...args,
    declarations: input('//# sourceMappingURL=other.map\n','declarations-output','psc-direct-javascript-declarations/1') }), /EXISTING_DIRECTIVE/);
});
