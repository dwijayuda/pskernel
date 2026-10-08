import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const source = await readFile(new URL('../packages/syntax/src/Ps/Syntax/ParseProofScript.lean', import.meta.url), 'utf8');
const worker = source.slice(source.indexOf('def psParseProofScriptBinderTypeWithFuel'), source.indexOf('def psParseProofScriptBinderType\n'));
const markers = [
  'psParseProofScriptBinderTypeWithFuel remaining;',
  'if psTokenCursorAtBinderStart cursor then',
  'psParseProofScriptNestedBinderType smaller cursor',
  'psParseProofScriptApplicationWithFuel smaller (Nat.succ remaining) cursor',
  'psParseProofScriptArrowTail smaller domain',
  'Except.error PsParseError.fuelExhausted',
];
const validate = text => markers.forEach(marker => assert(text.includes(marker), `missing binder replay guard: ${marker}`));
validate(worker);
for (const marker of markers) assert.throws(() => validate(worker.replaceAll(marker, 'removed')));
const host = await readFile(new URL('../host/src/Ps/Host/ProjectCompiler.lean', import.meta.url), 'utf8');
for (const marker of ['.proofscript-bootstrap.json', '.proofscript-selfhost.json', '.proofscript-project.json',
  'hasPackages && (hasStdlib || hasBootstrap || hasSelfhost || hasProject)']) assert(host.includes(marker));
console.log('PSC2_PROOFSCRIPT_BINDER_REPLAY_SOURCE: PASS (decreasing type parser, nested binders and generated workspace boundary)');
