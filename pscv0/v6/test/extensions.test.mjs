import test from 'node:test';
import assert from 'node:assert/strict';
import { validateExtensionManifest, selectExtensionSet } from '@proofscript/pscv-extensions';
import { createCompilerCore } from '@proofscript/pscv-core';

const library = Object.freeze({
  schemaVersion:1, id:'@example/math', version:'1.0.0',
  semanticClass:'E0', executionClass:'U0', apiVersion:'pscv-extension/1',
  entry:null, profiles:['pscv-v1','ps-standard-0.9-r3'], capabilities:[],
});
const tactic = Object.freeze({
  schemaVersion:1, id:'@example/tactic', version:'1.0.0',
  semanticClass:'E2', executionClass:'U1', apiVersion:'pscv-extension/1',
  entry:'./component.wasm', profiles:['pscv-v1'], capabilities:[],
});
const syntax = Object.freeze({
  schemaVersion:1, id:'@example/new-notation', version:'1.0.0',
  semanticClass:'E1', executionClass:'U1', apiVersion:'pscv-extension/1',
  entry:'./syntax.wasm', profiles:['pscv-v1'], capabilities:[],
});

test('library data and proof producer descriptors do not load executable code', () => {
  const ext = selectExtensionSet({available:[library,tactic], enabled:['@example/tactic','@example/math'], profile:'pscv-v1'});
  assert.equal(ext.descriptors.length, 2);
  assert.equal(ext.executableExtensionsEnabled, false);
  assert.equal(ext.descriptors[0].id,'@example/math');
  assert.equal(ext.descriptors[1].semanticClass,'E2');
  assert.equal(ext.fingerprint,selectExtensionSet({available:[tactic,library], enabled:['@example/math','@example/tactic'], profile:'pscv-v1'}).fingerprint);
  assert.equal(createCompilerCore({profile:'pscv-v1',availableExtensions:[library],enabledExtensions:['@example/math']}).describe().pscvCertificationImplemented,false);
});

test('unrecognized, semantic and in-process extensions are not accepted', () => {
  assert.throws(() => validateExtensionManifest({...tactic,semanticClass:'E5'}), /PSCV_EXTENSION_AUTHORITY_DENIED/u);
  assert.throws(() => validateExtensionManifest({...tactic,semanticClass:'E6'}), /PSCV_EXTENSION_AUTHORITY_DENIED/u);
  assert.throws(() => validateExtensionManifest({...tactic,executionClass:'U3'}), /PSCV_EXTENSION_AUTHORITY_DENIED/u);
  assert.throws(() => validateExtensionManifest({...tactic,entry:'../../escape.wasm'}), /PSCV_EXTENSION_ENTRY_INVALID/u);
  assert.throws(() => validateExtensionManifest({...library,entry:'./postinstall.js'}), /PSCV_EXTENSION_ENTRY_FORBIDDEN/u);
  assert.throws(() => validateExtensionManifest({...library,semanticClass:'E2'}), /PSCV_EXTENSION_EXECUTION_CLASS_REQUIRED/u);
  assert.throws(() => validateExtensionManifest({...tactic,unexpected:true}), /PSCV_EXTENSION_UNKNOWN_FIELD/u);
  const hostile = {...tactic};
  Object.defineProperty(hostile, 'entry', { get() { throw new Error('getter executed'); }, enumerable: true });
  assert.throws(() => validateExtensionManifest(hostile), /PSCV_EXTENSION_ACCESSOR_OR_SYMBOL_DENIED/u);
});

test('closed verified profile rejects unapproved source grammar changes', () => {
  assert.throws(() => selectExtensionSet({available:[syntax],enabled:[syntax.id],profile:'pscv-v1'}), /PSCV_CLOSED_PROFILE_SYNTAX_EXTENSION/u);
  assert.throws(() => selectExtensionSet({available:[{...syntax,profiles:['ps-standard-0.9-r3']}],enabled:[syntax.id],profile:'ps-standard-0.9-r3'}), /PSCV_CLOSED_PROFILE_SYNTAX_EXTENSION/u);
  assert.throws(() => selectExtensionSet({available:[library],enabled:['@other/package'],profile:'pscv-v1'}), /PSCV_EXTENSION_NOT_INSTALLED/u);
  assert.throws(() => selectExtensionSet({available:[library,library],enabled:[library.id],profile:'pscv-v1'}), /PSCV_EXTENSION_DUPLICATE_ID/u);
  assert.throws(() => selectExtensionSet({available:[library],enabled:[library.id,library.id],profile:'pscv-v1'}), /PSCV_EXTENSION_ENABLED/u);
  assert.throws(() => selectExtensionSet({available:[tactic],enabled:[tactic.id],profile:'ps-standard-0.9-r3'}), /PSCV_EXTENSION_PROFILE_MISMATCH/u);
});

test('only explicitly extensible source profile can activate E1 syntax descriptors', () => {
  const x = {...syntax, profiles:['ps-lean-extensible-0.9-r3']};
  const set = createCompilerCore({profile:'ps-lean-extensible-0.9-r3', availableExtensions:[x], enabledExtensions:[x.id]}).extensionPlan();
  assert.equal(set.descriptors[0].semanticClass, 'E1');
  assert.equal(set.executableExtensionsEnabled,false);
});
