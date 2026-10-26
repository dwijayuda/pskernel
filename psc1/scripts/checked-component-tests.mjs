// Closed WIT grammar: operator priority, hyphenated identifiers and refusals.
import assert from 'node:assert/strict';
import {observedBoolWit,expectedBoolWit,componentSchema} from '../host-tools/checked-component.mjs';
const schema=[{name:'truth',parameters:[]},{name:'invert-value',parameters:['input-value']}];
assert.deepEqual(observedBoolWit(expectedBoolWit(schema)),schema);
assert.deepEqual(observedBoolWit('package root:component;\nworld root {\n// observed by wasm-tools\n export truth: func() -> bool;\n export invert-value: func(input-value: bool) -> bool;\n}\n'),schema);
for(const text of [
 'world root { import truth: func() -> bool; }',
 'world root { export truth: func() -> string; }',
 'world root { export truth: func(value: u32) -> bool; }',
 'world root { export truth: func() - > bool; }',
 'world root { export truth: func() -> bool; } world other {}',
 'world root { export truth: func() -> bool;',
 'world root { export truth: func() -> bool; type other = bool; }',
])assert.throws(()=>observedBoolWit(text),/PSC1_COMPONENT_WIT_/);
const candidate={publicNames:['truth'],specializedIr:['psc1-ir/1',[],[],[],[['truth',[],[],['primitive','bool'],[]]]]};
assert.deepEqual(componentSchema(candidate),[{name:'truth',parameters:[]}]);
assert.throws(()=>componentSchema({...candidate,outputAbi:'io-dispatcher'}),/ABI_UNSUPPORTED/);
for(const primitive of ['nat','int','string','unit']) {
 const value=structuredClone(candidate);value.specializedIr[4][0][3]=['primitive',primitive];
 assert.throws(()=>componentSchema(value),/ABI_UNSUPPORTED/);
}
const indirect=structuredClone(candidate);indirect.specializedIr[4][0][2]=Array.from({length:17},(_,i)=>['a'+i,['primitive','bool']]);
assert.throws(()=>componentSchema(indirect),/ABI_UNSUPPORTED/);
console.log('PSC1_COMPONENT_HOST_GRAMMAR: 3 positive and13 refusal checks passed');
